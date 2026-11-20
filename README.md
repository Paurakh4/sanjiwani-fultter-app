# Battar Sanjibani

Patient app for **Battar Sanjibani Polyclinic** (Bidur-2, Sangamchowk, Nuwakot, Nepal).
Flutter, Android-first, Material 3, bilingual Nepali/English with Bikram Sambat dates.

Clinic identity, contact numbers and opening hours live in `lib/core/clinic.dart`.

## Status

The UI is complete. Patient data is still served from `lib/data/demo_data.dart` and cached in
SharedPreferences; the PocketBase backend (self-hosted, schema in `backend/`) replaces it. Until that
lands, the Records tab deliberately reads "चाँडै / coming soon" rather than showing invented reports.

## Development

```bash
flutter pub get
flutter run                 # debug, on the Expo_API_36 AVD
```

The emulator is fixed at **432×960dp** (1080×2400 @ 400dpi, 20:9) to match the clinic's test handset:

```bash
./tool/screen.sh status     # what the emulator is showing now
./tool/screen.sh small      # 360×800dp — the narrow end, where overflow actually appears
./tool/screen.sh ref        # back to the reference phone
```

Release builds need your own signing key (see below); debug builds do not.

## Checks

```bash
flutter analyze
flutter test
```

`test/` covers the pure domain logic — BS date conversion, the Saturday rotation (including the
unstaffed fourth Saturday of a five-Saturday month), the 17:00 specialist cutoff, slot availability —
plus the AppState booking/cancel/reschedule flows. Anything date-dependent is anchored to fixed dates,
so the suite does not drift with the calendar.

## Building

```bash
flutter build apk --release              # universal APK
flutter build apk --release --split-per-abi   # per-ABI, what the phone gets
```

Confirm the `✓ Built …` line rather than trusting a piped exit status, and record the artifact hash
before distributing. With split per-ABI builds, Flutter offsets `versionCode` per ABI.

### Release signing

`android/key.properties` is gitignored and never committed. A release build **fails on purpose**
when it is missing — the app is never signed with Flutter's public debug key.

```bash
keytool -genkeypair -v -keystore ~/bsp-release.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias bsp

chmod 600 ~/bsp-release.jks
```

Then create `android/key.properties`:

```properties
storeFile=/absolute/path/to/bsp-release.jks
storePassword=<the keystore password>
keyPassword=<the key password>
keyAlias=bsp
```

and `chmod 600 android/key.properties`. Keep both passwords yourself. Switching keys means the
debug-signed build has to be uninstalled first — signatures cannot be upgraded in place.

## Layout

| Path | Purpose |
|---|---|
| `lib/core/` | Clinic constants, Bikram Sambat dates, Saturday rotation, slot availability, l10n, design tokens |
| `lib/models.dart` | Patient, department, doctor, appointment, notice, notification types |
| `lib/state/app_state.dart` | The single `ChangeNotifier` every screen reads |
| `lib/data/demo_data.dart` | Current catalog (departments, doctors, fees, Saturday groups) — future backend seed |
| `lib/screens/`, `lib/widgets/` | UI |
| `backend/` | PocketBase migrations, hooks and config (added with the backend) |
| `tool/` | `screen.sh` emulator profile, `tapper.py` device tapping/screenshotting from the accessibility tree |

## Conventions

- Strings are added to both languages in `lib/core/l10n.dart` (`_t(np, en)`); nothing is hardcoded in a
  screen.
- Opening hours, fees and schedules come from `lib/core/`, never from a literal in the widget tree.
- `AppTokens` in `lib/core/tokens.dart` holds spacing, radii and motion. Use `AppTokens.scaled` for
  fixed-height containers so large system fonts do not overflow.
- Patient data must never leave the device by accident: auto-backup and device-to-device transfer are
  disabled in `android/app/src/main/AndroidManifest.xml` and `res/xml/data_extraction_rules.xml`.
