import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'bs_date.dart' as bs;
import 'nepali.dart' as np;
import 'saturday_schedule.dart';

enum AppLanguage {
  np('ne'),
  en('en');

  const AppLanguage(this.code);
  final String code;
}

class L10n {
  const L10n(this.language);

  final AppLanguage language;

  bool get isEn => language == AppLanguage.en;

  static const delegate = L10nDelegate();
  static const supportedLocales = <Locale>[Locale('ne'), Locale('en')];

  static L10n of(BuildContext context) =>
      Localizations.of<L10n>(context, L10n) ?? const L10n(AppLanguage.np);

  String _t(String npText, String enText) => isEn ? enText : npText;

  // Formatting helpers -------------------------------------------------------

  String digits(Object value) =>
      isEn ? value.toString() : np.nepDigits(value.toString());

  String date(DateTime value) => isEn ? _adDateLong(value) : bs.bsDateNp(value);

  String dateMedium(DateTime value) => isEn
      ? '${value.day} ${_monthsEn[value.month - 1]}'
      : bs.bsDateNpShort(value);

  String dateShort(DateTime value) => isEn
      ? '${_monthsShortEn[value.month - 1]} ${value.day}'
      : bs.bsDateNpShort(value);

  String weekday(DateTime value) =>
      isEn ? _weekdaysEn[value.weekday % 7] : np.nepWeekday(value);

  String weekdayShort(DateTime value) =>
      isEn ? _weekdaysShortEn[value.weekday % 7] : np.nepWeekdayShort(value);

  String monthShort(DateTime value) =>
      isEn ? _monthsShortEn[value.month - 1] : bs.bsMonthNp(value);

  String todayLine(DateTime value) => isEn
      ? '${weekday(value)}, ${_adDateLong(value)}'
      : '${np.nepWeekday(value)}, ${bs.bsDateNp(value)}';

  String todayBoth(DateTime value) {
    final ad =
        '${_weekdaysShortEn[value.weekday % 7]}, ${value.day} '
        '${_monthsShortEn[value.month - 1]}';
    final nepali = '${np.nepWeekdayShort(value)}, ${bs.bsDateNpShort(value)}';
    return isEn ? '$ad · $nepali' : '$nepali · $ad';
  }

  String dateBoth(DateTime value) =>
      '${_adDateLong(value)} · ${bs.bsDateNp(value)}';

  String dateBothShort(DateTime value) =>
      '${value.day} ${_monthsShortEn[value.month - 1]} ${value.year} · '
      '${bs.bsDateNp(value)}';

  String weekdayBoth(DateTime value) =>
      '${_weekdaysEn[value.weekday % 7]} / ${np.nepWeekday(value)}';

  String dateChipAd(DateTime value) =>
      '${_weekdaysShortEn[value.weekday % 7]}, ${value.day} '
      '${_monthsShortEn[value.month - 1]}';

  String dateChipBs(DateTime value) =>
      '${np.nepWeekdayShort(value)}, ${bs.bsDateNpShort(value)}';

  String relativeDay(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(value.year, value.month, value.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return _t('आज', 'Today');
    if (diff == 1) return _t('भोलि', 'Tomorrow');
    return weekday(value);
  }

  String timeShort(String slot) {
    final parts = slot.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    if (!isEn) return np.slotTime(slot);
    final h12 = hour > 12 ? hour - 12 : hour;
    return '$h12:$minute';
  }

  String time(String slot) {
    if (!isEn) return np.slotLabel(slot);
    final parts = slot.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour > 12 ? hour - 12 : hour;
    return '$h12:$minute $suffix';
  }

  String timeRange(String start, String end) {
    if (isEn) return '${time(start)} – ${time(end)}';
    final shift = np.slotLabel(start).split(' ').first;
    return '$shift ${timeShort(start)} – ${timeShort(end)}';
  }

  String appointmentTime(String slot) =>
      isEn ? time(slot) : '${np.slotLabel(slot)} बजे';

  String clock(DateTime value) {
    final slot =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return time(slot);
  }

  String notificationStamp(DateTime value) {
    final now = DateTime.now();
    final sameDay =
        value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
    return sameDay ? clock(value) : dateMedium(value);
  }

  String hoursToday(DateTime value) => weekdayHours;

  String nextOpening(DateTime value) {
    if (value.hour < 7) {
      return _t('आज बिहान ७:०० बाट खुल्छ', 'Opens today at 7:00 AM');
    }
    return _t('भोलि बिहान ७:०० बाट खुल्छ', 'Opens tomorrow at 7:00 AM');
  }

  String money(int amount) => isEn ? 'Rs. $amount' : 'रु. ${digits(amount)}';

  String doctorCount(int count) => isEn
      ? '$count ${count == 1 ? 'doctor' : 'doctors'}'
      : '${digits(count)} डाक्टर';

  String gender(String stored) {
    if (!isEn) return stored;
    return switch (stored) {
      'महिला' => 'Female',
      'पुरुष' => 'Male',
      'अन्य' => 'Other',
      _ => stored,
    };
  }

  String personName(String stored) {
    if (!isEn) return stored;
    return switch (stored) {
      'सीता' => 'Sita',
      'सीता श्रेष्ठ' => 'Sita Shrestha',
      _ => stored,
    };
  }

  String age(String stored) {
    final ascii = np.asciiDigits(stored);
    final value = int.tryParse(ascii) ?? ascii;
    return isEn ? '$value years' : '${digits(value)} वर्ष';
  }

  // Common -------------------------------------------------------------------

  String get navHome => _t('गृह', 'Home');
  String get navAppointments => _t('अपोइन्टमेन्ट', 'Appointments');
  String get navRecords => _t('रेकर्ड', 'Records');
  String get navProfile => _t('प्रोफाइल', 'Profile');

  String get all => _t('सबै', 'All');
  String get cancel => _t('रद्द', 'Cancel');
  String get okay => _t('ठीक छ', 'OK');
  String get save => _t('सुरक्षित गर्नुहोस्', 'Save');
  String get keep => _t('रहिरहनुहोस्', 'Keep it');
  String get viewAll => _t('सबै', 'View all');
  String get todayShort => _t('आज', 'Today');
  String get languageNepali => 'नेपाली';
  String get languageEnglish => 'English';

  // Onboarding ---------------------------------------------------------------

  String get welcomeTitle => _t('स्वागत छ', 'Welcome');
  String get welcomeBody => _t(
    'एप सुरु गर्न आफ्नो भाषा र थिम छान्नुहोस्।',
    'Choose your language and theme to get started.',
  );
  String get chooseLanguage => _t('भाषा', 'Language');
  String get chooseTheme => _t('थिम', 'Theme');
  String get chooseAccent => _t('रङ', 'Accent color');
  String get themeLight => _t('उज्यालो', 'Light');
  String get themeDark => _t('अँध्यारो', 'Dark');
  String get themeSystem => _t('सिस्टम', 'System');
  String get getStarted => _t('सुरु गर्नुहोस्', 'Get started');
  String get settingsLater => _t(
    'यी विकल्प पछि प्रोफाइलबाट परिवर्तन गर्न सकिन्छ।',
    'You can change these later from your profile.',
  );

  // Home ---------------------------------------------------------------------

  String greeting(String name) => _t('नमस्ते, $name', 'Hello, $name');

  String get homePrompt =>
      _t('आज कसरी सहयोग गर्न सक्छौं?', 'How can we help you today?');
  String get noticesTitle => _t('सूचना', 'Notices');
  String get swipeHint => _t('स्वाइप गर्नुहोस्', 'Swipe');
  String get noticeTapHint =>
      _t('पूरा विवरण हेर्न ट्याप गर्नुहोस्', 'Tap for full details');
  String get noticeRegisterCall =>
      _t('नाम टिपाउन फोन गर्नुहोस्', 'Call to register');

  String get quickBook => _t('बुकिङ', 'Book');
  String get quickDoctors => _t('डाक्टर', 'Doctors');
  String get quickReports => _t('रिपोर्ट', 'Reports');
  String get quickContact => _t('सम्पर्क', 'Contact');

  String get openToday => _t('आज खुला छ', 'Open today');
  String get closedNow => _t('अहिले बन्द छ', 'Closed now');
  String get weekdayHours => _t('बिहान ७:०० – साँझ ८:००', '7:00 AM – 8:00 PM');
  String get everyDay => _t('प्रत्येक दिन', 'Every day');
  String get specialistHours =>
      _t('बिहान १०:०० – साँझ ५:००', '10:00 AM – 5:00 PM');
  String get specialistHoursShort => _t('१०–५ बजे', '10 AM – 5 PM');
  String get specialistHoursTitle =>
      _t('विशेषज्ञ सेवा (शनिबार)', 'Specialist clinic (Saturday)');

  String get departmentsServices =>
      _t('विभाग तथा सेवा', 'Departments & services');
  String get ourDoctors => _t('हाम्रा डाक्टर', 'Our doctors');
  String get contactLocation =>
      _t('सम्पर्क तथा अवस्थिति', 'Contact & location');
  String get serviceAvailable => _t('सेवा उपलब्ध', 'Service available');
  String get visiting => _t('भ्रमण', 'Visiting');
  String get bookShort => _t('अपोइन्टमेन्ट', 'Book');
  String get bookAppointment =>
      _t('अपोइन्टमेन्ट बुक गर्नुहोस्', 'Book appointment');
  String get callClinic => _t('फोन गर्नुहोस्', 'Call clinic');
  String get directions => _t('दिशा', 'Directions');
  String get clinicServiceName => _t('क्लिनिक सेवा', 'Clinic service');

  String get saturdaySpecialistsTitle =>
      _t('शनिबार विशेषज्ञ सेवा', 'Specialist Saturdays');
  String get saturdaySpecialistsSubtitle => _t(
    'विशेषज्ञहरू महिनाको निश्चित शनिबारमा आउनुहुन्छ। तलको मासिक परिक्रमा हेर्नुहोस्; परिवर्तन भए सूचना जाँच्नुहोस्।',
    'Specialists visit on fixed Saturdays each month. See the monthly rotation below and check notices for changes.',
  );
  String get thisSaturday => _t('यो शनिबार', 'This Saturday');
  String get mbbsOpdDaily => _t('MBBS OPD · दैनिक', 'MBBS OPD · daily');
  String get monthlyRotation => _t('मासिक परिक्रमा', 'Monthly rotation');
  String get viewSaturdaySchedule => _t('मासिक तालिका', 'Monthly schedule');
  String get saturdayScheduleTitle =>
      _t('शनिबारको तालिका', 'Saturday schedule');
  String get saturdayScheduleNote => _t(
    'तालिका प्रायः निश्चित हुन्छ, तर केही महिना परिवर्तन हुन सक्छ। यात्रा अघि सूचना जाँच्नुहोस्।',
    'The rotation is usually fixed but can change. Check clinic notices before travelling.',
  );
  String get fiveSaturdayNote => _t(
    'महिनामा पाँच शनिबार परे अन्तिम शनिबारलाई मानिन्छ।',
    'When a month has five Saturdays, the last Saturday is used.',
  );
  String get noSpecialistThisSaturday => _t(
    'यो शनिबार विशेषज्ञ परिक्रमा छैन। क्लिनिक खुल्ने समयभर MBBS OPD उपलब्ध छ।',
    'No specialist rotation this Saturday. MBBS OPD is available during clinic hours.',
  );
  String get specialistRotationNote => _t(
    'विशेषज्ञ सेवा शनिबार परिक्रमा अनुसार हुन्छ। छानिएको डाक्टरको मिति मात्र देखाइएको छ।',
    'Specialties rotate across Saturdays. Only dates for the selected doctor are shown.',
  );
  String get rotationScheduleLabel =>
      _t('परिक्रमा तालिका', 'Rotation schedule');
  String get tapDoctorToBook => _t(
    'डाक्टरमा ट्याप गरेर त्यो शनिबारको अपोइन्टमेन्ट बुक गर्नुहोस्।',
    'Tap a doctor to book that Saturday.',
  );
  String get specialistOnlyNote => _t(
    'एपबाट अपोइन्टमेन्ट विशेषज्ञ डाक्टरका लागि शनिबार मात्र। प्रत्येक विशेषज्ञ महिनाको निश्चित शनिबार आउनुहुन्छ।',
    'App appointments are for Saturday specialists only. Each specialist visits on a fixed Saturday of the month.',
  );

  // Doctor calendar ----------------------------------------------------------

  String get doctorCalendarTitle => _t('डाक्टर पात्रो', 'Doctor calendar');
  String get viewDoctorCalendar => _t('पात्रो हेर्नुहोस्', 'View calendar');
  String get doctorCalendarHint => _t(
    'विशेषज्ञ डाक्टर आउने शनिबार छुनुहोस् — त्यो दिनका डाक्टरहरू देखिन्छन्।',
    'Tap a Saturday to see which specialists are in that day.',
  );
  String get prevMonth => _t('अघिल्लो महिना', 'Previous month');
  String get nextMonth => _t('अर्को महिना', 'Next month');
  String get goToday => _t('आजको महिना', 'This month');

  String saturdayGroupLabel(SaturdayGroup group) => switch (group) {
    SaturdayGroup.first => _t('पहिलो शनिबार', '1st Saturday'),
    SaturdayGroup.second => _t('दोस्रो शनिबार', '2nd Saturday'),
    SaturdayGroup.third => _t('तेस्रो शनिबार', '3rd Saturday'),
    SaturdayGroup.last => _t('अन्तिम शनिबार', 'Last Saturday'),
  };

  String saturdayGroupShort(SaturdayGroup group) => switch (group) {
    SaturdayGroup.first => _t('१औँ शनि', '1st Sat'),
    SaturdayGroup.second => _t('२औँ शनि', '2nd Sat'),
    SaturdayGroup.third => _t('३औँ शनि', '3rd Sat'),
    SaturdayGroup.last => _t('अन्तिम शनि', 'Last Sat'),
  };

  String nextDateLabel(DateTime date) =>
      _t('अर्को मिति: ${dateBoth(date)}', 'Next: ${dateBoth(date)}');

  // Booking ------------------------------------------------------------------

  String get bookingNew => _t('नयाँ अपोइन्टमेन्ट', 'New appointment');
  String get bookingIntro => _t(
    'विशेषज्ञ डाक्टरका लागि शनिबारको समय बुक गर्नुहोस्।',
    'Book a Saturday visit with a specialist doctor.',
  );
  String get bookingStepDepartment => _t('विशेषज्ञ सेवा', 'Specialist service');
  String get bookingStepDoctor => _t('विशेषज्ञ डाक्टर', 'Specialist doctor');
  String get bookingStepDate => _t('शनिबारको मिति', 'Saturday date');
  String get bookingSaturdayNote => _t(
    'विशेषज्ञ OPD हरेक शनिबार बिहान १०:०० – साँझ ५:०० बजेसम्म चल्छ। डाक्टरअनुसार शनिबार फरक पर्छ; उपलब्ध मिति मात्र देखाइएको छ।',
    'Specialist OPD runs every Saturday, 10:00 AM – 5:00 PM. Each doctor visits on specific Saturdays; only available dates are shown.',
  );
  String get bookingStepTime => _t('समय', 'Time');
  String get bookingStepPatient => _t('बिरामीको विवरण', 'Patient details');

  String bookingDoctorNote(String availability, int fee) => _t(
    '$availability · परामर्श शुल्क ${money(fee)}',
    '$availability · Consultation fee ${money(fee)}',
  );
  String bookingDoctorAvailableNote(String name, String availability) => _t(
    '$name $availability उपलब्ध हुनुहुन्छ।',
    '$name is available $availability.',
  );
  String get bookingNoSlots => _t(
    'यस शनिबारका लागि उपलब्ध समय सकिएको छ। कृपया अर्को शनिबार छान्नुहोस्।',
    'No slots are left on this Saturday. Please choose another Saturday.',
  );

  String get shiftMorning => _t('बिहान', 'Morning');
  String get shiftAfternoon => _t('दिउँसो', 'Afternoon');
  String get shiftEvening => _t('साँझ', 'Evening');

  String get bookingPatientNameHint =>
      _t('बिरामीको पूरा नाम', "Patient's full name");
  String get bookingPhoneHint => _t('फोन नम्बर', 'Phone number');
  String get bookingNameError =>
      _t('कृपया बिरामीको नाम लेख्नुहोस्।', "Please enter the patient's name.");
  String get bookingPhoneError => _t(
    'कृपया सही फोन नम्बर लेख्नुहोस्।',
    'Please enter a valid phone number.',
  );

  String get summaryDepartment => _t('विभाग', 'Department');
  String get summaryDoctor => _t('डाक्टर', 'Doctor');
  String get summaryDate => _t('मिति (वि.सं. / ई.सं.)', 'Date (BS / AD)');
  String get summaryTime => _t('समय', 'Time');
  String get summaryFee => _t('शुल्क', 'Fee');
  String get summaryNotSelected => _t('छानिएको छैन', 'Not selected');
  String get bookingNote => _t(
    'भुक्तानी क्लिनिकमै गर्नुहोस्। अपोइन्टमेन्ट समयभन्दा १० मिनेट अघि आउनुहोस्।',
    'Pay at the clinic. Please arrive 10 minutes before your appointment.',
  );
  String get confirmAppointment =>
      _t('अपोइन्टमेन्ट पुष्टि गर्नुहोस्', 'Confirm appointment');
  String get chooseSlotSnack =>
      _t('कृपया अपोइन्टमेन्टको समय छान्नुहोस्।', 'Please choose a time slot.');

  String get appointmentConfirmedTitle =>
      _t('अपोइन्टमेन्ट पुष्टि भयो', 'Appointment confirmed');
  String get appointmentConfirmedSnack =>
      _t('अपोइन्टमेन्ट पुष्टि भयो।', 'Appointment confirmed.');

  // Appointments -------------------------------------------------------------

  String get appointmentsTitle => _t('अपोइन्टमेन्ट', 'Appointments');
  String get appointmentsSubtitle =>
      _t('आगामी र विगतका भेटघाटहरू', 'Your upcoming and past visits');
  String get newAppointment => _t('नयाँ अपोइन्टमेन्ट', 'New appointment');
  String get tabUpcoming => _t('आगामी', 'Upcoming');
  String get tabPast => _t('विगत', 'Past');

  String get emptyUpcomingTitle =>
      _t('कुनै आगामी अपोइन्टमेन्ट छैन', 'No upcoming appointments');
  String get emptyUpcomingMessage => _t(
    'डाक्टर वा सेवा छानेर नयाँ समय बुक गर्नुहोस्।',
    'Choose a doctor or service and book a new time.',
  );
  String get emptyPastTitle => _t('विगतको रेकर्ड छैन', 'No past visits');
  String get emptyPastMessage => _t(
    'सम्पन्न भएका भेटघाटहरू यहाँ देखिनेछन्।',
    'Your completed visits will appear here.',
  );
  String get bookSlot => _t('समय बुक गर्नुहोस्', 'Book a slot');

  String get statusUpcoming => _t('आगामी', 'Upcoming');
  String get statusCompleted => _t('सम्पन्न', 'Completed');
  String get statusCancelled => _t('रद्द', 'Cancelled');

  String patientLabel(String name) => _t('बिरामी: $name', 'Patient: $name');
  String get cancelAppointment => _t('रद्द', 'Cancel');
  String get cancelDialogTitle =>
      _t('अपोइन्टमेन्ट रद्द गर्ने?', 'Cancel appointment?');
  String cancelDialogBody(DateTime value, String slot) => _t(
    '${weekdayBoth(value)}, ${dateBoth(value)} को ${appointmentTime(slot)} को अपोइन्टमेन्ट रद्द गर्ने हो?',
    'Cancel your appointment on ${weekdayBoth(value)}, ${dateBoth(value)} at ${appointmentTime(slot)}?',
  );
  String get cancelDoneSnack =>
      _t('अपोइन्टमेन्ट रद्द गरियो।', 'Appointment cancelled.');

  // Records ------------------------------------------------------------------

  String get recordsTitle => _t('मेडिकल रेकर्ड', 'Medical records');
  String get recordsSubtitle => _t(
    'भ्रमण, निदान र ल्याब रिपोर्टहरू',
    'Visits, diagnoses and lab reports',
  );
  String get filterVisits => _t('भ्रमण', 'Visits');
  String get filterLabs => _t('ल्याब', 'Lab');
  String get recordsDemoNote => _t(
    'यो डेमो संस्करणमा नमुना रेकर्डहरू देखाइएका छन्।',
    'This demo build shows sample records.',
  );
  String get noRecordsTitle => _t('कुनै रेकर्ड भेटिएन', 'No records found');
  String get noRecordsMessage => _t(
    'यस श्रेणीमा हाल कुनै रेकर्ड छैन।',
    'There are no records in this category.',
  );
  String get reportDetails => _t('रिपोर्ट विवरण', 'Report details');
  String get sectionResults => _t('जाँचको नतिजा', 'Results');
  String get sectionLabResults => _t('ल्याब नतिजा', 'Lab results');
  String get sectionMedicines => _t('औषधि', 'Medicines');
  String get sectionNotes => _t('परामर्श नोट', 'Consultation notes');
  String referenceLabel(String range) =>
      _t('सामान्य: $range', 'Reference: $range');
  String get recordDisclaimer => _t(
    'यो नमुना रेकर्ड हो। आधिकारिक जानकारीका लागि क्लिनिकमा सम्पर्क गर्नुहोस्।',
    'This is a sample record. Contact the clinic for official information.',
  );

  // Profile ------------------------------------------------------------------

  String get profileTitle => _t('प्रोफाइल', 'Profile');
  String get editProfileTooltip => _t('प्रोफाइल सम्पादन', 'Edit profile');
  String patientIdLabel(String id) => _t('रोगी नं. $id', 'Patient ID $id');
  String bloodGroup(String value) =>
      _t('रक्त समूह $value', 'Blood group $value');
  String get upcomingLabel => _t('आगामी अपोइन्टमेन्ट', 'Upcoming appointments');
  String get recordsLabel => _t('मेडिकल रेकर्ड', 'Medical records');
  String get sectionMyHealth => _t('मेरो स्वास्थ्य', 'My health');
  String get notificationsLabel => _t('सूचनाहरू', 'Notifications');
  String get appointmentsMenu => _t('अपोइन्टमेन्टहरू', 'Appointments');
  String get sectionPreferences => _t('प्राथमिकता', 'Preferences');
  String get themeTitle => _t('थिम', 'Theme');
  String get themeSubtitle => _t('एपको रङ योजना', 'App appearance');
  String get languageTitle => _t('भाषा', 'Language');
  String get languageSubtitle =>
      _t('एपको भाषा छान्नुहोस्', 'Choose the app language');
  String get accentTitle => _t('रङ', 'Accent color');
  String get accentSubtitle =>
      _t('आफ्नो मनपर्ने रङ छान्नुहोस्', 'Pick your preferred accent');
  String get fontsTitle => _t('फन्ट', 'Fonts');
  String get fontsSubtitle => _t(
    'शीर्षक, मुख्य र अंग्रेजी टाइपफेस छान्नुहोस्',
    'Choose heading, body and English typefaces',
  );
  String get nepaliHeadingFontTitle =>
      _t('नेपाली शीर्षक फन्ट', 'Nepali heading font');
  String get nepaliBodyFontTitle => _t('नेपाली मुख्य फन्ट', 'Nepali body font');
  String get englishFontTitle => _t('अंग्रेजी फन्ट', 'English font');
  String get fontRoleNote => _t(
    'शीर्षक र ठूला अक्षरमा शीर्षक फन्ट, अन्य सबै पाठमा मुख्य फन्ट लागू हुन्छ।',
    'Headings and large text use the heading font; all other text uses the body font.',
  );
  String get nepaliFontSample =>
      _t('बट्टार सञ्जीवनी पॉलीक्लिनिक', 'बट्टार सञ्जीवनी पॉलीक्लिनिक');
  String get englishFontSample =>
      _t('Battar Sanjibani Polyclinic', 'Battar Sanjibani Polyclinic');
  String get sectionClinic => _t('क्लिनिक', 'Clinic');
  String get contactHours => _t('सम्पर्क तथा समय', 'Contact & hours');
  String get aboutApp => _t('एपको बारेमा', 'About this app');
  String get versionLabel => _t('संस्करण १.५.०', 'Version 1.5.0');
  String get demoBuildLabel =>
      _t('डेमो संस्करण — नमुना सामग्री', 'Demo build — sample content');

  String get aboutVersion => _t('संस्करण १.५.० · डेमो', 'Version 1.5.0 · Demo');
  String get aboutBody => _t(
    'यो एप क्लिनिकका बिरामीहरूका लागि बनाइएको नमुना संस्करण हो। अपोइन्टमेन्ट, प्रोफाइल र सूचनाहरू यही फोनमा सुरक्षित रहन्छन्।',
    'This is a demo app for clinic patients. Appointments, profile and notifications are stored only on this phone.',
  );
  String get editProfileTitle => _t('प्रोफाइल सम्पादन', 'Edit profile');
  String get editProfileIntro => _t(
    'आफ्नो व्यक्तिगत विवरण अद्यावधिक गर्नुहोस्।',
    'Update your personal details.',
  );
  String get fullNameHint => _t('पूरा नाम', 'Full name');
  String get phoneHint => _t('फोन नम्बर', 'Phone number');
  String get ageHint => _t('उमेर (वर्ष)', 'Age (years)');
  String get genderLabel => _t('लिङ्ग', 'Gender');
  String get bloodGroupLabel => _t('रक्त समूह', 'Blood group');
  String get addressHint => _t('ठेगाना', 'Address');
  String get patientIdField => _t('रोगी नं.', 'Patient ID');
  String get saveProfile => _t('सुरक्षित गर्नुहोस्', 'Save profile');
  String get profileSaved => _t('प्रोफाइल सुरक्षित भयो।', 'Profile saved.');
  String get nameRequired =>
      _t('कृपया नाम लेख्नुहोस्।', 'Please enter a name.');
  String get phoneInvalid => _t(
    'कृपया सही फोन नम्बर लेख्नुहोस्।',
    'Please enter a valid phone number.',
  );
  String get ageInvalid =>
      _t('कृपया सही उमेर लेख्नुहोस्।', 'Please enter a valid age.');

  // Notifications ------------------------------------------------------------

  String get notificationsTitle => _t('सूचनाहरू', 'Notifications');
  String get markAllRead => _t('सबै पढियो', 'Mark all read');
  String get groupToday => _t('आज', 'Today');
  String get groupYesterday => _t('हिजो', 'Yesterday');
  String get groupEarlier => _t('यसअघि', 'Earlier');
  String get noNotificationsTitle => _t('कुनै सूचना छैन', 'No notifications');
  String get noNotificationsMessage => _t(
    'क्लिनिकका नयाँ सूचना र सम्झनाहरू यहाँ देखिनेछन्।',
    'New clinic notices and reminders will appear here.',
  );

  // Contact ------------------------------------------------------------------

  String get contactTitle => _t('सम्पर्क तथा समय', 'Contact & hours');
  String get contactCall => _t('फोन गर्नुहोस्', 'Call clinic');
  String get contactWhatsapp => _t('व्हाट्सएप', 'WhatsApp');
  String get contactEmail => _t('इमेल', 'Email');
  String get contactSendEmail => _t('इमेल पठाउनुहोस्', 'Email the clinic');
  String get contactMap => _t('नक्सा', 'Map');
  String get contactOpenMap => _t('बाटो हेर्नुहोस्', 'Get directions');
  String get clinicHours => _t('क्लिनिकको समय', 'Clinic hours');
  String get contactDetails => _t('सम्पर्क विवरण', 'Contact details');
  String get phoneClinicSuffix => _t('(क्लिनिक)', '(Clinic)');
  String get phoneMobileSuffix => _t('(मोबाइल)', '(Mobile)');
  String get contactNote => _t(
    'एपबाट अपोइन्टमेन्ट विशेषज्ञ डाक्टरका लागि शनिबार मात्र। आपत्कालीन सेवाका लागि सिधै फोन गर्नुहोस्।',
    'App appointments are for Saturday specialists only. For urgent care, call the clinic directly.',
  );

  // Doctors & departments ----------------------------------------------------

  String get servicesTitle => _t('डाक्टर तथा सेवा', 'Doctors & services');
  String get tabDoctors => _t('डाक्टरहरू', 'Doctors');
  String get tabDepartments => _t('विभागहरू', 'Departments');
  String get noDoctorsTitle => _t('कुनै डाक्टर भेटिएन', 'No doctors found');
  String get noDoctorsMessage => _t(
    'यस विभागमा हाल डाक्टर उपलब्ध छैनन्।',
    'No doctors are currently available in this department.',
  );
  String get departmentDoctors =>
      _t('यस विभागका डाक्टरहरू', 'Doctors in this department');
  String get technicalServiceNote => _t(
    'यो सेवा सिधै क्लिनिकमा उपलब्ध छ। एपबाट अपोइन्टमेन्ट विशेषज्ञ डाक्टरका लागि शनिबार मात्र लिन सकिन्छ।',
    'This service is available at the clinic. In this app, appointments are for Saturday specialists only.',
  );
  String get walkInOnly => _t('सिधै आउनुहोस्', 'Walk-in only');
  String get walkInNote => _t(
    'यो डाक्टरको सेवा सिधै क्लिनिकमा उपलब्ध छ; एपबाट अपोइन्टमेन्ट लिन मिल्दैन।',
    'This doctor is available as a walk-in at the clinic; app appointments are not available.',
  );
  String get bookTime => _t('समय बुक गर्नुहोस्', 'Book a time');
  String get doctorDetails => _t('डाक्टर विवरण', 'Doctor details');
  String get departmentLabel => _t('विभाग', 'Department');
  String get availabilityLabel => _t('उपलब्धता', 'Availability');
  String get consultationFee => _t('परामर्श शुल्क', 'Consultation fee');
  String get locationLabel => _t('स्थान', 'Location');
  String get aboutDoctor => _t('परिचय', 'About');
  String get visitingNote => _t(
    'यी विशेषज्ञ महिनाको निश्चित शनिबार आउनुहुन्छ। मासिक तालिका हेरेर समयमै नाम टिपाउनुहोस्।',
    'This specialist visits on a fixed Saturday each month. Check the Saturday schedule and book early.',
  );
  String get payAtClinic =>
      _t('भुक्तानी क्लिनिकमै गर्नुहोस्।', 'Pay at the clinic.');
  String departmentPhoneNote(String phone) => _t(
    'अपोइन्टमेन्ट विशेषज्ञ डाक्टरका लागि शनिबार मात्र। थप जानकारीका लागि क्लिनिकमा फोन गर्नुहोस्: $phone',
    'Appointments are for specialist doctors on Saturdays only. For more information, call the clinic: $phone',
  );

  // Links --------------------------------------------------------------------

  String get linkError => _t(
    'लिङ्क खोल्न सकिएन। कृपया पछि प्रयास गर्नुहोस्।',
    'Could not open the link. Please try again later.',
  );

  // Notification demo text ---------------------------------------------------

  String get appointmentReminderTitle =>
      _t('अपोइन्टमेन्ट सम्झना', 'Appointment reminder');
  String appointmentReminderBody(DateTime value, String doctor) => _t(
    '${weekdayBoth(value)}, ${dateBoth(value)} मा $doctorसँगको अपोइन्टमेन्ट बाँकी छ। समयमै क्लिनिक पुग्नुहोस्।',
    'Your appointment with $doctor is on ${weekdayBoth(value)}, ${dateBoth(value)}. Please arrive on time.',
  );

  String get newNoticeTitle => _t('नयाँ सूचना', 'New notice');
  String get newNoticeBody => _t(
    'शनिबार मनोरोग तथा मुटु विशेषज्ञ सेवा उपलब्ध छ। समयमै नाम टिपाउनुहोस्।',
    'Psychiatry and cardiology specialist services are available on Saturday. Register early.',
  );

  String get labReportReadyTitle =>
      _t('ल्याब रिपोर्ट तयार', 'Lab report ready');
  String get labReportReadyBody => _t(
    'तपाईंको CBC रिपोर्ट तयार भएको छ। रिसेप्सनबाट संकलन गर्नुहोस्।',
    'Your CBC report is ready. Please collect it from reception.',
  );

  String get appointmentConfirmedTitleNotification => appointmentConfirmedTitle;
  String appointmentConfirmedBody(DateTime value, String department) => _t(
    '${weekdayBoth(value)}, ${dateBoth(value)} को अपोइन्टमेन्ट $department सेवाका लागि पुष्टि भएको छ।',
    'Your $department appointment on ${weekdayBoth(value)}, ${dateBoth(value)} is confirmed.',
  );
}

const _monthsEn = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _monthsShortEn = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _adDateLong(DateTime value) =>
    '${value.day} ${_monthsEn[value.month - 1]} ${value.year}';

const _weekdaysEn = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const _weekdaysShortEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class L10nDelegate extends LocalizationsDelegate<L10n> {
  const L10nDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ne' || locale.languageCode == 'en';

  @override
  Future<L10n> load(Locale locale) {
    final language = locale.languageCode == 'en'
        ? AppLanguage.en
        : AppLanguage.np;
    return SynchronousFuture(L10n(language));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<L10n> old) => false;
}
