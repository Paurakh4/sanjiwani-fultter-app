# Backend

PocketBase **0.40.6** (pinned; SHA-256 of the linux_amd64 zip is in
`deploy/install.sh`) plus a small Node sender for push notifications.

```
pb_migrations/   schema and seed, applied automatically on boot
pb_hooks/        booking validation, patient register numbers, completion cron
push-sender/     polls for published notices and delivers them via FCM HTTP v1
../deploy/       systemd units, nginx site, install script
```

## Working on it locally

```bash
./tool/dev_backend.sh reset     # wipe and re-apply every migration
./tool/dev_backend.sh start
python3 tool/api_check.py       # 30 checks against rules and hooks
```

The dev superuser password is generated into `backend/.local/` (0600, gitignored)
and only ever applies to this machine. The app points at
`http://10.0.2.2:8090` in debug builds, which is the emulator's route to this Mac.

`backend/pb_migrations` is the source of truth. Never edit the schema in the
dashboard on the VPS — make a migration, apply it locally, re-run
`python3 tool/api_check.py`, then redeploy.

## Deploying a schema change

PocketBase records applied migrations **by filename**, so editing a migration
that has already run does nothing on the server. After changing anything in
`pb_migrations/` or `pb_hooks/`:

```bash
rsync -az --delete backend/pb_migrations/ hermes-vps:/home/px/bsp-staging/backend/pb_migrations/
rsync -az --delete backend/pb_hooks/      hermes-vps:/home/px/bsp-staging/backend/pb_hooks/
# then, as root on the VPS:
sudo bash /home/px/bsp-staging/deploy/install.sh
```

Confirm the copies match before trusting it — a stale staging dir once left the
live server missing a whole collection while every local check passed:

```bash
md5sum backend/pb_migrations/*.js
ssh hermes-vps 'md5sum /opt/bsp/pocketbase/pb_migrations/*.js'
```

Before go-live, when there is no patient data to lose, the clean way to resolve
an edited migration is to rebuild from scratch:

```bash
sudo systemctl stop bsp-pocketbase
sudo rm -rf /opt/bsp/pocketbase/pb_data
sudo bash /home/px/bsp-staging/deploy/install.sh   # re-creates the admin account
```

After go-live that is no longer an option: only ever add a new forward migration.

## What the checks cover

Anonymous catalog reads, closed patient/counter lists, phone-or-email signup and
login, sequential `BSP-####` register numbers that staff cannot rewrite, server-
priced bookings, same-patient duplicate rejection, wrong-Saturday and past-date
rejection, capacity blocking the last slot, cancel-then-rebook, per-patient
visibility of bookings, and notice drafts staying unpublished.

## PocketBase 0.40.6 gotchas found the hard way

Each of these produced a confusing failure before it was understood:

1. **`type: "datetime"` is silently dropped.** A field array containing one is
   discarded *whole*, leaving a collection with only `id`, and the migration
   still reports success. Use `type: "date"`.
2. **Auth configuration is top-level, not under `options`.** Writing
   `options: { passwordAuth: ... }` is accepted and ignored, so `username` never
   becomes a login handle and phone sign-in fails with a bare 400.
3. **Hook handlers cannot call file-scope helpers.** PocketBase re-evaluates a
   handler in a pooled JS runtime, so `function helper() {}` at the top of a
   `.pb.js` file raises "helper is not defined" the moment a handler runs. Every
   handler in `pb_hooks/` is self-contained for that reason. `--hooksPool 1` does
   not change this.
4. **A `date` field is stored as a UTC timestamp**, so `date = '2026-12-19'`
   matches nothing. Day matching needs the dynamic operator: `date ~ '2026-12-19'`.
5. **Error payloads are rewritten.** Structured data passed to `ApiError` comes
   back as generic `validation_invalid_value` field errors, so the machine-readable
   reason travels as a `code|English text` prefix in the message. PocketBase also
   capitalises the first letter of any message — compare codes case-insensitively.
6. **Record ids are fixed-length**, which is why the app's short identifiers
   (`gyn`, `rajan`) live in a unique `code` field rather than as `id`.
7. **Save-level hook events do not know who asked.** Inside
   `onRecordCreate`/`onRecordUpdate` the event exposes only `app`, `record`,
   `type`, `next` and `tags` — `e.auth` and `e.originalRecord` are `undefined`,
   and a closure built by a factory at registration time loses its captured
   variables for the same reason as trap 3. Anything that has to distinguish a
   patient from the clinic belongs in `onRecordCreateRequest`/
   `onRecordUpdateRequest`, where `e.auth` and `e.hasSuperuserAuth()` exist.
   The cron never reaches a `*Request` handler, because it saves through `$app`.

## Deliberate choices

- **A booking is `booked` when it is created, and only the clinic can complete
  one.** Without that, a patient could POST `status: "completed"` and have a
  visit that never happened counted as attended, or cancel-proof a slot by
  marking it done. `tool/api_check.py` asserts both halves.
- **A register number is issued only when the signup lands.** The counter lives
  in `patients.pb.js` after checks for a taken phone number, a taken email and
  the two format rules PocketBase evaluates at save time (email shape, name
  2-120). Anything that reaches the save after the hook runs and fails would
  otherwise take its number with it — production's first register started at
  BSP-0002 because of exactly that. Gaps from a purged checker run are
  impossible too: the checker reads the counter and asserts the next signup is
  still in line.

- **Notices are not seeded.** The three in the Flutter app reference a BS 2082
  Jestha date that has passed, so publishing them would state something false to
  patients. The clinic publishes its own.
- **No capacity numbers are invented.** `doctors.capacity` is empty, meaning
  unlimited, until the clinic states a real number per specialist.
- **The sender polls instead of being called by a hook**, because PocketBase's JS
  runtime can only sign HS256 and a Google service account needs RS256. Polling
  also means the sender opens no port and needs no shared secret.
- **Backups use PocketBase's own scheduler** (`0 18 * * *` UTC = 23:45 Nepal,
  7 kept), configured by `deploy/install.sh`, rather than a script and a timer.
- **`pushedAt` is day-granular on purpose**: editing a notice to fix a typo
  should not buzz every phone in the district again.
