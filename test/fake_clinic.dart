import 'package:battar_sanjibani/data/backend.dart';
import 'package:battar_sanjibani/models.dart';

/// In-memory [ClinicData] so the state machine in AppState can be exercised
/// without a PocketBase instance, an emulator or a network.
class FakeClinic implements ClinicData {
  FakeClinic({this.signedInValue = true, this.served = true});

  final List<Appointment> stored = [];
  final List<AppNotification> feed = [];
  final List<String> readEvents = [];
  final List<String> readNotices = [];
  PatientProfile storedProfile = const PatientProfile(
    name: 'सीता श्रेष्ठ',
    phone: '9841234567',
    age: '32',
    gender: 'महिला',
    bloodGroup: 'O+',
    address: 'विदुर-२, बट्टार, नुवाकोट',
    patientId: 'BSP-0001',
  );

  bool signedInValue;

  /// Whether the catalog read succeeds; false simulates an unreachable server.
  bool served;

  int bookCalls = 0;
  int cancelCalls = 0;
  int moveCalls = 0;

  /// Set to make the next write behave like a server rejection.
  BookingFailure? failNext;

  /// Set to make the next cancel/reschedule fail on the way to the server.
  bool writeFails = false;

  @override
  bool get signedIn => signedInValue;

  @override
  String get patientRecordId => 'patient-1';

  @override
  Future<bool> restoreSession() async => signedInValue;

  @override
  Future<void> signIn(String identifier, String password) async {
    signedInValue = true;
  }

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
  }) async {}

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {
    signedInValue = false;
  }

  @override
  PatientProfile profile() => storedProfile;

  @override
  Future<bool> saveProfile(PatientProfile profile) async {
    if (writeFails) return false;
    storedProfile = profile;
    return true;
  }

  @override
  Future<bool> syncCatalog() async => served;

  @override
  Future<List<Appointment>> myAppointments() async => List.of(stored);

  @override
  Future<List<AppNotification>> notificationsFeed() async => List.of(feed);

  @override
  Future<BookingResult> book({
    required Department department,
    required Doctor? doctor,
    required DateTime date,
    required String patientName,
    required String phone,
  }) async {
    bookCalls++;
    final failure = failNext;
    if (failure != null) {
      failNext = null;
      return BookingResult.failure(failure);
    }
    final appointment = Appointment(
      id: 'apt-${stored.length + 1}',
      departmentId: department.id,
      departmentName: department.displayName,
      doctorId: doctor?.id,
      doctorName: doctor?.displayName ?? '',
      date: DateTime(date.year, date.month, date.day),
      slot: doctor?.startTime ?? '09:00',
      patientName: patientName.trim(),
      phone: phone.trim(),
      // The server sets this from the doctor's row, never from the client.
      fee: doctor?.fee ?? 0,
      status: AppointmentStatus.booked,
      createdAt: DateTime.now(),
    );
    stored.add(appointment);
    feed.insert(
      0,
      AppNotification(
        id: 'notif-${stored.length}',
        title: 'title',
        body: 'body',
        time: DateTime.now(),
        kind: 'appointment',
        refId: appointment.id,
      ),
    );
    return BookingResult.success(appointment);
  }

  @override
  Future<bool> cancel(String id) async {
    cancelCalls++;
    if (writeFails) return false;
    _setStatus(id, AppointmentStatus.cancelled);
    return true;
  }

  @override
  Future<bool> reopen(String id) async {
    if (writeFails) return false;
    _setStatus(id, AppointmentStatus.booked);
    return true;
  }

  @override
  Future<bool> moveTo(String id, DateTime date) async {
    moveCalls++;
    if (writeFails) return false;
    final index = stored.indexWhere((item) => item.id == id);
    if (index == -1) return false;
    stored[index] = _copy(stored[index], date: DateTime(date.year, date.month, date.day));
    return true;
  }

  void _setStatus(String id, AppointmentStatus status) {
    final index = stored.indexWhere((item) => item.id == id);
    if (index == -1) return;
    stored[index] = _copy(stored[index], status: status);
  }

  static Appointment _copy(
    Appointment item, {
    AppointmentStatus? status,
    DateTime? date,
  }) {
    return Appointment(
      id: item.id,
      departmentId: item.departmentId,
      departmentName: item.departmentName,
      doctorId: item.doctorId,
      doctorName: item.doctorName,
      date: date ?? item.date,
      slot: item.slot,
      patientName: item.patientName,
      phone: item.phone,
      fee: item.fee,
      status: status ?? item.status,
      createdAt: item.createdAt,
    );
  }

  @override
  Future<void> markEventRead(String id) async => readEvents.add(id);

  @override
  Future<void> markNoticesRead() async => readNotices.add('all');

  @override
  Future<void> saveReadNoticeKeys(List<String> keys) async =>
      readNotices.addAll(keys);

  @override
  Future<void> listen(void Function() onChange) async {}

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> close() async {}
}
