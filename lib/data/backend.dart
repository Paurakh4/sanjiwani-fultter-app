import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';

import '../core/api_config.dart';
import '../core/icons.dart';
import '../core/l10n.dart';
import '../core/saturday_schedule.dart';
import '../models.dart';
import 'cache_db.dart';
import 'catalog.dart';

/// Why the server refused to book a visit. The codes come back from
/// `backend/pb_hooks/appointments.pb.js` as `code|English text`.
enum BookingFailure {
  offline,
  notScheduled,
  alreadyBooked,
  full,
  past,
  cutoff,
  signedOut,
  unknown,
}

class BookingResult {
  const BookingResult.success(this.appointment)
    : failure = null,
      serverMessage = '';

  const BookingResult.failure(this.failure, [this.serverMessage = ''])
    : appointment = null;

  final Appointment? appointment;
  final BookingFailure? failure;
  final String serverMessage;

  bool get ok => appointment != null;
}

/// What the app can ask for: the clinic's catalog, this patient's bookings and
/// the writes that change them. [Backend] is the only real implementation;
/// tests substitute an in-memory one so the booking rules in [AppState] stay
/// covered without a server.
abstract class ClinicData {
  bool get signedIn;
  String get patientRecordId;

  Future<bool> restoreSession();
  Future<void> signIn(String identifier, String password);
  Future<void> signUp({
    required String name,
    required String phone,
    required String password,
    String email,
    String gender,
    String bloodGroup,
    String address,
    String age,
  });
  Future<void> requestPasswordReset(String email);
  Future<void> signOut();

  PatientProfile profile();
  Future<bool> saveProfile(PatientProfile profile);

  /// True when the catalog now in [Catalog] came from the server or its cache.
  Future<bool> syncCatalog();
  Future<List<Appointment>> myAppointments();
  Future<List<AppNotification>> notificationsFeed();

  Future<BookingResult> book({
    required Department department,
    required Doctor? doctor,
    required DateTime date,
    required String patientName,
    required String phone,
  });
  Future<bool> cancel(String id);
  Future<bool> reopen(String id);
  Future<bool> moveTo(String id, DateTime date);

  Future<void> markEventRead(String id);
  Future<void> markNoticesRead();
  Future<void> saveReadNoticeKeys(List<String> keys);

  Future<void> listen(void Function() onChange);
  Future<void> stopListening();
  Future<void> close();
}

/// Everything the app knows how to ask the clinic's server for.
///
/// Reads are cache-first: the catalog and the patient's own bookings are
/// mirrored locally so a screen renders immediately and still works with no
/// signal in Bidur. Writes go to the server and fail loudly — a booking that
/// cannot be confirmed is never presented as if it were.
class Backend implements ClinicData {
  Backend._(this._pb, this._cache);

  static const _authKey = 'pocketbase_auth';

  final PocketBase _pb;
  final CacheDb _cache;

  static Future<Backend> open() async {
    final storage = const FlutterSecureStorage();
    final cache = await CacheDb.open();
    final initial = await storage.read(key: _authKey) ?? '';

    final pb = PocketBase(
      ApiConfig.baseUrl,
      authStore: AsyncAuthStore(
        save: (data) => storage.write(key: _authKey, value: data),
        clear: () => storage.delete(key: _authKey),
        initial: initial,
      ),
    );

    return Backend._(pb, cache);
  }

  // ---------------------------------------------------------------- session

  @override
  bool get signedIn => _pb.authStore.isValid && _pb.authStore.record != null;

  @override
  String get patientRecordId => _pb.authStore.record?.id ?? '';

  Map<String, dynamic>? get _patientRaw => _pb.authStore.record?.data;

  /// Revalidates a stored session against the server. Returns false when the
  /// token no longer works, which the SDK has then already cleared.
  @override
  Future<bool> restoreSession() async {
    if (!_pb.authStore.isValid) return false;
    try {
      await _pb.collection('patients').authRefresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> signIn(String identifier, String password) =>
      _pb.collection('patients').authWithPassword(identifier, password);

  @override
  Future<void> signUp({
    required String name,
    required String phone,
    required String password,
    String email = '',
    String gender = '',
    String bloodGroup = '',
    String address = '',
    String age = '',
  }) async {
    await _pb.collection('patients').create(
      body: {
      'username': phone,
      'name': name,
      'password': password,
      'passwordConfirm': password,
      if (email.isNotEmpty) 'email': email,
      if (gender.isNotEmpty) 'gender': gender,
      'bloodGroup': bloodGroup,
      'address': address,
      'age': age,
    });
    // Registration is not a login: the patient still has to sign in, which
    // keeps the two paths honest and tests the same flow every other time.
  }

  @override
  Future<void> requestPasswordReset(String email) =>
      _pb.collection('patients').requestPasswordReset(email);

  @override
  Future<void> signOut() async {
    _pb.authStore.clear();
    await _cache.clear();
    Catalog.reset();
  }

  @override
  PatientProfile profile() {
    final raw = _patientRaw ?? const {};
    String text(String key) => (raw[key] as String?) ?? '';
    return PatientProfile(
      name: text('name'),
      phone: text('username'),
      age: text('age'),
      gender: _genderFromStored(text('gender')),
      bloodGroup: text('bloodGroup'),
      address: text('address'),
      // Issued by the server; never invented here.
      patientId: text('patientId'),
    );
  }

  /// False means the profile edit did not reach the server; the caller keeps
  /// what was typed on screen and says so.
  @override
  Future<bool> saveProfile(PatientProfile profile) async {
    try {
      await _pb.collection('patients').update(patientRecordId, body: {
        'name': profile.name,
        'username': profile.phone,
        'age': profile.age,
        'gender': _genderToStored(profile.gender),
        'bloodGroup': profile.bloodGroup,
        'address': profile.address,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static const _genderCodes = {
    'female': 'महिला',
    'male': 'पुरुष',
    'other': 'अन्य',
  };

  static String _genderFromStored(String value) =>
      _genderCodes[value] ?? (value.isEmpty ? 'महिला' : value);

  static String _genderToStored(String value) =>
      _genderCodes.entries
          .firstWhere(
            (entry) => entry.value == value || entry.key == value,
            orElse: () => const MapEntry('female', 'महिला'),
          )
          .key;

  // -------------------------------------------------------------- catalog

  /// Server first, cache second, shipped defaults third. The last of those is
  /// only reachable on a brand-new install with no signal, and it is the same
  /// data the server was seeded from, so it cannot contradict the clinic.
  @override
  Future<bool> syncCatalog() async {
    try {
      final departments = await _pb
          .collection('departments')
          .getFullList(sort: 'sortOrder');
      final doctors = await _pb.collection('doctors').getFullList(sort: 'nameEn');
      final notices = await _pb
          .collection('notices')
          .getFullList(sort: '-created');
      final config = await _pb
          .collection('clinic_config')
          .getFirstListItem('singleton="clinic"');

      final doctorRows = doctors.map((r) => r.data).toList();
      Catalog.apply(
        departments: departments.map((r) => departmentFrom(r.data)).toList(),
        doctors: doctors.map((r) => doctorFrom(r.data)).toList(),
        notices: notices.map((r) => noticeFrom(r.data)).toList(),
        specialistOrder: _specialistOrder(
          departments.map((r) => r.data).toList(),
          _specialistDepartmentCodes(doctorRows),
        ),
        saturdayOverrides: _overrides(config.data['saturdayOverrides']),
      );

      await _cache.replace('departments', _maps(departments));
      await _cache.replace('doctors', _maps(doctors));
      await _cache.replace('notices', _maps(notices));
      await _cache.replace('clinic_config', [config.data]);
      return true;
    } catch (_) {
      return _catalogFromCache();
    }
  }

  Future<bool> _catalogFromCache() async {
    final departments = await _cache.rows('departments');
    final doctors = await _cache.rows('doctors');
    if (departments.isEmpty && doctors.isEmpty) return false;

    final doctorRows = await _cache.rows('doctors');
    Catalog.apply(
      departments: departments.map(departmentFrom).toList(),
      doctors: doctors.map(doctorFrom).toList(),
      notices: (await _cache.rows('notices')).map(noticeFrom).toList(),
      specialistOrder: _specialistOrder(
        departments,
        _specialistDepartmentCodes(doctorRows),
      ),
      saturdayOverrides: _overrides(
        (await _cache.rows('clinic_config')).isEmpty
            ? null
            : (await _cache.rows('clinic_config')).first['saturdayOverrides'],
      ),
    );
    return true;
  }

  static List<Map<String, dynamic>> _maps(List<RecordModel> records) =>
      records.map((record) => record.data).toList();

  /// The bookable specialist departments, in the order the clinic sets.
  ///
  /// Membership comes from having a doctor with a Saturday group, not from
  /// `specialistOrder` being present: PocketBase returns 0 for an unset number
  /// field, so treating 0 as "set" would list every walk-in department as a
  /// specialist one. The field only decides the order.
  static List<String> _specialistOrder(
    List<Map<String, dynamic>> departments,
    Set<String> specialistDepartmentCodes,
  ) {
    final ranked = departments
        .where((row) => specialistDepartmentCodes.contains(row['code']))
        .toList()
      ..sort((a, b) {
        final byOrder = ((a['specialistOrder'] as num?) ?? 0)
            .compareTo((b['specialistOrder'] as num?) ?? 0);
        return byOrder != 0
            ? byOrder
            : '${a['code']}'.compareTo('${b['code']}');
      });
    return ranked.map((row) => row['code'] as String).toList();
  }

  /// Department codes that have at least one Saturday specialist attached.
  static Set<String> _specialistDepartmentCodes(
    List<Map<String, dynamic>> doctors,
  ) =>
      {
        for (final doctor in doctors)
          if ('${doctor['saturdayGroup']}'.isNotEmpty)
            '${doctor['departmentCode']}',
      };

  static Map<String, Set<String>> _overrides(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) => MapEntry(
        key as String,
        (value as List?)?.cast<String>().toSet() ?? const <String>{},
      ),
    );
  }

  // ------------------------------------------------------------ bookings

  @override
  Future<List<Appointment>> myAppointments() async {
    if (!signedIn) return const [];
    try {
      // No filter needed: the collection's list rule only ever returns the
      // signed-in patient's own rows.
      final records = await _pb
          .collection('appointments')
          .getFullList(sort: '-date');
      await _cache.replace('appointments', _maps(records));
      return records.map((r) => appointmentFrom(r.data)).toList();
    } catch (_) {
      final cached = await _cache.rows('appointments');
      return cached.map(appointmentFrom).toList();
    }
  }

  @override
  Future<BookingResult> book({
    required Department department,
    required Doctor? doctor,
    required DateTime date,
    required String patientName,
    required String phone,
  }) async {
    if (!await _reachable) {
      return const BookingResult.failure(BookingFailure.offline);
    }
    try {
      final created = await _pb.collection('appointments').create(
        body: {
        'patient': patientRecordId,
        'patientName': patientName.trim(),
        'phone': phone.trim(),
        'departmentCode': department.id,
        'doctorCode': doctor?.id ?? '',
        'date': saturdayDateKey(date),
        'status': 'booked',
      });
      final appointment = appointmentFrom(created.data);
      await _cache.updateOne('appointments', created.data);
      return BookingResult.success(appointment);
    } on ClientException catch (error) {
      return BookingResult.failure(_failureFor(error), _reason(error));
    } catch (_) {
      return const BookingResult.failure(BookingFailure.unknown);
    }
  }

  @override
  Future<bool> cancel(String id) => _patch(id, {'status': 'cancelled'});

  @override
  Future<bool> reopen(String id) => _patch(id, {'status': 'booked'});

  @override
  Future<bool> moveTo(String id, DateTime date) =>
      _patch(id, {'date': saturdayDateKey(date)});

  Future<bool> _patch(String id, Map<String, dynamic> changes) async {
    if (!await _reachable) return false;
    try {
      final updated = await _pb.collection('appointments').update(id, body: changes);
      await _cache.updateOne('appointments', updated.data);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _reason(ClientException error) =>
      '${error.response['message'] ?? ''}';

  static BookingFailure _failureFor(ClientException error) {
    final code = _reason(error).split('|').first.toLowerCase();
    return switch (code) {
      'booking_not_scheduled' => BookingFailure.notScheduled,
      'already_booked' => BookingFailure.alreadyBooked,
      'booking_full' => BookingFailure.full,
      'booking_date_past' => BookingFailure.past,
      'booking_cutoff' => BookingFailure.cutoff,
      _ => error.statusCode == 400 && _reason(error).contains('unique')
          ? BookingFailure.alreadyBooked
          : BookingFailure.unknown,
    };
  }

  // --------------------------------------------------------- notifications

  /// The feed is appointment events the server wrote for this patient, merged
  /// with the clinic's published notices. Notices are shared, so their read
  /// state lives as a list of ids on the patient rather than one row each.
  @override
  Future<List<AppNotification>> notificationsFeed() async {
    if (!signedIn) return const [];

    final events = <AppNotification>[];
    try {
      final records = await _pb
          .collection('notifications')
          .getFullList(sort: '-created');
      await _cache.replace('notifications', _maps(records));
      events.addAll(records.map((r) => _eventFrom(r.data)));
    } catch (_) {
      for (final row in await _cache.rows('notifications')) {
        events.add(_eventFrom(row));
      }
    }

    final readKeys = _readNoticeKeys();
    final notices = <AppNotification>[
      for (final notice in Catalog.notices)
        AppNotification(
          id: 'notice:${notice.id}',
          title: L10n(AppLanguage.np).newNoticeTitle,
          body: notice.title,
          titleEn: L10n(AppLanguage.en).newNoticeTitle,
          bodyEn: notice.title,
          time: notice.createdAt,
          kind: 'notice',
          read: readKeys.contains(notice.id),
          refId: notice.id,
        ),
    ];

    final merged = [...events, ...notices]
      ..sort((a, b) => b.time.compareTo(a.time));
    return merged;
  }

  AppNotification _eventFrom(Map<String, dynamic> row) {
    final meta = (row['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    final date = DateTime.tryParse('${meta['date']}') ?? DateTime.now();
    final code = (row['event'] as String?) ?? 'confirmed';
    final department = departmentByIdOrNull(meta['departmentCode'] as String?);
    final np = L10n(AppLanguage.np);
    final en = L10n(AppLanguage.en);

    final (title, titleEn, body, bodyEn) = switch (code) {
      'rescheduled' => (
        np.appointmentRescheduledTitle,
        en.appointmentRescheduledTitle,
        np.appointmentRescheduledBody(date),
        en.appointmentRescheduledBody(date),
      ),
      'cancelled' => (
        np.appointmentCancelledTitle,
        en.appointmentCancelledTitle,
        np.appointmentCancelledBody(date, department?.nameNp ?? ''),
        en.appointmentCancelledBody(date, department?.nameEn ?? ''),
      ),
      'completed' => (
        np.visitCompletedTitle,
        en.visitCompletedTitle,
        np.visitCompletedBody(date, department?.nameNp ?? ''),
        en.visitCompletedBody(date, department?.nameEn ?? ''),
      ),
      _ => (
        np.appointmentConfirmedTitle,
        en.appointmentConfirmedTitle,
        np.appointmentConfirmedBody(date, department?.nameNp ?? ''),
        en.appointmentConfirmedBody(date, department?.nameEn ?? ''),
      ),
    };

    return AppNotification(
      id: row['id'] as String? ?? '',
      title: title,
      body: body,
      titleEn: titleEn,
      bodyEn: bodyEn,
      time: DateTime.tryParse('${row['created']}') ?? DateTime.now(),
      kind: 'appointment',
      read: row['read'] as bool? ?? false,
      refId: row['refId'] as String?,
    );
  }

  @override
  Future<void> markEventRead(String id) async {
    try {
      await _pb.collection('notifications').update(id, body: {'read': true});
    } catch (_) {
      // A read marker that cannot be saved only means the dot stays; it is not
      // worth interrupting someone who is opening a notification.
    }
  }

  @override
  Future<void> markNoticesRead() async {
    final keys = Catalog.notices.map((notice) => notice.id).toList();
    await saveReadNoticeKeys(keys);
  }

  List<String> _readNoticeKeys() {
    final raw = _patientRaw?['readNoticeKeys'];
    return raw is List ? raw.cast<String>() : const [];
  }

  @override
  Future<void> saveReadNoticeKeys(List<String> keys) async {
    try {
      final updated = await _pb
          .collection('patients')
          .update(patientRecordId, body: {'readNoticeKeys': keys});
      await _cache.updateOne('patient_self', updated.data);
    } catch (_) {
      // See markEventRead.
    }
  }

  // -------------------------------------------------------------- realtime

  /// Calls [onChange] whenever the server changes anything this patient cares
  /// about. The SDK reconnects on its own and fires `PB_CONNECT`, which is also
  /// reported here so a stale cache gets refetched after a dropout.
  @override
  Future<void> listen(void Function() onChange) async {
    if (!signedIn) return;
    for (final collection in ['appointments', 'notifications', 'notices']) {
      try {
        await _pb.collection(collection).subscribe('*', (_) => onChange());
      } catch (_) {
        // A subscription that failed to start is retried on the next login;
        // polling the lists still keeps the app correct.
      }
    }
    try {
      await _pb.realtime.subscribe('PB_CONNECT', (_) => onChange());
    } catch (_) {
      // Same.
    }
  }

  @override
  Future<void> stopListening() => _pb.realtime.unsubscribe();

  /// True when a network interface is up. Not a promise that the clinic's
  /// server answers — that is what the write path's own error handling is for.
  Future<bool> get _reachable async {
    final status = await Connectivity().checkConnectivity();
    return status.isNotEmpty && !status.contains(ConnectivityResult.none);
  }

  @override
  Future<void> close() async {
    await _pb.realtime.unsubscribe();
    await _cache.close();
  }
}

// ------------------------------------------------------------------ mapping

/// A blank server value means "not set", not "empty text".
String? _text(Object? raw) => (raw as String?)?.isEmpty ?? true ? null : raw as String;


/// A `date` field comes back as a UTC timestamp. Reading only the date part
/// keeps the clinic's day the clinic's day, whatever timezone the handset is in.
DateTime _clinicDate(Object? raw) {
  final text = raw?.toString() ?? '';
  if (text.length < 10) return DateTime.now();
  final parts = text.substring(0, 10).split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

Department departmentFrom(Map<String, dynamic> row) => Department(
  id: row['code'] as String,
  nameNp: row['nameNp'] as String? ?? '',
  nameEn: row['nameEn'] as String? ?? '',
  descriptionNp: row['descNp'] as String? ?? '',
  descriptionEn: row['descEn'] as String? ?? '',
  icon: departmentIcon(row['icon'] as String?),
);

Doctor doctorFrom(Map<String, dynamic> row) => Doctor(
  id: row['code'] as String,
  nameNp: row['nameNp'] as String? ?? '',
  nameEn: row['nameEn'] as String? ?? '',
  specialtyNp: row['specialtyNp'] as String? ?? '',
  specialtyEn: row['specialtyEn'] as String? ?? '',
  qualification: row['qualification'] as String? ?? '',
  departmentId: row['departmentCode'] as String? ?? '',
  availabilityNp: row['availabilityNp'] as String? ?? '',
  availabilityEn: row['availabilityEn'] as String? ?? '',
  bioNp: row['bioNp'] as String? ?? '',
  bioEn: row['bioEn'] as String? ?? '',
  fee: (row['fee'] as num?)?.toInt() ?? 0,
  avatar: row['avatar'] as String? ?? '',
  weekdays: ((row['weekdays'] as List?) ?? const []).cast<num>().map(
    (value) => value.toInt(),
  ).toSet(),
  shifts: ((row['shifts'] as List?) ?? const []).cast<String>().map(
    SlotShift.values.byName,
  ).toSet(),
  startTime: _text(row['startTime']),
  endTime: _text(row['endTime']),
  saturdayGroup: _saturdayGroup(row['saturdayGroup']),
  visiting: row['visiting'] as bool? ?? false,
);

Notice noticeFrom(Map<String, dynamic> row) => Notice(
  id: row['id'] as String,
  tag: row['tag'] as String? ?? '',
  title: row['title'] as String? ?? '',
  body: row['body'] as String? ?? '',
  dateLabel: row['dateLabel'] as String? ?? '',
  createdAt: DateTime.tryParse('${row['created']}') ?? DateTime.now(),
  doctorId: _text(row['doctorCode']),
);

/// A blank or unknown rotation value means the doctor is not a Saturday
/// specialist, which is the same thing the shipped catalog expresses with null.
SaturdayGroup? _saturdayGroup(Object? raw) => switch (raw) {
  'first' => SaturdayGroup.first,
  'second' => SaturdayGroup.second,
  'third' => SaturdayGroup.third,
  'last' => SaturdayGroup.last,
  _ => null,
};

Appointment appointmentFrom(Map<String, dynamic> row) {
  final status = (row['status'] as String?) ?? 'booked';
  return Appointment(
    id: row['id'] as String,
    departmentId: row['departmentCode'] as String? ?? '',
    departmentName: row['departmentName'] as String? ?? '',
    doctorId: _text(row['doctorCode']),
    doctorName: row['doctorName'] as String? ?? '',
    date: _clinicDate(row['date']),
    slot: row['slot'] as String? ?? '',
    patientName: row['patientName'] as String? ?? '',
    phone: row['phone'] as String? ?? '',
    fee: (row['fee'] as num?)?.toInt() ?? 0,
    status: AppointmentStatus.values.firstWhere(
      (value) => value.name == status,
      orElse: () => AppointmentStatus.booked,
    ),
    createdAt: DateTime.tryParse('${row['created']}') ?? DateTime.now(),
  );
}

/// Icons are presentation, so the server stores the member's name and the app
/// decides how to draw it. Unknown names fall back rather than throw.
IconData departmentIcon(String? name) => switch (name) {
  'heartbeat' => CoolIcons.heartbeat,
  'genderFemale' => CoolIcons.genderFemale,
  'scan' => CoolIcons.scan,
  'tooth' => CoolIcons.tooth,
  'testTube' => CoolIcons.testTube,
  'ear' => CoolIcons.ear,
  'brain' => CoolIcons.brain,
  'sparkle' => CoolIcons.sparkle,
  'monitor' => CoolIcons.monitor,
  'waveform' => CoolIcons.waveform,
  'usersThree' => CoolIcons.usersThree,
  'personSimpleWalk' => CoolIcons.personSimpleWalk,
  'bone' => CoolIcons.bone,
  'siren' => CoolIcons.siren,
  'pill' => CoolIcons.pill,
  'bed' => CoolIcons.bed,
  _ => CoolIcons.stethoscope,
};
