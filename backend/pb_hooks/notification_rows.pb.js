/// <reference path="../pb_data/types.d.ts" />

// Every booking change that a patient should see in their notifications tab
// writes one row for that patient. Written inside the validate-stage hook so a
// rejected update leaves no feed entry behind.
//
// The two handlers repeat a small `insert` helper on purpose: PocketBase 0.40.6
// re-evaluates each handler in its own JS runtime, so a helper declared at file
// scope is not reachable from inside one. See backend/README.md.

onRecordCreate((e) => {
  const record = e.record;

  const row = new Record(e.app.findCollectionByNameOrId("notifications"), {
    patient: record.getString("patient"),
    event: "confirmed",
    refId: record.id,
    read: false,
    meta: {
      date: String(record.getString("date")).slice(0, 10),
      departmentCode: record.getString("departmentCode"),
      doctorCode: record.getString("doctorCode"),
    },
  });
  e.app.save(row);

  e.next();
}, "appointments");

onRecordUpdate((e) => {
  const record = e.record;

  let before;
  try {
    before = e.app.findRecordById("appointments", record.id);
  } catch (err) {
    before = null;
  }
  if (!before) {
    e.next();
    return;
  }

  const wasDate = String(before.getString("date")).slice(0, 10);
  const nowDate = String(record.getString("date")).slice(0, 10);
  const status = record.getString("status");

  let event = null;
  if (status === "cancelled" && before.getString("status") !== "cancelled") {
    event = "cancelled";
  } else if (status === "completed" && before.getString("status") !== "completed") {
    event = "completed";
  } else if (nowDate !== wasDate && status === "booked") {
    event = "rescheduled";
  }

  if (event) {
    const row = new Record(e.app.findCollectionByNameOrId("notifications"), {
      patient: record.getString("patient"),
      event: event,
      refId: record.id,
      read: false,
      meta: {
        date: nowDate,
        previousDate: wasDate,
        departmentCode: record.getString("departmentCode"),
        doctorCode: record.getString("doctorCode"),
      },
    });
    e.app.save(row);
  }

  e.next();
}, "appointments");
