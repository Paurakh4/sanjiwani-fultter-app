import 'dart:convert';

import 'package:battar_sanjibani/core/clinic.dart';
import 'package:battar_sanjibani/core/fonts.dart';
import 'package:battar_sanjibani/core/l10n.dart';
import 'package:battar_sanjibani/core/nepali.dart';
import 'package:battar_sanjibani/core/saturday_schedule.dart';
import 'package:battar_sanjibani/data/backend.dart';
import 'package:battar_sanjibani/data/catalog.dart';

import 'package:battar_sanjibani/models.dart';
import 'package:battar_sanjibani/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_clinic.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A signed-in patient used to seed SharedPreferences in these tests; the app
/// no longer ships any invented patient data.
PatientProfile testProfile() => const PatientProfile(
  name: 'सीता श्रेष्ठ',
  phone: '9841234567',
  age: '32',
  gender: 'महिला',
  bloodGroup: 'O+',
  address: 'विदुर-२, बट्टार, नुवाकोट',
  patientId: 'BSP-0001',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('nepali helpers format digits, BS dates and initials', () {
    expect(nepDigits('9841'), '९८४१');
    expect(asciiDigits('९८४१'), '9841');
    expect(initials('डा. सुनिता तामाङ'), 'सु');
    expect(initials('Dr. Sunita Tamang'), 'S');
    expect(initials('सीता श्रेष्ठ'), 'सी');
    expect(slotLabel('09:00'), 'बिहान ९:००');
    expect(slotLabel('16:30'), 'दिउँसो ४:३०');
    expect(slotLabel('21:00'), 'राति ९:००');

    const np = L10n(AppLanguage.np);
    final date = DateTime(2026, 11, 14);
    expect(np.date(date), '२८ कात्तिक २०८३');
    expect(np.weekday(date), 'शनिबार');
    expect(np.dateBoth(date), '14 November 2026 · २८ कात्तिक २०८३');
    expect(np.dateChipBs(date), 'शनि, २८ कात्तिक');
    expect(
      np.primaryDateLine(date, DatePrimary.nepali),
      'शनिबार, २८ कात्तिक २०८३',
    );
    expect(
      np.secondaryDateLine(date, DatePrimary.nepali),
      'Saturday, 14 November 2026',
    );
    expect(np.primaryDayShort(date, DatePrimary.nepali), '२८');
    expect(np.primaryDayShort(date, DatePrimary.english), '14');
    expect(
      np.primaryDateLine(date, DatePrimary.english),
      'Saturday, 14 November 2026',
    );
  });

  test('english formatting and Saturday-only specialist data', () {
    const en = L10n(AppLanguage.en);
    final date = DateTime(2026, 11, 14);
    expect(en.date(date), '14 November 2026');
    expect(en.weekday(date), 'Saturday');
    expect(en.money(800), 'Rs. 800');
    expect(en.time('09:00'), '9:00 AM');
    expect(en.dateChipAd(date), 'Sat, 14 Nov');
    expect(en.dateChipBs(date), 'शनि, २८ कात्तिक');

    expect(specialistDoctors, isNotEmpty);
    expect(
      specialistDoctors.every((doctor) => doctor.saturdayGroup != null),
      isTrue,
    );
    expect(
      bookableDepartments.map((department) => department.id),
      containsAll([
        'gyn',
        'ortho',
        'ent',
        'derma',
        'psych',
        'echo',
        'physician',
      ]),
    );
    expect(bookableDepartments.length, 7);
    expect(doctorById('ashish')!.isSpecialist, isFalse);
    expect(doctorById('navin')!.isSpecialist, isTrue);
    expect(doctorById('navin')!.saturdayGroup, SaturdayGroup.second);
    expect(doctorById('ashish')!.allClinicHours, isTrue);
    expect(saturdayGroupForDate(DateTime(2026, 11, 21)), SaturdayGroup.third);
    expect(saturdayGroupForDate(DateTime(2026, 11, 28)), SaturdayGroup.last);
    expect(
      saturdayDoctorsForDate(DateTime(2026, 11, 7)).map((doctor) => doctor.id),
      containsAll(['pratibha', 'bikas']),
    );
    expect(
      saturdayDoctorsForDate(DateTime(2026, 11, 14)).map((doctor) => doctor.id),
      containsAll(['navin', 'sunita']),
    );
    expect(
      saturdayDoctorsForDate(DateTime(2026, 11, 21)).map((doctor) => doctor.id),
      ['rajan'],
    );
    expect(
      saturdayDoctorsForDate(DateTime(2026, 11, 28)).map((doctor) => doctor.id),
      containsAll(['suman', 'sujan']),
    );
    expect(doctorById('sunita')!.displayName, contains(' / '));
    expect(departmentById('gyn').displayName, 'Gynecology / स्त्री रोग');
  });

  test('opening hours are derived from Clinic, not restated as text', () {
    const en = L10n(AppLanguage.en);
    const np = L10n(AppLanguage.np);
    expect(Clinic.openHour, 7);
    expect(Clinic.closeHour, 20);
    expect(en.weekdayHours, '7:00 AM – 8:00 PM');
    expect(np.weekdayHours, contains('७:००'));
    expect(np.weekdayHours, contains('८:००'));
    expect(
      en.nextOpening(DateTime(2026, 11, 14, 6)),
      'Opens today at 7:00 AM',
    );
    expect(
      en.nextOpening(DateTime(2026, 11, 14, 19)),
      'Opens tomorrow at 7:00 AM',
    );
    expect(
      np.nextOpening(DateTime(2026, 11, 14, 6)),
      'आज बिहान ७:०० बाट खुल्छ',
    );
  });

  test('books a Saturday visit and writes it through the server', () async {
    SharedPreferences.setMockInitialValues({});
    final clinic = FakeClinic();
    final state = await AppState.load(data: clinic);

    expect(state.signedIn, isTrue);
    expect(state.profile.patientId, 'BSP-0001');
    expect(state.appointments, isEmpty);

    final date = nextSaturdayForGroup(SaturdayGroup.third);
    final rajan = doctorById('rajan')!;
    final result = await state.bookAppointment(
      department: departmentById('ortho'),
      doctor: rajan,
      date: date,
      patientName: 'परीक्षण बिरामी',
      phone: '9800000000',
    );

    expect(result.ok, isTrue);
    expect(clinic.bookCalls, 1);
    expect(state.appointments.single.date, dateOnly(date));
    expect(state.appointments.single.fee, rajan.fee);
    expect(state.upcomingAppointments, hasLength(1));
    expect(state.notifications, hasLength(1));
  });

  test('a repeat booking is stopped locally, without a round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final clinic = FakeClinic();
    final state = await AppState.load(data: clinic);
    final date = nextSaturdayForGroup(SaturdayGroup.third);
    final rajan = doctorById('rajan')!;
    final ortho = departmentById('ortho');

    await state.bookAppointment(
      department: ortho,
      doctor: rajan,
      date: date,
      patientName: 'क',
      phone: '9800000000',
    );
    expect(clinic.bookCalls, 1);

    final second = await state.bookAppointment(
      department: ortho,
      doctor: rajan,
      date: date,
      patientName: 'ख',
      phone: '9800000001',
    );
    expect(second.failure, BookingFailure.alreadyBooked);
    // The local pre-check caught it, so the server was not asked again.
    expect(clinic.bookCalls, 1);
  });

  test('a server rejection is reported with its reason', () async {
    SharedPreferences.setMockInitialValues({});
    final clinic = FakeClinic()..failNext = BookingFailure.full;
    final state = await AppState.load(data: clinic);

    final result = await state.bookAppointment(
      department: departmentById('ortho'),
      doctor: doctorById('rajan'),
      date: nextSaturdayForGroup(SaturdayGroup.third),
      patientName: 'क',
      phone: '9800000000',
    );

    expect(result.ok, isFalse);
    expect(result.failure, BookingFailure.full);
    expect(state.appointments, isEmpty);
  });

  test('reschedule moves the date, a blocked write says so', () async {
    SharedPreferences.setMockInitialValues({});
    final clinic = FakeClinic();
    final state = await AppState.load(data: clinic);
    final ortho = departmentById('ortho');
    final rajan = doctorById('rajan')!;

    final first = await state.bookAppointment(
      department: ortho,
      doctor: rajan,
      date: nextSaturdayForGroup(SaturdayGroup.third),
      patientName: 'क',
      phone: '9800000000',
    );
    final later = nextSaturdayForGroup(SaturdayGroup.third, from: first.appointment!.date);

    expect(await state.rescheduleAppointment(first.appointment!.id, date: later), isTrue);
    expect(state.appointments.single.date, dateOnly(later));
    expect(clinic.moveCalls, 1);

    clinic.writeFails = true;
    expect(await state.rescheduleAppointment(first.appointment!.id, date: first.appointment!.date), isFalse);
    expect(state.offline, isTrue);
  });

  test('cancel then restore round-trip, restore refused once the date is taken', () async {
    SharedPreferences.setMockInitialValues({});
    final clinic = FakeClinic();
    final state = await AppState.load(data: clinic);
    final ortho = departmentById('ortho');
    final rajan = doctorById('rajan')!;
    final date = nextSaturdayForGroup(SaturdayGroup.third);

    final a = await state.bookAppointment(
      department: ortho,
      doctor: rajan,
      date: date,
      patientName: 'क',
      phone: '9800000000',
    );
    expect(await state.cancelAppointment(a.appointment!.id), isTrue);
    expect(state.appointments.single.status, AppointmentStatus.cancelled);

    expect(await state.restoreAppointment(a.appointment!.id), isTrue);
    expect(state.appointments.single.status, AppointmentStatus.booked);

    // A cancelled booking leaves the slot; someone else taking it blocks the
    // restore, which the local list can see.
    await state.cancelAppointment(a.appointment!.id);
    clinic.stored.add(
      Appointment(
        id: 'apt-other',
        departmentId: 'ortho',
        departmentName: 'Orthopaedics',
        doctorId: 'rajan',
        doctorName: 'Dr. Rajan',
        date: dateOnly(date),
        slot: '10:00',
        patientName: 'ख',
        phone: '9800000001',
        fee: 800,
        status: AppointmentStatus.booked,
        createdAt: DateTime.now(),
      ),
    );
    state.appointments = await state.data.myAppointments();
    expect(await state.restoreAppointment(a.appointment!.id), isFalse);
  });

  test('a failed cancel never claims the visit was cancelled', () async {
    SharedPreferences.setMockInitialValues({});
    final clinic = FakeClinic();
    final state = await AppState.load(data: clinic);
    final booked = await state.bookAppointment(
      department: departmentById('ortho'),
      doctor: doctorById('rajan'),
      date: nextSaturdayForGroup(SaturdayGroup.third),
      patientName: 'क',
      phone: '9800000000',
    );

    clinic.writeFails = true;
    expect(await state.cancelAppointment(booked.appointment!.id), isFalse);
    expect(state.appointments.single.status, AppointmentStatus.booked);
    expect(state.offline, isTrue);
  });

  test('a past booked visit reads as completed after the day turns', () async {
    SharedPreferences.setMockInitialValues({});
    final clinic = FakeClinic();
    final state = await AppState.load(data: clinic);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    clinic.stored.add(
      Appointment(
        id: 'past-booked',
        departmentId: 'gyn',
        departmentName: 'Gynecology',
        doctorId: 'sunita',
        doctorName: 'Dr. Sunita',
        date: dateOnly(yesterday),
        slot: '10:30',
        patientName: 'क',
        phone: '9800000000',
        fee: 800,
        status: AppointmentStatus.booked,
        createdAt: yesterday,
      ),
    );

    await state.refresh();

    expect(state.appointments.single.status, AppointmentStatus.completed);
    expect(state.pastAppointments.single.id, 'past-booked');
  });

  test('an unreachable server still renders the shipped catalog', () async {
    SharedPreferences.setMockInitialValues({});
    final clinic = FakeClinic(served: false);
    final state = await AppState.load(data: clinic);

    expect(state.offline, isTrue);
    expect(departments, isNotEmpty);
    expect(specialistDoctors, isNotEmpty);
    expect(state.appointments, isEmpty);
  });

  test('appearance settings survive a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final clinic = FakeClinic();
    final state = await AppState.load(data: clinic);

    state.setNepaliHeadingFont(NepaliFont.baloo2);
    state.setNepaliBodyFont(NepaliFont.hind);
    state.setEnglishFont(EnglishFont.inter);
    state.setDatePrimary(DatePrimary.english);
    state.setTabOrder([4, 0, 1, 2, 3]);

    final reloaded = await AppState.load(data: FakeClinic());
    expect(reloaded.nepaliHeadingFont, NepaliFont.baloo2);
    expect(reloaded.nepaliBodyFont, NepaliFont.hind);
    expect(reloaded.englishFont, EnglishFont.inter);
    expect(reloaded.datePrimary, DatePrimary.english);
    expect(reloaded.tabOrder, [4, 0, 1, 2, 3]);
  });

  test('an upgraded demo install keeps settings and loses invented records', () async {
    SharedPreferences.setMockInitialValues({
      'seeded_v1': true,
      'signed_in_v1': true,
      'profile_v1': jsonEncode(testProfile().toJson()),
      'appointments_v1': jsonEncode([
        {'id': 'apt-1', 'patientName': 'सीता श्रेष्ठ', 'status': 'booked'},
      ]),
      'notifications_v1': jsonEncode([
        {'id': 'notif-appointment', 'title': 't', 'body': 'b', 'kind': 'appointment'},
      ]),
      'language_v1': 'np',
      'nepali_heading_font_v1': 'mukta',
    });

    final state = await AppState.load(data: FakeClinic(signedInValue: false));

    expect(state.language, AppLanguage.np);
    expect(state.nepaliHeadingFont, NepaliFont.mukta);
    // The demo history is gone from preferences, and a stored bool is not a
    // session: only the server decides whether someone is signed in.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('appointments_v1'), isNull);
    expect(prefs.getString('profile_v1'), isNull);
    expect(prefs.getBool('signed_in_v1'), isNull);
    expect(state.signedIn, isFalse);
    expect(state.appointments, isEmpty);
  });
}
