import 'dart:convert';

import 'package:battar_sanjibani/core/fonts.dart';
import 'package:battar_sanjibani/core/l10n.dart';
import 'package:battar_sanjibani/core/nepali.dart';
import 'package:battar_sanjibani/core/saturday_schedule.dart';
import 'package:battar_sanjibani/core/slot_availability.dart';
import 'package:battar_sanjibani/data/demo_data.dart';
import 'package:battar_sanjibani/models.dart';
import 'package:battar_sanjibani/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('seeds demo data, books Saturday, cancels, persists fonts', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();

    expect(state.profile.name, 'सीता श्रेष्ठ');
    expect(state.upcomingAppointments, isNotEmpty);
    expect(state.nepaliHeadingFont, NepaliFont.anek);
    expect(state.nepaliBodyFont, NepaliFont.mukta);
    expect(state.englishFont, EnglishFont.poppins);
    final upcomingBefore = state.upcomingAppointments.length;

    final date = nextSaturdayForGroup(SaturdayGroup.third);
    final rajan = doctorById('rajan')!;
    expect(isDateBookable(doctor: rajan, date: date), isTrue);

    final appointment = state.bookAppointment(
      department: departmentById('ortho'),
      doctor: rajan,
      date: date,
      patientName: 'परीक्षण बिरामी',
      phone: '9800000000',
    );

    expect(appointment, isNotNull);
    expect(appointment!.date.weekday, DateTime.saturday);
    expect(appointment.slot, rajan.startTime);
    expect(state.datePrimary, DatePrimary.nepali);
    state.setDatePrimary(DatePrimary.english);
    expect(state.upcomingAppointments.length, upcomingBefore + 1);
    expect(state.notifications.first.title, 'अपोइन्टमेन्ट पुष्टि भयो');
    expect(state.notifications.first.refId, appointment.id);

    state.cancelAppointment(appointment.id);
    expect(
      state.appointments.firstWhere((item) => item.id == appointment.id).status,
      AppointmentStatus.cancelled,
    );
    expect(
      state.pastAppointments.any((item) => item.id == appointment.id),
      isTrue,
    );

    state.setNepaliHeadingFont(NepaliFont.baloo2);
    state.setNepaliBodyFont(NepaliFont.hind);
    state.setEnglishFont(EnglishFont.inter);

    final reloaded = await AppState.load();
    expect(
      reloaded.appointments.any((item) => item.id == appointment.id),
      isTrue,
    );
    expect(reloaded.nepaliHeadingFont, NepaliFont.baloo2);
    expect(reloaded.nepaliBodyFont, NepaliFont.hind);
    expect(reloaded.englishFont, EnglishFont.inter);
    expect(reloaded.datePrimary, DatePrimary.english);
  });

  test('books one visit per doctor per date and reschedules by date', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    final date = nextSaturdayForGroup(SaturdayGroup.third);
    final laterDate = date.add(const Duration(days: 28));
    final rajan = doctorById('rajan')!;
    final ortho = departmentById('ortho');

    final a = state.bookAppointment(
      department: ortho,
      doctor: rajan,
      date: date,
      patientName: 'क',
      phone: '9800000000',
    )!;
    expect(
      state.bookAppointment(
        department: ortho,
        doctor: rajan,
        date: date,
        patientName: 'ख',
        phone: '9800000001',
      ),
      isNull,
    );

    final b = state.bookAppointment(
      department: ortho,
      doctor: rajan,
      date: laterDate,
      patientName: 'ग',
      phone: '9800000002',
    )!;

    expect(state.rescheduleAppointment(a.id, date: laterDate), isFalse);
    state.cancelAppointment(b.id);
    expect(state.rescheduleAppointment(a.id, date: laterDate), isTrue);

    final reloaded = await AppState.load();
    final moved = reloaded.appointments.firstWhere((item) => item.id == a.id);
    expect(moved.date, laterDate);
    expect(moved.slot, rajan.startTime);
  });

  test(
    'cancel then restore round-trip, restore fails when date is taken',
    () async {
      SharedPreferences.setMockInitialValues({});
      final state = await AppState.load();
      final date = nextSaturdayForGroup(SaturdayGroup.third);
      final rajan = doctorById('rajan')!;
      final ortho = departmentById('ortho');

      final a = state.bookAppointment(
        department: ortho,
        doctor: rajan,
        date: date,
        patientName: 'क',
        phone: '9800000000',
      )!;

      state.cancelAppointment(a.id);
      expect(state.restoreAppointment(a.id), isTrue);
      expect(
        state.appointments.firstWhere((item) => item.id == a.id).status,
        AppointmentStatus.booked,
      );

      state.cancelAppointment(a.id);
      final b = state.bookAppointment(
        department: ortho,
        doctor: rajan,
        date: date,
        patientName: 'ख',
        phone: '9800000001',
      )!;
      expect(state.restoreAppointment(a.id), isFalse);
      state.cancelAppointment(b.id);
      expect(state.restoreAppointment(a.id), isTrue);
    },
  );

  test('normalizes past booked appointments to completed on restore', () async {
    final past = DateTime.now().subtract(const Duration(days: 1));
    final apt = Appointment(
      id: 'past-booked',
      departmentId: 'gyn',
      departmentName: 'Gynecology / स्त्री रोग',
      doctorId: 'sunita',
      doctorName: 'Dr. Sunita Tamang / डा. सुनिता तामाङ',
      date: past,
      slot: '10:30',
      patientName: 'x',
      phone: '9800000000',
      fee: 800,
      status: AppointmentStatus.booked,
      createdAt: past,
    );
    SharedPreferences.setMockInitialValues({
      'seeded_v1': true,
      'profile_v1': jsonEncode(demoProfile().toJson()),
      'appointments_v1': jsonEncode([apt.toJson()]),
      'notifications_v1': jsonEncode(<Map<String, dynamic>>[]),
    });
    final state = await AppState.load();
    expect(state.appointments.first.status, AppointmentStatus.completed);
    expect(
      state.pastAppointments.any((item) => item.id == 'past-booked'),
      isTrue,
    );
  });

  test('falls back gracefully on corrupt prefs', () async {
    SharedPreferences.setMockInitialValues({
      'seeded_v1': true,
      'appointments_v1': 'not-json',
      'profile_v1': '{bad',
    });
    final state = await AppState.load();
    expect(state.appointments, isEmpty);
    expect(state.profile.name, 'सीता श्रेष्ठ');
  });

  test(
    're-anchors a drifted demo upcoming appointment to the future',
    () async {
      final past = DateTime.now().subtract(const Duration(days: 14));
      final demo = Appointment(
        id: 'demo-upcoming',
        departmentId: 'gyn',
        departmentName: 'Gynecology / स्त्री रोग',
        doctorId: 'sunita',
        doctorName: 'Dr. Sunita Tamang / डा. सुनिता तामाङ',
        date: past,
        slot: '10:30',
        patientName: 'सीता श्रेष्ठ',
        phone: '9841234567',
        fee: 800,
        status: AppointmentStatus.booked,
        createdAt: past,
      );
      SharedPreferences.setMockInitialValues({
        'seeded_v1': true,
        'profile_v1': jsonEncode(demoProfile().toJson()),
        'appointments_v1': jsonEncode([demo.toJson()]),
        'notifications_v1': jsonEncode([
          AppNotification(
            id: 'notif-appointment',
            title: 't',
            body: 'b',
            time: DateTime.now(),
            kind: 'appointment',
          ).toJson(),
        ]),
      });
      final state = await AppState.load();
      final a = state.appointments.firstWhere(
        (item) => item.id == 'demo-upcoming',
      );
      expect(a.status, AppointmentStatus.booked);
      expect(a.date.weekday, DateTime.saturday);
      expect(a.date.isAfter(DateTime.now()), isTrue);
    },
  );
}
