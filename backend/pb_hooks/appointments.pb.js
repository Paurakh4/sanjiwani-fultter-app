/// <reference path="../pb_data/types.d.ts" />

// Booking authority. The app pre-checks against its own cached list, which can
// only ever see one patient's bookings; this is the only place that can see
// everyone's. Price, doctor and department names are also taken from the
// catalog here so a client cannot book a specialist at a physician's fee.
//
// Everything lives inside one self-contained function: PocketBase 0.40.6
// re-evaluates a hook handler in a pooled JS runtime, so a handler that calls
// a helper declared at file scope fails with "function is not defined". The
// same rule rules out a closure built by a factory — whatever it captured is
// gone by the time a request arrives.

const validateBooking = function (e) {
  const app = e.app;
  const record = e.record;

  // `e.type` is the only self-contained way to tell the two registrations
  // apart: a handler cannot close over anything from file scope, because
  // PocketBase re-evaluates its source per request.
  const isCreate = e.type === "create";

  if (isCreate) {
    // A booking starts as a booking. Without this a client could create a row
    // already marked completed, or cancelled, and skip the queue.
    record.set("status", "booked");
  }

  // A cancellation never needs a schedulable date.
  if (record.getString("status") === "cancelled") {
    e.next();
    return;
  }

  /** A `date` field arrives as "YYYY-MM-DD"; parse it component-wise so the
   *  day does not shift with the server's own timezone. */
  function clinicDate(value) {
    if (!value) return null;
    const parts = String(value).slice(0, 10).split("-");
    if (parts.length !== 3) return null;
    return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
  }

  /**
   * Today in the clinic's own calendar. The VPS sits in Europe, so server-local
   * "today" is a different day for hours of every Nepali night. Nepal is
   * UTC+5:45 all year — there is no daylight saving to track.
   */
  function nstNow() {
    const now = new Date();
    const utcMs = now.getTime() + now.getTimezoneOffset() * 60000;
    return new Date(utcMs + (5 * 60 + 45) * 60000);
  }

  function dayStart(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  }

  function saturdayGroupForDate(date) {
    if (!date || date.getDay() !== 6) return null;
    const ordinal = Math.floor((date.getDate() - 1) / 7) + 1;
    if (ordinal <= 3) return ["first", "second", "third"][ordinal - 1];
    const next = new Date(date.getFullYear(), date.getMonth(), date.getDate() + 7);
    return next.getMonth() === date.getMonth() ? null : "last";
  }

  /**
   * PocketBase rewrites any structured error data into generic field errors, so
   * the machine-readable reason travels as a `code|English text` prefix. The
   * app splits on the first "|" and localizes the code itself; the English half
   * is only there for the dashboard and for debugging.
   */
  function reject(code, message) {
    throw new ApiError(400, code + "|" + message);
  }

  function countBooked(doctorCode, day, excludeId) {
    // A `date` field is stored as a UTC timestamp, so equality against
    // "YYYY-MM-DD" matches nothing; the dynamic operator is the day match.
    let filter = "doctorCode = {:d} && date ~ {:dt} && status != 'cancelled'";
    const params = { d: doctorCode, dt: day };
    if (excludeId) {
      filter += " && id != {:ex}";
      params.ex = excludeId;
    }
    return app.findRecordsByFilter("appointments", filter, "", -1, 0, params).length;
  }

  const date = clinicDate(record.getString("date"));
  if (!date) reject("booking_date", "A valid visit date is required.");

  const now = nstNow();
  const today = dayStart(now);
  if (date.getTime() < today.getTime()) {
    reject("booking_date_past", "That date has already passed.");
  }

  let config;
  try {
    config = app.findFirstRecordByFilter("clinic_config", "singleton = {:s}", {
      s: "clinic",
    });
  } catch (err) {
    config = null;
  }
  const cutoff = config ? config.getInt("specialistCutoffHour") : 17;

  if (date.getTime() === today.getTime() && now.getHours() >= cutoff) {
    reject("booking_cutoff", "Same-day specialist bookings have closed for today.");
  }

  const doctorCode = record.getString("doctorCode");
  if (!doctorCode) {
    // A plain clinic-service visit has no rotation to honour.
    record.set("doctorName", "");
    record.set("fee", 0);
    e.next();
    return;
  }

  let doctor;
  try {
    doctor = app.findFirstRecordByData("doctors", "code", doctorCode);
  } catch (err) {
    doctor = null;
  }
  if (!doctor) reject("booking_doctor", "That doctor is not in the current roster.");

  const day = String(record.getString("date")).slice(0, 10);

  // Date-specific exceptions the clinic announces in advance, e.g.
  // {"2026-12-12": ["sunita"]} replaces the whole rotation for that Saturday.
  const overrides = config ? config.get("saturdayOverrides") : null;
  const overridden =
    overrides && Object.prototype.hasOwnProperty.call(overrides, day);

  if (overridden) {
    if ((overrides[day] || []).indexOf(doctorCode) === -1) {
      reject("booking_not_scheduled", "That doctor is not sitting on that date.");
    }
  } else {
    const group = doctor.getString("saturdayGroup");
    if (group) {
      if (saturdayGroupForDate(date) !== group) {
        reject(
          "booking_not_scheduled",
          "That doctor only sees patients on the " + group + " Saturday.",
        );
      }
    } else {
      const weekdays = doctor.get("weekdays") || [];
      const clinicDay = date.getDay() === 0 ? 7 : date.getDay();
      if (weekdays.indexOf(clinicDay) === -1) {
        reject("booking_not_scheduled", "That doctor does not sit on that day.");
      }
    }
  }

  const capacity = doctor.getInt("capacity");
  if (capacity > 0 && countBooked(doctorCode, day, record.id) >= capacity) {
    reject("booking_full", "That doctor is already fully booked that day.");
  }

  // The unique index is the race-proof backstop; this only turns the collision
  // into something a patient can read.
  const mine = app.findRecordsByFilter(
    "appointments",
    "patient = {:p} && doctorCode = {:d} && date ~ {:dt} && status != 'cancelled'",
    "",
    1,
    0,
    { p: record.getString("patient"), d: doctorCode, dt: day },
  );
  if (mine.length && mine[0].id !== record.id) {
    reject(
      "already_booked",
      "You already have a visit booked with that doctor on that date.",
    );
  }

  let department;
  try {
    department = app.findFirstRecordByData(
      "departments",
      "code",
      doctor.getString("departmentCode"),
    );
  } catch (err) {
    department = null;
  }

  record.set("departmentCode", doctor.getString("departmentCode"));
  record.set(
    "departmentName",
    department
      ? department.getString("nameEn") + " / " + department.getString("nameNp")
      : doctor.getString("departmentCode"),
  );
  record.set(
    "doctorName",
    doctor.getString("nameEn") + " / " + doctor.getString("nameNp"),
  );
  record.set("fee", doctor.getInt("fee"));
  if (!record.getString("slot")) {
    record.set("slot", doctor.getString("startTime"));
  }

  e.next();
};

onRecordCreate(validateBooking, "appointments");
onRecordUpdate(validateBooking, "appointments");
// Only the clinic marks a visit attended. This has to sit on the *request*
// event because the save-level event carries no information about who asked;
// the hourly cron never reaches here, since it saves through $app directly.
onRecordUpdateRequest(function (e) {
  if (e.record.getString("status") !== "completed" || e.hasSuperuserAuth()) {
    e.next();
    return;
  }
  throw new ApiError(
    400,
    "booking_completed|Only the clinic can mark a visit completed.",
  );
}, "appointments");
