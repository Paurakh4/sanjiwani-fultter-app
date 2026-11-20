/// <reference path="../pb_data/types.d.ts" />

// Clinic catalog and booking schema. Applied automatically on boot; the local
// dev instance and the VPS both run this same file, so the schema is never
// edited by hand in the dashboard.
//
// Short ids used by the app ('gyn', 'ortho', 'rajan') live in a `code` field
// because PocketBase record ids are fixed-length and cannot hold them.

migrate(
  (app) => {
    // ---------------------------------------------------------------- patients
    app.save(
      new Collection({
        id: "pb_patients",
        name: "patients",
        type: "auth",
        system: false,
        fields: [
          // The phone number doubles as the login handle, so a patient can
          // sign in with either the phone number or an email if they have one.
          { type: "text", name: "username", presentable: true, min: 3, max: 47, pattern: "^[-_.@a-zA-Z0-9]+$" },
          // Optional: most patients in Bidur register by phone, and the unique
          // email index PocketBase adds skips empty values.
          { type: "email", name: "email", required: false, authRule: null },
          { type: "text", name: "name", required: true, min: 2, max: 120 },
          { type: "text", name: "patientId", presentable: true, required: true, pattern: "^BSP-[0-9]{4,6}$" },
          { type: "select", name: "gender", maxSelect: 1, values: ["female", "male", "other"] },
          { type: "text", name: "bloodGroup", max: 6 },
          { type: "text", name: "address", max: 300 },
          { type: "text", name: "age", max: 6 },
          // Which notice ids this patient has opened. Stored here rather than
          // as one row per patient per notice, so publishing a notice does not
          // have to write a feed item for every patient in the register.
          { type: "json", name: "readNoticeKeys" },
        ],
        indexes: [
          "CREATE UNIQUE INDEX `idx_patients_patientId` ON `patients` (`patientId`)",
          "CREATE UNIQUE INDEX `idx_patients_username` ON `patients` (`username`)",
        ],
        // Self-service signup; a patient may only ever read their own record,
        // and there is no way to enumerate the patient list.
        listRule: null,
        viewRule: "@request.auth.id != '' && id = @request.auth.id",
        createRule: "",
        updateRule: "@request.auth.id != '' && id = @request.auth.id",
        deleteRule: null,
        // These are top-level collection properties in 0.40.6; a nested
        // `options` object is accepted by the constructor and then ignored.
        passwordAuth: {
          enabled: true,
          // Both handles resolve to the same account. Only fields with a
          // single-column unique index qualify as an identity.
          identityFields: ["email", "username"],
        },
        otp: { enabled: false },
        mfa: { enabled: false },
        // A patient logging in from a new phone gets no email: most accounts
        // have no email at all, and the clinic cannot act on the alert.
        authAlert: { enabled: false },
      }),
    );

    // ------------------------------------------------------------- departments
    app.save(
      new Collection({
        id: "pb_departments",
        name: "departments",
        type: "base",
        system: false,
        fields: [
          { type: "text", name: "code", presentable: true, required: true, max: 40 },
          { type: "text", name: "nameNp", required: true, max: 120 },
          { type: "text", name: "nameEn", required: true, max: 120 },
          { type: "text", name: "descNp", max: 500 },
          { type: "text", name: "descEn", max: 500 },
          { type: "text", name: "icon", max: 60 },
          { type: "number", name: "sortOrder", max: 9999 },
          // Position in the specialist list the app shows; only the seven
          // bookable departments carry one.
          { type: "number", name: "specialistOrder", min: 0, max: 20 },
        ],
        indexes: ["CREATE UNIQUE INDEX `idx_departments_code` ON `departments` (`code`)"],
        listRule: "",
        viewRule: "",
        createRule: null,
        updateRule: null,
        deleteRule: null,
        options: {},
      }),
    );

    // ----------------------------------------------------------------- doctors
    app.save(
      new Collection({
        id: "pb_doctors",
        name: "doctors",
        type: "base",
        system: false,
        fields: [
          { type: "text", name: "code", presentable: true, required: true, max: 40 },
          { type: "text", name: "nameNp", required: true, max: 120 },
          { type: "text", name: "nameEn", required: true, max: 120 },
          { type: "text", name: "specialtyNp", max: 120 },
          { type: "text", name: "specialtyEn", max: 120 },
          { type: "text", name: "qualification", max: 200 },
          { type: "text", name: "departmentCode", required: true, max: 40 },
          // Free-text availability and biography: the app shows both, and the
          // clinic edits them directly rather than having them derived.
          { type: "text", name: "availabilityNp", max: 200 },
          { type: "text", name: "availabilityEn", max: 200 },
          { type: "text", name: "bioNp", max: 2000 },
          { type: "text", name: "bioEn", max: 2000 },
          { type: "number", name: "fee", min: 0, max: 100000 },
          { type: "text", name: "startTime", pattern: "^([01][0-9]|2[0-3]):[0-5][0-9]$" },
          { type: "text", name: "endTime", pattern: "^([01][0-9]|2[0-3]):[0-5][0-9]$" },
          // Weekday numbers (1=Mon..7=Sun) and shift names the app already uses.
          { type: "json", name: "weekdays" },
          { type: "json", name: "shifts" },
          { type: "select", name: "saturdayGroup", maxSelect: 1, values: ["first", "second", "third", "last"] },
          { type: "bool", name: "visiting" },
          // Empty means "no capacity limit" — the clinic sets real numbers.
          { type: "number", name: "capacity", min: 1, max: 500 },
          { type: "text", name: "avatar", max: 120 },
        ],
        indexes: [
          "CREATE UNIQUE INDEX `idx_doctors_code` ON `doctors` (`code`)",
          "CREATE INDEX `idx_doctors_department` ON `doctors` (`departmentCode`)",
        ],
        listRule: "",
        viewRule: "",
        createRule: null,
        updateRule: null,
        deleteRule: null,
        options: {},
      }),
    );

    // ----------------------------------------------------------------- notices
    app.save(
      new Collection({
        id: "pb_notices",
        name: "notices",
        type: "base",
        system: false,
        fields: [
          { type: "text", name: "title", presentable: true, required: true, max: 200 },
          { type: "text", name: "body", required: true, max: 4000 },
          { type: "text", name: "titleEn", max: 200 },
          { type: "text", name: "bodyEn", max: 4000 },
          { type: "text", name: "tag", max: 60 },
          { type: "text", name: "dateLabel", max: 60 },
          { type: "text", name: "doctorCode", max: 40 },
          { type: "autodate", name: "created", onCreate: true, onUpdate: false },
          { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
          { type: "bool", name: "published" },
          { type: "bool", name: "pinned" },
          { type: "number", name: "sortOrder", max: 9999 },
          // Written by the push sender, not by staff. An empty value is the
          // sender's work queue; the app never reads it. NB: field type
          // "datetime" is silently dropped by PocketBase 0.40.6's JSVM, so the
          // queue marker uses day granularity, which is all the sender needs.
          { type: "date", name: "pushedAt" },
        ],
        indexes: ["CREATE INDEX `idx_notices_published` ON `notices` (`published`, `sortOrder`)"],
        // Drafts stay invisible to patients; superusers bypass rules entirely.
        listRule: "published = true",
        viewRule: "published = true",
        createRule: null,
        updateRule: null,
        deleteRule: null,
        options: {},
      }),
    );

    // ------------------------------------------------------------ clinic_config
    app.save(
      new Collection({
        id: "pb_clinic_config",
        name: "clinic_config",
        type: "base",
        system: false,
        fields: [
          // Constant value plus a unique index keeps exactly one row.
          { type: "text", name: "singleton", required: true, max: 20 },
          { type: "text", name: "nameNp", max: 200 },
          { type: "text", name: "nameEn", max: 200 },
          { type: "text", name: "shortNameNp", max: 120 },
          { type: "text", name: "shortNameEn", max: 120 },
          { type: "text", name: "addressNp", max: 300 },
          { type: "text", name: "addressEn", max: 300 },
          { type: "text", name: "phonePrimary", max: 30 },
          { type: "text", name: "phoneMobile", max: 30 },
          { type: "text", name: "whatsapp", max: 30 },
          { type: "email", name: "email" },
          { type: "text", name: "website", max: 120 },
          { type: "text", name: "facebookUrl", max: 200 },
          { type: "text", name: "mapsUrl", max: 400 },
          { type: "number", name: "openHour", min: 0, max: 23 },
          { type: "number", name: "closeHour", min: 1, max: 24 },
          { type: "number", name: "specialistCutoffHour", min: 1, max: 23 },
          // {"2026-11-28": []} style exceptions to the Saturday rotation.
          { type: "json", name: "saturdayOverrides" },
        ],
        indexes: ["CREATE UNIQUE INDEX `idx_clinic_config_singleton` ON `clinic_config` (`singleton`)"],
        listRule: "",
        viewRule: "",
        createRule: null,
        updateRule: null,
        deleteRule: null,
        options: {},
      }),
    );

    // ------------------------------------------------------------ appointments
    app.save(
      new Collection({
        id: "pb_appointments",
        name: "appointments",
        type: "base",
        system: false,
        fields: [
          { type: "relation", name: "patient", required: true, collectionId: "pb_patients", maxSelect: 1, cascadeDelete: false },
          { type: "text", name: "patientName", presentable: true, required: true, max: 120 },
          { type: "text", name: "phone", required: true, max: 30 },
          { type: "text", name: "departmentCode", required: true, max: 40 },
          { type: "text", name: "departmentName", required: true, max: 200 },
          { type: "text", name: "doctorCode", max: 40 },
          { type: "text", name: "doctorName", max: 200 },
          { type: "date", name: "date", required: true },
          { type: "text", name: "slot", max: 5 },
          { type: "number", name: "fee", min: 0, max: 100000 },
          { type: "select", name: "status", required: true, maxSelect: 1, values: ["booked", "completed", "cancelled"] },
          { type: "autodate", name: "created", onCreate: true, onUpdate: false },
          { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
        ],
        indexes: [
          // One live booking per patient, doctor and date. Cancelled rows are
          // excluded so re-booking after a cancellation still works.
          "CREATE UNIQUE INDEX `idx_apt_one_per_doctor_day` ON `appointments` (`patient`, `doctorCode`, `date`) WHERE `status` != 'cancelled'",
          "CREATE INDEX `idx_apt_doctor_date` ON `appointments` (`doctorCode`, `date`)",
          "CREATE INDEX `idx_apt_patient` ON `appointments` (`patient`, `status`)",
        ],
        listRule: "@request.auth.id != '' && patient = @request.auth.id",
        viewRule: "@request.auth.id != '' && patient = @request.auth.id",
        createRule: "@request.auth.id != '' && patient = @request.auth.id",
        updateRule: "@request.auth.id != '' && patient = @request.auth.id",
        deleteRule: null,
        options: {},
      }),
    );

    // ----------------------------------------------------------------- devices
    app.save(
      new Collection({
        id: "pb_devices",
        name: "devices",
        type: "base",
        system: false,
        fields: [
          { type: "relation", name: "patient", required: true, collectionId: "pb_patients", maxSelect: 1, cascadeDelete: true },
          { type: "text", name: "token", presentable: true, required: true, max: 500 },
          { type: "text", name: "platform", max: 20 },
        ],
        indexes: ["CREATE UNIQUE INDEX `idx_devices_token` ON `devices` (`token`)"],
        listRule: "@request.auth.id != '' && patient = @request.auth.id",
        viewRule: "@request.auth.id != '' && patient = @request.auth.id",
        createRule: "@request.auth.id != '' && patient = @request.auth.id",
        updateRule: "@request.auth.id != '' && patient = @request.auth.id",
        deleteRule: "@request.auth.id != '' && patient = @request.auth.id",
        options: {},
      }),
    );

    // ----------------------------------------------------------- notifications
    app.save(
      new Collection({
        id: "pb_notifications",
        name: "notifications",
        type: "base",
        system: false,
        fields: [
          { type: "relation", name: "patient", required: true, collectionId: "pb_patients", maxSelect: 1, cascadeDelete: true },
          // Stored as an event plus the data needed to render it, not as
          // finished text: the server has no Bikram Sambat table and no
          // Nepali-digit formatting, and both belong to the app's l10n layer.
          { type: "select", name: "event", presentable: true, required: true, maxSelect: 1, values: ["confirmed", "rescheduled", "cancelled", "completed"] },
          { type: "text", name: "refId", required: true, max: 40 },
          { type: "json", name: "meta" },
          { type: "bool", name: "read" },
          { type: "autodate", name: "created", onCreate: true, onUpdate: false },
          { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
        ],
        indexes: [
          "CREATE INDEX `idx_notifications_patient` ON `notifications` (`patient`, `read`, `created`)",
        ],
        listRule: "@request.auth.id != '' && patient = @request.auth.id",
        viewRule: "@request.auth.id != '' && patient = @request.auth.id",
        // Only hooks write these; a patient cannot invent an event about
        // themselves, and cannot delete one either.
        createRule: null,
        updateRule: "@request.auth.id != '' && patient = @request.auth.id",
        deleteRule: null,
        options: {},
      }),
    );

    // ---------------------------------------------------------------- counters
    app.save(
      new Collection({
        id: "pb_counters",
        name: "counters",
        type: "base",
        system: false,
        fields: [
          { type: "text", name: "key", presentable: true, required: true, max: 60 },
          { type: "number", name: "value", min: 0 },
        ],
        indexes: ["CREATE UNIQUE INDEX `idx_counters_key` ON `counters` (`key`)"],
        listRule: null,
        viewRule: null,
        createRule: null,
        updateRule: null,
        deleteRule: null,
        options: {},
      }),
    );

    // PocketBase seeds a default "users" auth collection on first boot. A
    // second, unruled table of people has no use here.
    try {
      app.delete(app.findCollectionByNameOrId("users"));
    } catch (_) {
      // not present
    }
  },
  (app) => {
    for (const name of [
      "counters",
      "devices",
      "notifications",
      "appointments",
      "clinic_config",
      "notices",
      "doctors",
      "departments",
      "patients",
    ]) {
      try {
        app.delete(app.findCollectionByNameOrId(name));
      } catch (_) {
        // already gone
      }
    }
  },
);
