// Pushes clinic notices to patient phones through Firebase Cloud Messaging.
//
// It polls PocketBase instead of being called by a hook, because PocketBase's
// JS runtime cannot sign the RS256 JWT a Google service account needs. Polling
// also means this process opens no port at all: nothing on the machine can
// trigger a push except the clinic publishing a notice.
//
// Notice latency is therefore up to POLL_SECONDS. The app itself gets instant
// updates over PocketBase's realtime stream, so this only covers patients whose
// app is closed.

// firebase-admin 14 is modular: the root export no longer carries `credential`
// or `messaging`, so the subpaths are imported directly. Passing a file *path*
// to cert() is deprecated, so the JSON is read here.
const fs = require("node:fs");
const { initializeApp, cert } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

const PB_URL = process.env.BSP_PB_URL || "http://127.0.0.1:8090";
const PB_EMAIL = process.env.BSP_PB_EMAIL;
const PB_PASS = process.env.BSP_PB_PASS;
const GOOGLE_CREDENTIALS = process.env.BSP_GOOGLE_CREDENTIALS;
const POLL_SECONDS = Number(process.env.BSP_POLL_SECONDS || 20);

if (!PB_EMAIL || !PB_PASS || !GOOGLE_CREDENTIALS) {
  console.error(
    "BSP_PB_EMAIL, BSP_PB_PASS and BSP_GOOGLE_CREDENTIALS must all be set",
  );
  process.exit(1);
}

initializeApp({
  credential: cert(JSON.parse(fs.readFileSync(GOOGLE_CREDENTIALS, "utf8"))),
});
const messaging = getMessaging();

let token = null;

async function pb(path, options = {}, retry = true) {
  if (!token && retry !== false) {
    token = await signIn();
  }
  const response = await fetch(PB_URL + path, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: token } : {}),
      ...(options.headers || {}),
    },
  });

  // PocketBase superuser tokens expire; re-authenticate once and replay.
  if (response.status === 401 && retry) {
    token = await signIn();
    return pb(path, options, false);
  }
  if (!response.ok) {
    throw new Error(`${path} -> http ${response.status}: ${await response.text()}`);
  }
  return response.status === 204 ? {} : response.json();
}

async function signIn() {
  const body = JSON.stringify({ identity: PB_EMAIL, password: PB_PASS });
  const response = await fetch(`${PB_URL}/api/collections/_superusers/auth-with-password`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body,
  });
  if (!response.ok) {
    throw new Error(`superuser sign-in failed: http ${response.status}`);
  }
  return (await response.json()).token;
}

async function allRecords(collection, filter) {
  const out = [];
  for (let page = 1; ; page++) {
    const query =
      `/api/collections/${collection}/records?perPage=500&page=${page}` +
      (filter ? `&filter=${encodeURIComponent(filter)}` : "");
    const result = await pb(query);
    out.push(...result.items);
    if (page >= result.totalPages) break;
  }
  return out;
}

/**
 * A notice is handed to every registered device once. Marking it pushed at day
 * granularity means an edited notice is not re-broadcast, which is what a
 * waiting room wants: a corrected spelling should not buzz 200 phones.
 */
async function pendingNotices() {
  return allRecords(
    "notices",
    "(published = true) && pushedAt = ''",
  );
}

async function markPushed(notice) {
  const today = new Date().toISOString().slice(0, 10);
  await pb(`/api/collections/notices/records/${notice.id}`, {
    method: "PATCH",
    body: JSON.stringify({ pushedAt: today }),
  });
}

async function dropDevice(id) {
  try {
    await pb(`/api/collections/devices/records/${id}`, { method: "DELETE" });
  } catch (error) {
    console.error(`could not drop device ${id}: ${error.message}`);
  }
}

async function sendToTokens(notice, devices) {
  const outcome = { delivered: 0, dead: [], unresolved: 0 };

  for (let i = 0; i < devices.length; i += 500) {
    const chunk = devices.slice(i, i + 500);
    const result = await messaging.sendEachForMulticast({
      tokens: chunk.map((entry) => entry.token),
      notification: {
        title: notice.title,
        body: notice.body,
      },
      data: { kind: "notice", noticeId: notice.id },
      android: { priority: "high" },
    });

    result.responses.forEach((response, index) => {
      if (response.success) {
        outcome.delivered++;
        return;
      }
      const code = (response.error && response.error.code) || "unknown";
      if (
        code.endsWith("registration-token-not-registered") ||
        code.endsWith("invalid-registration-token")
      ) {
        // The app is gone from that phone; the row is worthless.
        outcome.dead.push(chunk[index].id);
      } else {
        // A credential or transport problem on our side: the patient still
        // deserves the notice, so it must be retried.
        outcome.unresolved++;
        console.warn(`push failed for one device: ${code}`);
      }
    });
  }

  return outcome;
}

let running = false;

async function tick() {
  if (running) return;
  running = true;
  try {
    const notices = await pendingNotices();
    if (!notices.length) return;

    const devices = await allRecords("devices", "");
    if (!devices.length) {
      console.info("notices pending but no devices registered yet");
      return;
    }

    for (const notice of notices) {
      const outcome = await sendToTokens(notice, devices);
      for (const id of outcome.dead) await dropDevice(id);

      // Marking a notice announced is what stops it ever being delivered, so
      // it only happens once every device was either reached or proven dead.
      if (outcome.unresolved) {
        console.warn(
          `notice ${notice.id} left queued: ${outcome.unresolved} device(s) ` +
            `unreachable for a retryable reason, ${outcome.delivered} delivered`,
        );
        continue;
      }

      await markPushed(notice);
      console.info(
        `announced notice ${notice.id}: ${outcome.delivered} delivered, ` +
          `${outcome.dead.length} token(s) dropped`,
      );
    }
  } catch (error) {
    // A failed pass leaves pushedAt empty, so the next tick retries it.
    console.error(`pass failed: ${error.message}`);
    token = null;
  } finally {
    running = false;
  }
}

signIn()
  .then((value) => {
    token = value;
    console.info(`push sender ready, polling ${PB_URL} every ${POLL_SECONDS}s`);
  })
  .catch((error) => {
    console.error(`initial sign-in failed: ${error.message}`);
  })
  .finally(() => {
    setInterval(tick, POLL_SECONDS * 1000);
  });
