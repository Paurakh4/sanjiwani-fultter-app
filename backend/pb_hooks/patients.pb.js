/// <reference path="../pb_data/types.d.ts" />

// Patient identity: a clinic-style BSP register number issued by the server,
// and a rule that an account always has something to sign in with.
//
// Handlers are self-contained — see the note at the top of appointments.pb.js.

onRecordCreate((e) => {
  const app = e.app;
  const record = e.record;

  if (!record.getString("username") && !record.getString("email")) {
    throw new ValidationError(
      "identity_required",
      "A phone number or an email address is required.",
    );
  }

  /**
   * Reject a taken phone number or email before a number is issued. PocketBase
   * enforces both with unique indexes, but that lands after this hook, so a
   * colliding signup would already have taken a register number with it — a
   * number issued to nobody, and a gap in the register that looks exactly like
   * a deleted patient. Checking here also turns the bare "Failed to create
   * record." into something the app can put on screen.
   */
  function rejectTaken(field, value) {
    if (!value) return;
    let existing = null;
    try {
      existing = app.findFirstRecordByData("patients", field, value);
    } catch (err) {
      existing = null;
    }
    if (!existing) return;
    // The code|English prefix is the one error shape that survives PocketBase's
    // rewriting, so the app can show "that number is already registered".
    throw new ApiError(
      400,
      field === "username"
        ? "signup_phone_taken|This phone number already has an account."
        : "signup_email_taken|This email address already has an account.",
    );
  }

  rejectTaken("username", record.getString("username"));
  rejectTaken("email", record.getString("email"));

  /**
   * Mirror the two format rules PocketBase checks at save time, which is after
   * this hook: a signup rejected there would keep its register number. These
   * stay in sync with the migration (patients.email is email, name is 2-120);
   * tool/api_check.py asserts the numbers survive both, so drift shows up there
   * instead of as a gap in the register.
   */
  const email = record.getString("email");
  if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new ValidationError("email", "is not a valid address");
  }
  const name = record.getString("name");
  if (name.length < 2 || name.length > 120) {
    throw new ValidationError("name", "must be 2 to 120 characters");
  }

  // The counter advances with the patient row: `app` inside an execute hook is
  // bound to the same save, so a signup rejected below this line does not keep
  // its number. `app.runInTransaction` would open a second transaction that
  // commits regardless — which is how the first production register got a gap.
  const counters = app.findCollectionByNameOrId("counters");
  let counter;
  try {
    counter = app.findFirstRecordByData(counters, "key", "patientId");
  } catch (err) {
    counter = null;
  }
  const next = counter ? counter.getInt("value") + 1 : 1;
  if (counter) {
    counter.set("value", next);
    app.save(counter);
  } else {
    app.save(new Record(counters, { key: "patientId", value: next }));
  }

  // No String.prototype.padStart in this JS runtime.
  let padded = String(next);
  while (padded.length < 4) {
    padded = "0" + padded;
  }
  record.set("patientId", "BSP-" + padded);

  e.next();
}, "patients");

onRecordUpdate((e) => {
  const record = e.record;
  let stored;
  try {
    stored = e.app.findRecordById("patients", record.id);
  } catch (err) {
    stored = null;
  }
  if (stored) {
    // Reception may correct a name or a phone; the register number a patient
    // has already quoted at the desk stays put.
    record.set("patientId", stored.getString("patientId"));
  }

  if (!record.getString("username") && !record.getString("email")) {
    throw new ValidationError(
      "identity_required",
      "Keep at least a phone number or an email address on the account.",
    );
  }

  e.next();
}, "patients");
