#!/usr/bin/env python3
"""Exercise the PocketBase schema, rules and hooks against a running instance.

  tool/api_check.py [--url http://127.0.0.1:8090] [--email dev@clinic.local]

Reads the superuser password from BSP_SUPERUSER_PASS, or from the local dev
file when pointed at the development instance. Nothing here writes outside the
database it is pointed at.
"""

import argparse
import json
import os
import ssl
import sys
import urllib.error
import urllib.request
from datetime import date, timedelta

try:
    import certifi
    _CTX = ssl.create_default_context(cafile=certifi.where())
except Exception:  # pragma: no cover - fall back to the system store
    _CTX = ssl.create_default_context()

results = []
created = []  # (collection, id) so a run against a live server cleans up after itself


def track(collection, record):
    if isinstance(record, dict) and record.get("id"):
        created.append((collection, record["id"]))
    return record


def purge(base, token):
    """Delete everything this run created.

    The patient relation does not cascade, so every row belonging to a test
    patient has to be removed explicitly before the patient itself goes, or the
    run would leave orphaned bookings and notifications behind on a live server.
    """
    patients = [rid for name, rid in created if name == "patients"]
    removed = 0
    for pid in patients:
        for collection in ("appointments", "notifications", "devices"):
            listed = api(
                base,
                "GET",
                f"/api/collections/{collection}/records?perPage=100"
                f"&filter=patient%3D%22{pid}%22",
                token=token,
            )[1]
            for row in listed.get("items", []):
                if api(base, "DELETE", f"/api/collections/{collection}/records/{row['id']}",
                       token=token)[0] in (204, 200):
                    removed += 1
    for name, rid in created:
        if name == "patients":
            if api(base, "DELETE", f"/api/collections/patients/records/{rid}",
                   token=token)[0] in (204, 200):
                removed += 1
    print(f"cleaned up {removed} test record(s) for {len(patients)} test patient(s)")


def check(name, ok, detail=""):
    results.append((name, bool(ok), detail))
    print(("  PASS  " if ok else "  FAIL  ") + name + (f"  [{detail}]" if detail else ""))


def api(base, method, path, body=None, token=None):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(base + path, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", token)
    try:
        with urllib.request.urlopen(req, context=_CTX, timeout=20) as resp:
            raw = resp.read().decode()
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            return e.code, json.loads(raw)
        except Exception:
            return e.code, {"raw": raw}
    except Exception as e:  # connection refused, TLS, etc.
        return 0, {"error": str(e)}


def reason(body):
    """The server sends "code|English text"; PocketBase capitalises the first
    letter of any message, so compare case-insensitively."""
    return body.get("message", "").split("|")[0].lower()


def saturdays(year, month):
    d = date(year, month, 1)
    out = []
    while d.month == month:
        if d.weekday() == 5:
            out.append(d)
        d += timedelta(days=1)
    return out


def nth_saturday(n):
    """The nth Saturday of next month — always in the future."""
    today = date.today()
    y, m = (today.year + 1, 1) if today.month == 12 else (today.year, today.month + 1)
    sats = saturdays(y, m)
    while len(sats) < n:
        y, m = (y + 1, 1) if m == 12 else (y, m + 1)
        sats = saturdays(y, m)
    return sats[n - 1]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", default="http://127.0.0.1:8090")
    ap.add_argument("--email", default="dev@clinic.local")
    ap.add_argument("--purge", action="store_true",
                    help="delete the records this run created when finished")
    args = ap.parse_args()
    base = args.url.rstrip("/")

    password = os.environ.get("BSP_SUPERUSER_PASS")
    if not password:
        local = os.path.join(os.path.dirname(__file__), "..", "backend", ".local", "dev-superuser-pass")
        if os.path.exists(local):
            password = open(local).read().strip()
    if not password:
        print("set BSP_SUPERUSER_PASS")
        return 2

    status, auth = api(base, "POST", "/api/collections/_superusers/auth-with-password",
                       {"identity": args.email, "password": password})
    if status != 200:
        print("superuser login failed", status, auth)
        return 2
    admin = auth["token"]
    print(f"\nPocketBase at {base}\n")

    # --- public catalog -----------------------------------------------------
    for collection in ("departments", "doctors", "clinic_config", "notices"):
        status, data = api(base, "GET", f"/api/collections/{collection}/records?perPage=5")
        check(f"anonymous can read {collection}", status == 200, f"{data.get('totalItems')} rows")

    status, _ = api(base, "GET", "/api/collections/counters/records")
    check("anonymous cannot read counters", status in (400, 403), f"http {status}")

    status, _ = api(base, "GET", "/api/collections/patients/records")
    check("anonymous cannot enumerate patients", status in (400, 403), f"http {status}")

    # --- signup and login ---------------------------------------------------
    phone_a = "98" + str(os.getpid()).rjust(8, "0")
    phone_b = "97" + str(os.getpid()).rjust(8, "0")
    email_b = f"bsp-check-{os.getpid()}@example.invalid"
    secret = "clinic-pass-1"

    status, a = api(base, "POST", "/api/collections/patients/records",
                    {"username": phone_a, "name": "Test Patient A",
                     "password": secret, "passwordConfirm": secret})
    if status == 200:
        track("patients", a)
    check("phone-only signup works", status == 200, f"http {status} {a.get('patientId', a.get('message',''))}")
    status, b = api(base, "POST", "/api/collections/patients/records",
                    {"username": phone_b, "name": "Test Patient B",
                     "password": secret, "passwordConfirm": secret,
                     "email": email_b})
    if status == 200:
        track("patients", b)
    check("signup with an email too", status == 200, f"http {status} {b.get('patientId', b.get('message',''))}")

    if status != 200 or a.get("patientId") is None:
        return finish()

    check("register numbers are sequential",
          a["patientId"] != b["patientId"] and a["patientId"].startswith("BSP-"),
          f"{a['patientId']} then {b['patientId']}")

    # A register number is issued only when the signup actually lands. PocketBase
    # validates some fields after the create hook runs, so a signup that fails
    # there would otherwise take a number with it — a gap in the register that
    # looks like a deleted patient. The expected numbers come from the counter
    # itself, because a purged run leaves it where it stopped (numbers are never
    # handed out twice, on purpose).
    status, dupe = api(base, "POST", "/api/collections/patients/records",
                       {"username": phone_a, "name": "Test Patient A",
                        "password": secret, "passwordConfirm": secret})
    check("a duplicate phone number is refused with a readable reason",
          status == 400 and reason(dupe) == "signup_phone_taken",
          dupe.get("message", "")[:60])
    status, short = api(base, "POST", "/api/collections/patients/records",
                        {"username": "91" + phone_a[2:], "name": "A",
                         "password": secret, "passwordConfirm": secret})
    check("a name too short to save does not burn a number",
          status == 400, f"http {status}")
    _, counter_row = api(base, "GET", "/api/collections/counters/records", token=admin)
    issued = counter_row["items"][0]["value"] if counter_row["items"] else 0
    status, c = api(base, "POST", "/api/collections/patients/records",
                    {"username": "92" + phone_a[2:], "name": "Test Patient C",
                     "password": secret, "passwordConfirm": secret})
    if status == 200:
        track("patients", c)
    check("after two failed signups the next one is still in line",
          status == 200
          and c.get("patientId") == "BSP-" + str(issued + 1).rjust(4, "0"),
          f"counter {issued}, got {c.get('patientId', c.get('message', ''))}")

    status, by_phone = api(base, "POST", "/api/collections/patients/auth-with-password",
                           {"identity": phone_a, "password": secret})
    check("login by phone number", status == 200, f"http {status}")
    status, by_email = api(base, "POST", "/api/collections/patients/auth-with-password",
                           {"identity": email_b, "password": secret})
    check("login by email address", status == 200, f"http {status}")
    status, _ = api(base, "POST", "/api/collections/patients/auth-with-password",
                    {"identity": phone_a, "password": "wrong-password"})
    check("wrong password rejected", status == 400, f"http {status}")

    if by_phone.get("token") is None:
        return finish()
    tok_a, tok_b = by_phone["token"], by_email["token"]

    status, _ = api(base, "GET", "/api/collections/patients/records", token=tok_a)
    check("a patient cannot list patients", status in (400, 403), f"http {status}")

    # --- booking ------------------------------------------------------------
    third = nth_saturday(3)
    second = nth_saturday(2)
    date_text = third.isoformat()

    doctors = api(base, "GET", "/api/collections/doctors/records?perPage=100&filter="
                            "saturdayGroup%20%3D%20%27third%27")[1]["items"]
    if not doctors:
        print("no third-Saturday doctor seeded")
        return finish()
    rajan = doctors[0]
    status, physicians = api(base, "GET",
                            "/api/collections/departments/records?filter=code%3D%27physician%27")

    status, apt = api(base, "POST", "/api/collections/appointments/records",
                      {"patient": a["id"], "patientName": "Test Patient A", "phone": phone_a,
                       "departmentCode": rajan["departmentCode"], "doctorCode": rajan["code"],
                       "date": date_text, "status": "booked", "fee": 1},
                      token=tok_a)
    if status == 200:
        track("appointments", apt)
    check("patient can book their own visit", status == 200, f"http {status} {apt.get('message','')}")
    if status != 200:
        return finish()

    check("price comes from the catalog, not the client",
          apt["fee"] == rajan["fee"], f"sent 1, stored {apt['fee']}, catalog {rajan['fee']}")
    check("department name is filled server-side", bool(apt.get("departmentName")),
          apt.get("departmentName", ""))

    status, feed = api(base, "GET", "/api/collections/notifications/records", token=tok_a)
    check("booking writes exactly one feed row",
          status == 200 and [r["event"] for r in feed.get("items", [])] == ["confirmed"],
          str([r["event"] for r in feed.get("items", [])]))
    check("the row carries the data needed to render it locally",
          bool(feed.get("items")) and feed["items"][0]["meta"].get("date") == date_text,
          json.dumps(feed["items"][0]["meta"])[:70] if feed.get("items") else "")

    status, dup = api(base, "POST", "/api/collections/appointments/records",
                      {"patient": a["id"], "patientName": "Test Patient A", "phone": phone_a,
                       "departmentCode": rajan["departmentCode"], "doctorCode": rajan["code"],
                       "date": date_text, "status": "booked"},
                      token=tok_a)
    check("the same patient cannot book that doctor twice",
          reason(dup) == "already_booked",
          dup.get("message", "")[:60])

    status, wrong = api(base, "POST", "/api/collections/appointments/records",
                        {"patient": a["id"], "patientName": "A", "phone": phone_a,
                         "departmentCode": rajan["departmentCode"], "doctorCode": rajan["code"],
                         "date": second.isoformat(), "status": "booked"},
                        token=tok_a)
    check("a doctor only sits on their own Saturday",
          reason(wrong) == "booking_not_scheduled",
          wrong.get("message", "")[:60])

    past = (date.today() - timedelta(days=7)).isoformat()
    status, old = api(base, "POST", "/api/collections/appointments/records",
                      {"patient": a["id"], "patientName": "A", "phone": phone_a,
                       "departmentCode": rajan["departmentCode"], "doctorCode": rajan["code"],
                       "date": past, "status": "booked"},
                      token=tok_a)
    check("a past date is refused",
          reason(old) == "booking_date_past",
          old.get("message", "")[:60])

    status, _ = api(base, "POST", "/api/collections/appointments/records",
                    {"patient": a["id"], "patientName": "A", "phone": phone_a,
                     "departmentCode": rajan["departmentCode"], "doctorCode": rajan["code"],
                     "date": date_text, "status": "booked"})
    check("anonymous cannot book", status in (400, 403), f"http {status}")

    status, _ = api(base, "POST", "/api/collections/appointments/records",
                    {"patient": b["id"], "patientName": "B", "phone": phone_b,
                     "departmentCode": rajan["departmentCode"], "doctorCode": rajan["code"],
                     "date": date_text, "status": "booked"},
                    token=tok_a)
    check("a patient cannot book on someone else's account", status in (400, 403), f"http {status}")

    status, seen_a = api(base, "GET", "/api/collections/appointments/records", token=tok_a)
    status, seen_b = api(base, "GET", "/api/collections/appointments/records", token=tok_b)
    check("each patient sees only their own bookings",
          seen_a.get("totalItems") == 1 and seen_b.get("totalItems") == 0,
          f"A sees {seen_a.get('totalItems')}, B sees {seen_b.get('totalItems')}")

    # --- capacity -----------------------------------------------------------
    status, updated = api(base, "PATCH", f"/api/collections/doctors/records/{rajan['id']}",
                          {"capacity": 1}, token=admin)
    check("staff can set a capacity", status == 200, f"http {status}")
    status, full = api(base, "POST", "/api/collections/appointments/records",
                       {"patient": b["id"], "patientName": "B", "phone": phone_b,
                        "departmentCode": rajan["departmentCode"], "doctorCode": rajan["code"],
                        "date": date_text, "status": "booked"},
                       token=tok_b)
    check("capacity stops a second patient taking the last slot",
          reason(full) == "booking_full",
          full.get("message", "")[:60])
    api(base, "PATCH", f"/api/collections/doctors/records/{rajan['id']}", {"capacity": 0}, token=admin)

    # --- cancel then re-book -------------------------------------------------
    status, _ = api(base, "PATCH", f"/api/collections/appointments/records/{apt['id']}",
                    {"status": "cancelled"}, token=tok_a)
    check("patient can cancel", status == 200, f"http {status}")
    status, feed2 = api(base, "GET", "/api/collections/notifications/records?sort=-created", token=tok_a)
    check("cancelling is reported in the feed too",
          [r["event"] for r in feed2.get("items", [])][:1] == ["cancelled"],
          str([r["event"] for r in feed2.get("items", [])]))
    status, again = api(base, "POST", "/api/collections/appointments/records",
                        {"patient": a["id"], "patientName": "A", "phone": phone_a,
                         "departmentCode": rajan["departmentCode"], "doctorCode": rajan["code"],
                         "date": date_text, "status": "booked"},
                        token=tok_a)
    check("cancelling frees the slot for re-booking", status == 200,
          f"http {status} {again.get('message','')}")

    # A visit is attended only when the clinic says so. Both halves matter: the
    # status is forced on the way in, and a patient cannot PATCH it afterwards.
    status, fake = api(base, "POST", "/api/collections/appointments/records",
                       {"patient": b["id"], "patientName": "B", "phone": phone_b,
                        "departmentCode": rajan["departmentCode"], "doctorCode": rajan["code"],
                        "date": date_text, "status": "completed"},
                       token=tok_b)
    if status == 200:
        track("appointments", fake)
    check("a new booking cannot arrive already completed",
          status == 200 and fake.get("status") == "booked",
          f"sent completed, stored {fake.get('status', fake.get('message', ''))}")

    status, done = api(base, "PATCH", f"/api/collections/appointments/records/{fake.get('id', '')}",
                       {"status": "completed"}, token=tok_b)
    check("a patient cannot mark their own visit completed",
          reason(done) == "booking_completed", done.get("message", "")[:60])

    status, _ = api(base, "PATCH", f"/api/collections/appointments/records/{fake.get('id', '')}",
                    {"status": "completed"}, token=admin)
    check("the clinic can mark it completed", status == 200, f"http {status}")

    status, _ = api(base, "POST", "/api/collections/notifications/records",
                    {"patient": a["id"], "event": "confirmed", "refId": "x"}, token=tok_a)
    check("a patient cannot write their own notification feed",
          status in (400, 403), f"http {status}")

    # --- notices -------------------------------------------------------------
    notices = api(base, "GET", "/api/collections/notices/records")[1]["totalItems"]
    check("no notices are visible until published", notices == 0, f"{notices} visible")
    status, draft = api(base, "POST", "/api/collections/notices/records",
                        {"title": "Draft", "body": "not public yet", "published": False},
                        token=admin)
    if status == 200:
        track("notices", draft)
    check("staff can hold a draft", status == 200, f"http {status}")
    if status == 200:
        status, _ = api(base, "GET", f"/api/collections/notices/records/{draft['id']}")
        check("a draft is invisible to patients", status in (400, 404), f"http {status}")
        api(base, "DELETE", f"/api/collections/notices/records/{draft['id']}", token=admin)

    # --- identity guard ------------------------------------------------------
    status, _ = api(base, "PATCH", f"/api/collections/patients/records/{a['id']}",
                    {"patientId": "BSP-9999"}, token=admin)
    status, after = api(base, "GET", f"/api/collections/patients/records/{a['id']}", token=admin)
    check("a register number cannot be rewritten", after.get("patientId") == a["patientId"],
          f"still {after.get('patientId')}")

    if args.purge:
        purge(base, admin)
    return finish()


def finish():
    failed = [name for name, ok, _ in results if not ok]
    print(f"\n{len(results) - len(failed)}/{len(results)} checks passed")
    if failed:
        print("failed: " + ", ".join(failed))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
