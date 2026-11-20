import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fonts.dart';
import '../core/l10n.dart';
import '../core/palette.dart';
import '../core/saturday_schedule.dart';
import '../core/slot_availability.dart';
import '../data/demo_data.dart';
import '../models.dart';

class AppState extends ChangeNotifier {
  AppState._(this._prefs);

  final SharedPreferences _prefs;

  static const _kSeeded = 'seeded_v1';
  static const _kOnboarded = 'onboarded_v1';
  static const _kProfile = 'profile_v1';
  static const _kAppointments = 'appointments_v1';
  static const _kNotifications = 'notifications_v1';
  static const _kThemeMode = 'theme_mode_v1';
  static const _kLanguage = 'language_v1';
  static const _kDatePrimary = 'date_primary_v1';
  static const _kPalette = 'palette_v1';
  static const _kNepaliHeadingFont = 'nepali_heading_font_v1';
  static const _kNepaliBodyFont = 'nepali_body_font_v1';
  static const _kEnglishFont = 'english_font_v1';
  static const _kSignedIn = 'signed_in_v1';
  static const _kTabOrder = 'tab_order_v1';

  late PatientProfile profile;
  List<Appointment> appointments = [];
  List<AppNotification> notifications = [];
  ThemeMode themeMode = ThemeMode.system;
  AppLanguage language = AppLanguage.np;
  DatePrimary datePrimary = DatePrimary.nepali;
  AppPalette palette = AppPalette.green;
  NepaliFont nepaliHeadingFont = NepaliFont.anek;
  NepaliFont nepaliBodyFont = NepaliFont.mukta;
  EnglishFont englishFont = EnglishFont.poppins;
  bool onboarded = false;
  bool signedIn = false;

  /// Bottom-bar tab ids in display order (see RootShell for the id mapping).
  List<int> tabOrder = const [0, 4, 1, 2, 3];

  AppFonts get fonts => AppFonts(
    nepaliHeading: nepaliHeadingFont,
    nepaliBody: nepaliBodyFont,
    english: englishFont,
  );

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final state = AppState._(prefs);
    state._restore();
    return state;
  }

  void _restore() {
    final seeded = _prefs.getBool(_kSeeded) ?? false;
    if (!seeded) {
      profile = demoProfile();
      appointments = demoAppointments();
      notifications = demoNotifications();
      _persistProfile();
      _persistAppointments();
      _persistNotifications();
      _prefs.setBool(_kSeeded, true);
    } else {
      profile = _readJson(_kProfile, PatientProfile.fromJson) ?? demoProfile();
      appointments = _readList(_kAppointments, Appointment.fromJson);
      notifications = _readList(_kNotifications, AppNotification.fromJson);
    }

    _reanchorDemoUpcoming();
    normalizeCompleted();

    themeMode = switch (_prefs.getString(_kThemeMode)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    language = _prefs.getString(_kLanguage) == 'en'
        ? AppLanguage.en
        : AppLanguage.np;
    datePrimary = _prefs.getString(_kDatePrimary) == 'english'
        ? DatePrimary.english
        : DatePrimary.nepali;
    final paletteId = _prefs.getString(_kPalette);
    palette = AppPalette.values.firstWhere(
      (value) => value.id == paletteId,
      orElse: () => AppPalette.green,
    );
    final nepaliHeadingName = _prefs.getString(_kNepaliHeadingFont);
    nepaliHeadingFont = NepaliFont.values.firstWhere(
      (value) => value.name == nepaliHeadingName,
      orElse: () => NepaliFont.anek,
    );
    final nepaliBodyName = _prefs.getString(_kNepaliBodyFont);
    nepaliBodyFont = NepaliFont.values.firstWhere(
      (value) => value.name == nepaliBodyName,
      orElse: () => NepaliFont.mukta,
    );
    final englishFontName = _prefs.getString(_kEnglishFont);
    englishFont = EnglishFont.values.firstWhere(
      (value) => value.name == englishFontName,
      orElse: () => EnglishFont.poppins,
    );
    onboarded = _prefs.getBool(_kOnboarded) ?? false;
    signedIn = _prefs.getBool(_kSignedIn) ?? false;
    tabOrder = _restoreTabOrder();
    if (!onboarded && themeMode == ThemeMode.system) {
      themeMode = ThemeMode.light;
      _prefs.setString(_kThemeMode, 'light');
    }
  }

  T? _readJson<T>(String key, T Function(Map<String, dynamic>) parse) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return parse(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error) {
      debugPrint('AppState: corrupt "$key" ($error); backing up raw value.');
      _prefs.setString('${key}_corrupt', raw);
      return null;
    }
  }

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) parse) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((entry) => parse(entry as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('AppState: corrupt "$key" ($error); backing up raw value.');
      _prefs.setString('${key}_corrupt', raw);
      return [];
    }
  }

  int get unreadCount =>
      notifications.where((notification) => !notification.read).length;

  List<Appointment> get upcomingAppointments {
    final list = appointments
        .where((appointment) => appointment.isUpcoming)
        .toList();
    list.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.slot.compareTo(b.slot);
    });
    return list;
  }

  List<Appointment> get pastAppointments {
    final list = appointments
        .where((appointment) => !appointment.isUpcoming)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Books a specialist visit for a date only (no time slot). Returns null when
  /// the date is no longer bookable or the same doctor is already booked then.
  Appointment? bookAppointment({
    required Department department,
    Doctor? doctor,
    required DateTime date,
    required String patientName,
    required String phone,
  }) {
    final now = DateTime.now();
    final day = dateOnly(date);
    if (doctor != null) {
      if (!isDateBookable(doctor: doctor, date: day, now: now)) return null;
      if (hasBookingOn(
        appointments: appointments,
        doctorId: doctor.id,
        date: day,
      )) {
        return null;
      }
    }
    final appointment = Appointment(
      id: 'apt-${now.microsecondsSinceEpoch}',
      departmentId: department.id,
      departmentName: department.displayName,
      doctorId: doctor?.id,
      doctorName: doctor?.displayName ?? kClinicServiceDisplayName,
      date: day,
      slot: doctor?.startTime ?? '09:00',
      patientName: patientName.trim(),
      phone: phone.trim(),
      fee: doctor?.fee ?? 0,
      status: AppointmentStatus.booked,
      createdAt: now,
    );

    final np = const L10n(AppLanguage.np);
    final en = const L10n(AppLanguage.en);
    appointments = [...appointments, appointment];
    notifications = [
      AppNotification(
        id: 'notif-${now.microsecondsSinceEpoch}',
        title: np.appointmentConfirmedTitle,
        body: np.appointmentConfirmedBody(appointment.date, department.nameNp),
        titleEn: en.appointmentConfirmedTitle,
        bodyEn: en.appointmentConfirmedBody(
          appointment.date,
          department.nameEn,
        ),
        time: now,
        kind: 'appointment',
        refId: appointment.id,
      ),
      ...notifications,
    ];

    _persistAppointments();
    _persistNotifications();
    notifyListeners();
    return appointment;
  }

  void cancelAppointment(String id) {
    final index = appointments.indexWhere(
      (appointment) => appointment.id == id,
    );
    if (index == -1) return;
    if (appointments[index].status != AppointmentStatus.booked) return;
    appointments = List.of(appointments)
      ..[index] = appointments[index].copyWith(
        status: AppointmentStatus.cancelled,
      );
    _persistAppointments();
    notifyListeners();
  }

  bool rescheduleAppointment(String id, {required DateTime date}) {
    final index = appointments.indexWhere(
      (appointment) => appointment.id == id,
    );
    if (index == -1) return false;
    final current = appointments[index];
    if (current.status != AppointmentStatus.booked) return false;
    final day = dateOnly(date);
    final doctor = doctorById(current.doctorId);
    if (doctor != null && !isDateBookable(doctor: doctor, date: day)) {
      return false;
    }
    if (hasBookingOn(
      appointments: appointments,
      doctorId: current.doctorId,
      date: day,
      excludingAppointmentId: id,
    )) {
      return false;
    }
    final now = DateTime.now();
    final updated = current.copyWith(date: day);
    appointments = List.of(appointments)..[index] = updated;
    final np = const L10n(AppLanguage.np);
    final en = const L10n(AppLanguage.en);
    notifications = [
      AppNotification(
        id: 'notif-${now.microsecondsSinceEpoch}',
        title: np.appointmentRescheduledTitle,
        body: np.appointmentRescheduledBody(updated.date),
        titleEn: en.appointmentRescheduledTitle,
        bodyEn: en.appointmentRescheduledBody(updated.date),
        time: now,
        kind: 'appointment',
        refId: id,
      ),
      ...notifications,
    ];
    _persistAppointments();
    _persistNotifications();
    notifyListeners();
    return true;
  }

  bool restoreAppointment(String id) {
    final index = appointments.indexWhere(
      (appointment) => appointment.id == id,
    );
    if (index == -1) return false;
    final current = appointments[index];
    if (current.status != AppointmentStatus.cancelled) return false;
    if (dateOnly(current.date).isBefore(dateOnly(DateTime.now()))) return false;
    if (hasBookingOn(
      appointments: appointments,
      doctorId: current.doctorId,
      date: current.date,
      excludingAppointmentId: id,
    )) {
      return false;
    }
    appointments = List.of(appointments)
      ..[index] = current.copyWith(status: AppointmentStatus.booked);
    _persistAppointments();
    notifyListeners();
    return true;
  }

  /// Persists "completed" for booked appointments whose day has passed.
  /// Called on restore and from the shell's minute ticker — never in a getter.
  void normalizeCompleted() {
    final today = dateOnly(DateTime.now());
    var changed = false;
    final next = appointments.map((appointment) {
      if (appointment.status == AppointmentStatus.booked &&
          dateOnly(appointment.date).isBefore(today)) {
        changed = true;
        return appointment.copyWith(status: AppointmentStatus.completed);
      }
      return appointment;
    }).toList();
    if (!changed) return;
    appointments = next;
    _persistAppointments();
    notifyListeners();
  }

  /// Keeps the seeded demo "upcoming" appointment in the future so the demo
  /// does not silently drift into the past. Never touches user-created records.
  void _reanchorDemoUpcoming() {
    final index = appointments.indexWhere(
      (appointment) => appointment.id == 'demo-upcoming',
    );
    if (index == -1) return;
    final demo = appointments[index];
    if (demo.status != AppointmentStatus.booked) return;
    final today = dateOnly(DateTime.now());
    if (!dateOnly(demo.date).isBefore(today)) return;

    final newDate = nextSaturdayForGroup(SaturdayGroup.second);
    appointments = List.of(appointments)
      ..[index] = demo.copyWith(date: newDate);

    final nIndex = notifications.indexWhere(
      (notification) => notification.id == 'notif-appointment',
    );
    if (nIndex != -1) {
      final old = notifications[nIndex];
      final np = const L10n(AppLanguage.np);
      final en = const L10n(AppLanguage.en);
      final sunita = doctorById('sunita');
      notifications = List.of(notifications)
        ..[nIndex] = AppNotification(
          id: old.id,
          title: old.title,
          body: np.appointmentReminderBody(
            newDate,
            sunita?.name(AppLanguage.np) ?? '',
          ),
          titleEn: old.titleEn,
          bodyEn: en.appointmentReminderBody(
            newDate,
            sunita?.name(AppLanguage.en) ?? '',
          ),
          time: DateTime.now().subtract(const Duration(hours: 2)),
          kind: old.kind,
          read: old.read,
          refId: 'demo-upcoming',
        );
      _persistNotifications();
    }
    _persistAppointments();
  }

  void markNotificationRead(String id) {
    final index = notifications.indexWhere(
      (notification) => notification.id == id,
    );
    if (index == -1 || notifications[index].read) return;
    notifications = List.of(notifications)
      ..[index] = notifications[index].copyWith(read: true);
    _persistNotifications();
    notifyListeners();
  }

  void markAllNotificationsRead() {
    if (unreadCount == 0) return;
    notifications = notifications
        .map((notification) => notification.copyWith(read: true))
        .toList();
    _persistNotifications();
    notifyListeners();
  }

  void updateProfile(PatientProfile updated) {
    profile = updated;
    _persistProfile();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (themeMode == mode) return;
    themeMode = mode;
    _prefs.setString(_kThemeMode, mode.name);
    notifyListeners();
  }

  void setDatePrimary(DatePrimary value) {
    if (datePrimary == value) return;
    datePrimary = value;
    _prefs.setString(_kDatePrimary, value.name);
    notifyListeners();
  }

  void setLanguage(AppLanguage value) {
    if (language == value) return;
    language = value;
    _prefs.setString(_kLanguage, value.name);
    notifyListeners();
  }

  void setPalette(AppPalette value) {
    if (palette == value) return;
    palette = value;
    _prefs.setString(_kPalette, value.id);
    notifyListeners();
  }

  void setNepaliHeadingFont(NepaliFont value) {
    if (nepaliHeadingFont == value) return;
    nepaliHeadingFont = value;
    _prefs.setString(_kNepaliHeadingFont, value.name);
    notifyListeners();
  }

  void setNepaliBodyFont(NepaliFont value) {
    if (nepaliBodyFont == value) return;
    nepaliBodyFont = value;
    _prefs.setString(_kNepaliBodyFont, value.name);
    notifyListeners();
  }

  void setEnglishFont(EnglishFont value) {
    if (englishFont == value) return;
    englishFont = value;
    _prefs.setString(_kEnglishFont, value.name);
    notifyListeners();
  }

  void completeOnboarding() {
    if (onboarded) return;
    onboarded = true;
    _prefs.setBool(_kOnboarded, true);
    notifyListeners();
  }

  // Demo-only auth: any credentials are accepted; real auth arrives later.
  void signIn() {
    if (signedIn) return;
    signedIn = true;
    _prefs.setBool(_kSignedIn, true);
    notifyListeners();
  }

  void signOut() {
    if (!signedIn) return;
    signedIn = false;
    _prefs.setBool(_kSignedIn, false);
    notifyListeners();
  }

  // Bottom-bar tab order (0 home, 1 appointments, 2 records, 3 profile,
  // 4 calendar). Defaults to calendar second; reorderable from settings.
  static const _defaultTabOrder = [0, 4, 1, 2, 3];

  List<int> _restoreTabOrder() {
    final raw = _prefs.getString(_kTabOrder);
    if (raw == null) return List.of(_defaultTabOrder);
    try {
      final order = (jsonDecode(raw) as List).map((e) => e as int).toList();
      final valid = order.length == 5 &&
          {...order}.length == 5 &&
          order.every(_defaultTabOrder.contains);
      return valid ? order : List.of(_defaultTabOrder);
    } catch (_) {
      return List.of(_defaultTabOrder);
    }
  }

  void setTabOrder(List<int> order) {
    tabOrder = List.of(order);
    _prefs.setString(_kTabOrder, jsonEncode(order));
    notifyListeners();
  }

  void resetTabOrder() => setTabOrder(_defaultTabOrder);

  void _persistProfile() {
    _prefs.setString(_kProfile, jsonEncode(profile.toJson()));
  }

  void _persistAppointments() {
    _prefs.setString(
      _kAppointments,
      jsonEncode(
        appointments.map((appointment) => appointment.toJson()).toList(),
      ),
    );
  }

  void _persistNotifications() {
    _prefs.setString(
      _kNotifications,
      jsonEncode(
        notifications.map((notification) => notification.toJson()).toList(),
      ),
    );
  }
}
