#!/usr/bin/env python3
"""Turns the app's catalog into the PocketBase seed migration.

  flutter test test/_export_catalog_seed_test.dart
  python3 tool/gen_seed.py

The Dart side is the source of truth for the shipped defaults, which is why the
export runs inside the Flutter test harness rather than re-declaring the
departments and doctors here. Notices are intentionally left out: the ones the
app once carried are dated, so the clinic publishes its own.
"""

import json
import pathlib
import subprocess
import sys

EXPORT = "test/_export_catalog_seed_test.dart"
OUT = pathlib.Path("backend/pb_migrations/1766300010_seed_catalog.js")
JSON_PATH = pathlib.Path("/tmp/bsp_seed.json")

HEADER = """/// <reference path="../pb_data/types.d.ts" />

// Structural catalog exported from the app's own lib/data/catalog.dart, so the
// backend and a first-run app cannot disagree. Regenerate with:
//   flutter test test/_export_catalog_seed_test.dart
//   python3 tool/gen_seed.py
//
// Deliberately NOT seeded: notices. The ones the app shipped were dated and had
// passed, so publishing them would state something false to patients. The
// patientId counter starts at 0 and must be set to the clinic's real register
// number before go-live.

migrate(
  (app) => {
"""

FOOTER = """  },
  (app) => {
    for (const name of ["counters", "clinic_config", "doctors", "departments"]) {
      const collection = app.findCollectionByNameOrId(name);
      for (const record of app.findRecordsByFilter(collection, "", "", 0, 0)) {
        app.delete(record);
      }
    }
  },
);
"""


def block(name, rows):
    body = json.dumps(rows, ensure_ascii=False, indent=2)
    body = "\n".join("      " + line for line in body.splitlines())
    return f"""    const {name} = app.findCollectionByNameOrId("{name}");
    if (app.countRecords({name}) === 0) {{
      const rows = {body};
      rows.forEach((row) => {{
        app.save(new Record({name}, row));
      }});
    }}
"""


def main():
    if not JSON_PATH.exists():
        print("run the exporter first:")
        print("  flutter test", EXPORT)
        return 1

    data = json.loads(JSON_PATH.read_text())
    out = [HEADER]
    out.append(block("departments", data["departments"]))
    out.append(block("doctors", data["doctors"]))
    out.append(block("notices", []) if "notices" not in data else "")

    config = json.dumps(data["clinic"], ensure_ascii=False, indent=6)
    out.append(
        """
    const config = app.findCollectionByNameOrId("clinic_config");
    if (app.countRecords(config) === 0) {
      app.save(new Record(config, { singleton: "clinic", ...%s }));
    }

    const counters = app.findCollectionByNameOrId("counters");
    if (app.countRecords(counters) === 0) {
      app.save(new Record(counters, { key: "patientId", value: 0 }));
    }
"""
        % config
    )
    out.append(FOOTER)

    OUT.write_text("".join(out))
    print(
        f"wrote {OUT} with {len(data['departments'])} departments, "
        f"{len(data['doctors'])} doctors, {len(data['notices'])} notices"
    )
    subprocess.run(["node", "--check", str(OUT)], check=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
