import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fonts.dart';
import '../core/l10n.dart';
import '../core/palette.dart';
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
  static const _kPalette = 'palette_v1';
  static const _kNepaliHeadingFont = 'nepali_heading_font_v1';
  static const _kNepaliBodyFont = 'nepali_body_font_v1';
  static const _kEnglishFont = 'english_font_v1';

  late PatientProfile profile;
  List<Appointment> appointments = [];
  List<AppNotification> notifications = [];
  ThemeMode themeMode = ThemeMode.system;
  AppLanguage language = AppLanguage.np;
  AppPalette palette = AppPalette.green;
  NepaliFont nepaliHeadingFont = NepaliFont.anek;
  NepaliFont nepaliBodyFont = NepaliFont.mukta;
  EnglishFont englishFont = EnglishFont.poppins;
  bool onboarded = false;

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

    themeMode = switch (_prefs.getString(_kThemeMode)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    language = _prefs.getString(_kLanguage) == 'en'
        ? AppLanguage.en
        : AppLanguage.np;
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
    } catch (_) {
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
    } catch (_) {
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

  Appointment bookAppointment({
    required Department department,
    Doctor? doctor,
    required DateTime date,
    required String slot,
    required String patientName,
    required String phone,
  }) {
    final now = DateTime.now();
    final appointment = Appointment(
      id: 'apt-${now.microsecondsSinceEpoch}',
      departmentId: department.id,
      departmentName: department.displayName,
      doctorId: doctor?.id,
      doctorName: doctor?.displayName ?? 'Clinic service / क्लिनिक सेवा',
      date: DateTime(date.year, date.month, date.day),
      slot: slot,
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
