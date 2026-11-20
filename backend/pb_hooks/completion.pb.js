/// <reference path="../pb_data/types.d.ts" />

// A booked visit that has passed is history, not a slot still owed to someone.
// Doing this server-side means every device agrees on the status instead of
// each app rewriting its own copy at an arbitrary hour.
//
// Handlers are self-contained — see the note at the top of appointments.pb.js.

// Runs on the hour; the work is idempotent, so the exact minute the Nepali day
// ends does not matter and a missed hour is caught by the next one.
cronAdd("appointments_complete_past", "0 * * * *", () => {
  // Today in the clinic's calendar. The VPS is in Europe while Nepal is
  // UTC+5:45 year-round, so server-local "today" is the wrong day for hours.
  const now = new Date();
  const utcMs = now.getTime() + now.getTimezoneOffset() * 60000;
  const nst = new Date(utcMs + (5 * 60 + 45) * 60000);

  let month = String(nst.getMonth() + 1);
  let day = String(nst.getDate());
  while (month.length < 2) month = "0" + month;
  while (day.length < 2) day = "0" + day;
  const today = nst.getFullYear() + "-" + month + "-" + day;

  const pending = $app.findRecordsByFilter(
    "appointments",
    "status = 'booked' && date < {:today}",
    "",
    -1,
    0,
    { today: today },
  );

  let done = 0;
  for (const record of pending) {
    try {
      record.set("status", "completed");
      $app.save(record);
      done++;
    } catch (err) {
      console.error("could not complete appointment " + record.id + ": " + err);
    }
  }

  if (done) {
    console.info("marked " + done + " past bookings completed");
  }
});
