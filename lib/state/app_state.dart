import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fonts.dart';
import '../core/l10n.dart';
import '../core/palette.dart';
import '../core/saturday_schedule.dart';
import '../core/slot_availability.dart';
import '../data/backend.dart';
import '../models.dart';

/// The single view the screens have of the clinic: what the patient booked,
/// what the server says is available, and the preferences this handset keeps.
///
/// Data comes from [Backend] — server first, local cache second. Only the
/// appearance settings live in SharedPreferences now; nothing about a patient
/// is invented or stored unencrypted on the phone.
class AppState extends ChangeNotifier {
  AppState._(this._prefs, this.data);

  final SharedPreferences _prefs;
  /// The clinic's server, or an in-memory stand-in while testing.
  final ClinicData data;

  static const _kOnboarded = 'onboarded_v1';
  static const _kThemeMode = 'theme_mode_v1';
  static const _kLanguage = 'language_v1';
  static const _kDatePrimary = 'date_primary_v1';
  static const _kPalette = 'palette_v1';
  static const _kNepaliHeadingFont = 'nepali_heading_font_v1';
  static const _kNepaliBodyFont = 'nepali_body_font_v1';
  static const _kEnglishFont = 'english_font_v1';
  static const _kTabOrder = 'tab_order_v1';

  /// Keys the demo builds used to hold invented patient records. Removed on
  /// first launch of this version so an upgrade cannot leave a fake history,
  /// or a fake signed-in state, behind.
  static const _retiredKeys = [
    'seeded_v1',
    'profile_v1',
    'appointments_v1',
    'notifications_v1',
    'signed_in_v1',
  ];

  static const _emptyProfile = PatientProfile(
    name: '',
    phone: '',
    age: '',
    gender: '',
    bloodGroup: '',
    address: '',
    patientId: '',
  );

  PatientProfile profile = _emptyProfile;
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

  /// Bottom-bar tab ids in display order (see RootShell for the id mapping).
  List<int> tabOrder = const [0, 4, 1, 2, 3];

  bool refreshing = false;

  /// The last read or write could not reach the clinic's server.
  bool offline = false;

  bool get signedIn => data.signedIn;

  AppFonts get fonts => AppFonts(
    nepaliHeading: nepaliHeadingFont,
    nepaliBody: nepaliBodyFont,
    english: englishFont,
  );

  /// [data] lets a test drive the same state machine without a server.
  static Future<AppState> load({ClinicData? data}) async {
    final prefs = await SharedPreferences.getInstance();
    final state = AppState._(prefs, data ?? await Backend.open());
    state._restoreSettings();
    await state._dropRetiredKeys();

    // Whatever the phone already has renders before the network answers, so a
    // slow link is not a blank screen.
    await state._hydrate();
    return state;
  }

  void _restoreSettings() {
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
    tabOrder = _restoreTabOrder();
    if (!onboarded && themeMode == ThemeMode.system) {
      themeMode = ThemeMode.light;
      _prefs.setString(_kThemeMode, 'light');
    }
  }

  Future<void> _dropRetiredKeys() async {
    for (final key in _retiredKeys) {
      await _prefs.remove(key);
    }
  }

  Future<void> _hydrate() async {
    if (await data.restoreSession()) {
      profile = data.profile();
      appointments = await data.myAppointments();
      notifications = await data.notificationsFeed();
      await data.listen(_onRealtimeChange);
    }
    offline = !(await data.syncCatalog());
    normalizeCompleted();
    notifyListeners();
  }

  /// Pulls everything this patient and this clinic can see. Runs on open, on
  /// pull-to-refresh, and whenever the realtime stream reports a change.
  Future<void> refresh() async {
    if (refreshing) return;
    refreshing = true;
    notifyListeners();
    try {
      offline = !(await data.syncCatalog());
      if (data.signedIn) {
        profile = data.profile();
        appointments = await data.myAppointments();
        notifications = await data.notificationsFeed();
      } else {
        appointments = const [];
        notifications = const [];
      }
      normalizeCompleted();
    } finally {
      refreshing = false;
      notifyListeners();
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

  /// Books a specialist visit for a date. The server decides whether that date
  /// is bookable and what it costs, so a failure always carries a reason the
  /// screen can phrase in the patient's language.
  Future<BookingResult> bookAppointment({
    required Department department,
    required Doctor? doctor,
    required DateTime date,
    required String patientName,
    required String phone,
  }) async {
    // A local pre-check avoids a round trip for an obvious clash, but it is
    // only a courtesy: the server holds the whole register, not this handset.
    if (doctor != null &&
        hasBookingOn(
          appointments: appointments,
          doctorId: doctor.id,
          date: date,
        )) {
      return const BookingResult.failure(BookingFailure.alreadyBooked);
    }

    final result = await data.book(
      department: department,
      doctor: doctor,
      date: date,
      patientName: patientName,
      phone: phone,
    );

    if (result.ok) {
      appointments = [...appointments, result.appointment!];
      notifications = await data.notificationsFeed();
      offline = false;
    } else {
      offline = result.failure == BookingFailure.offline;
    }
    notifyListeners();
    return result;
  }

  Future<bool> cancelAppointment(String id) async {
    if (!await data.cancel(id)) {
      offline = true;
      return false;
    }
    _replace(
      id,
      (appointment) => appointment.copyWith(
        status: AppointmentStatus.cancelled,
      ),
    );
    notifications = await data.notificationsFeed();
    notifyListeners();
    return true;
  }

  Future<bool> rescheduleAppointment(String id, {required DateTime date}) async {
    if (!await data.moveTo(id, date)) {
      offline = true;
      return false;
    }
    _replace(id, (appointment) => appointment.copyWith(date: dateOnly(date)));
    notifications = await data.notificationsFeed();
    notifyListeners();
    return true;
  }

  Future<bool> restoreAppointment(String id) async {
    final index = appointments.indexWhere((appointment) => appointment.id == id);
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
    if (!await data.reopen(id)) {
      offline = true;
      return false;
    }
    _replace(
      id,
      (appointment) => appointment.copyWith(status: AppointmentStatus.booked),
    );
    notifyListeners();
    return true;
  }

  void _replace(String id, Appointment Function(Appointment) update) {
    final index = appointments.indexWhere((item) => item.id == id);
    if (index == -1) return;
    appointments = List.of(appointments)..[index] = update(appointments[index]);
  }

  /// A past booking reads as history rather than as something still owed. The
  /// server's nightly job is the authority; this only keeps the display honest
  /// when the day turns over while the app is open.
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
    if (changed) appointments = next;
  }

  Future<void> markNotificationRead(String id) async {
    final index = notifications.indexWhere(
      (notification) => notification.id == id,
    );
    if (index == -1 || notifications[index].read) return;
    final wasNotice = notifications[index].kind == 'notice';
    notifications = List.of(notifications)
      ..[index] = notifications[index].copyWith(read: true);
    notifyListeners();

    if (wasNotice) {
      await data.saveReadNoticeKeys(
        notifications
            .where((item) => item.kind == 'notice' && item.read)
            .map((item) => item.refId ?? '')
            .where((key) => key.isNotEmpty)
            .toList(),
      );
    } else {
      await data.markEventRead(id);
    }
  }

  Future<void> markAllNotificationsRead() async {
    if (unreadCount == 0) return;
    notifications = notifications
        .map((notification) => notification.copyWith(read: true))
        .toList();
    notifyListeners();
    await data.markNoticesRead();
    for (final notification in notifications.where(
      (item) => item.kind != 'notice',
    )) {
      await data.markEventRead(notification.id);
    }
  }

  Future<void> updateProfile(PatientProfile updated) async {
    profile = updated;
    notifyListeners();
    if (await data.saveProfile(updated)) {
      profile = data.profile();
      notifyListeners();
    } else {
      offline = true;
    }
  }

  // ------------------------------------------------------------------- auth

  Future<void> signIn(String identifier, String password) async {
    await data.signIn(identifier, password);
    profile = data.profile();
    await refresh();
    await data.listen(_onRealtimeChange);
  }

  Future<void> signUp({
    required String name,
    required String phone,
    required String password,
    String email = '',
    String gender = '',
    String bloodGroup = '',
    String address = '',
    String age = '',
  }) => data.signUp(
    name: name,
    phone: phone,
    password: password,
    email: email,
    gender: gender,
    bloodGroup: bloodGroup,
    address: address,
    age: age,
  );

  Future<void> requestPasswordReset(String email) =>
      data.requestPasswordReset(email);

  Future<void> signOut() async {
    await data.stopListening();
    await data.signOut();
    profile = _emptyProfile;
    appointments = const [];
    notifications = const [];
    notifyListeners();
  }

  Future<void> _onRealtimeChange() => refresh();

  // -------------------------------------------------------------- preference

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

  // -------------------------------------------------------------- tab order

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
    } catch (error) {
      debugPrint('AppState: unreadable tab order ($error); using defaults.');
      return List.of(_defaultTabOrder);
    }
  }

  void setTabOrder(List<int> order) {
    tabOrder = List.of(order);
    _prefs.setString(_kTabOrder, jsonEncode(order));
    notifyListeners();
  }

  void resetTabOrder() => setTabOrder(_defaultTabOrder);
}
