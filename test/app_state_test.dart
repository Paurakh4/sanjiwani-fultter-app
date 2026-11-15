import 'package:battar_sanjibani/core/fonts.dart';
import 'package:battar_sanjibani/core/l10n.dart';
import 'package:battar_sanjibani/core/nepali.dart';
import 'package:battar_sanjibani/core/saturday_schedule.dart';
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

    final appointment = state.bookAppointment(
      department: departmentById('gyn'),
      doctor: doctorById('sunita'),
      date: nextSaturdayForGroup(SaturdayGroup.second),
      slot: '10:30',
      patientName: 'परीक्षण बिरामी',
      phone: '9800000000',
    );

    expect(appointment.date.weekday, DateTime.saturday);
    expect(state.upcomingAppointments.length, upcomingBefore + 1);
    expect(state.notifications.first.title, 'अपोइन्टमेन्ट पुष्टि भयो');

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
  });
}
