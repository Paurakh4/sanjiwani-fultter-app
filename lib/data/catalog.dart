import '../core/icons.dart';

import '../core/saturday_schedule.dart';
import '../models.dart';

/// Bilingual fallback label for an appointment without a specific doctor.
const String kClinicServiceDisplayName = 'Clinic service / क्लिनिक सेवा';

const _shippedDepartments = <Department>[
  Department(
    id: 'opd',
    nameNp: 'सामान्य OPD',
    nameEn: 'General OPD',
    descriptionNp: 'हरेक दिन क्लिनिक खुल्ने समयभर MBBS मेडिकल अफिसरद्वारा OPD जाँच, परामर्श र प्राथमिक उपचार। अपोइन्टमेन्ट आवश्यक पर्दैन।',
    descriptionEn: 'Daily MBBS medical officer OPD for checks, consultations and primary care throughout clinic hours. No appointment needed.',
    icon: CoolIcons.stethoscope,
    doctorIds: ['ashish'],
  ),
  Department(
    id: 'physician',
    nameNp: 'भित्री रोग',
    nameEn: 'Internal Medicine',
    descriptionNp: 'भित्री रोग विशेषज्ञसहित परामर्श — महिनाको दोस्रो शनिबार; आइत–शुक्र दिउँसो पनि उपलब्ध।',
    descriptionEn: 'Internal medicine consultation with a specialist — 2nd Saturday; also available Sunday–Friday afternoons.',
    icon: CoolIcons.heartbeat,
    doctorIds: ['navin'],
  ),
  Department(
    id: 'gyn',
    nameNp: 'स्त्री रोग',
    nameEn: 'Gynecology',
    descriptionNp: 'गर्भवती जाँच, स्त्री रोग परामर्श र परिवार नियोजन — महिनाको दोस्रो शनिबार।',
    descriptionEn: 'Pregnancy checks, gynecology consultations and family planning — 2nd Saturday of the month.',
    icon: CoolIcons.genderFemale,
    doctorIds: ['sunita'],
  ),
  Department(
    id: 'xray',
    nameNp: 'डिजिटल एक्स-रे',
    nameEn: 'Digital X-Ray',
    descriptionNp: 'डिजिटल एक्स-रे सेवा, दैनिक उपलब्ध।',
    descriptionEn: 'Digital X-ray service, available daily.',
    icon: CoolIcons.scan,
  ),
  Department(
    id: 'dental',
    nameNp: 'दन्त उपचार',
    nameEn: 'Dental Care',
    descriptionNp: 'दाँत जाँच, सफाइ र दन्त उपचार सेवा। बिहान सिधै आउन सकिन्छ।',
    descriptionEn:
        'Dental checks, cleaning and treatment. Walk in during morning hours.',
    icon: CoolIcons.tooth,
    doctorIds: ['manish'],
  ),
  Department(
    id: 'lab',
    nameNp: 'ल्याब',
    nameEn: 'Laboratory',
    descriptionNp: 'रगत, पिसाब तथा अन्य नियमित परीक्षण। रिपोर्ट सोही दिन।',
    descriptionEn:
        'Blood, urine and other routine tests. Reports available the same day.',
    icon: CoolIcons.testTube,
  ),
  Department(
    id: 'ent',
    nameNp: 'नाक, कान, घाँटी',
    nameEn: 'ENT',
    descriptionNp:
        'नाक, कान र घाँटी सम्बन्धी जाँच तथा उपचार — महिनाको पहिलो शनिबार।',
    descriptionEn: 'Ear, nose and throat care — 1st Saturday of the month.',
    icon: CoolIcons.ear,
    doctorIds: ['bikas'],
  ),
  Department(
    id: 'psych',
    nameNp: 'मानसिक स्वास्थ्य',
    nameEn: 'Mental Health',
    descriptionNp: 'मनोरोग विशेषज्ञद्वारा मानसिक स्वास्थ्य परामर्श — महिनाको अन्तिम शनिबार।',
    descriptionEn: 'Mental health consultation with a psychiatrist — last Saturday of the month.',
    icon: CoolIcons.brain,
    doctorIds: ['suman'],
  ),
  Department(
    id: 'derma',
    nameNp: 'छाला रोग',
    nameEn: 'Dermatology',
    descriptionNp:
        'छाला सम्बन्धी समस्या, एलर्जी र उपचार परामर्श — महिनाको पहिलो शनिबार।',
    descriptionEn: 'Skin problems, allergies and treatment consultation — 1st Saturday of the month.',
    icon: CoolIcons.sparkle,
    doctorIds: ['pratibha'],
  ),
  Department(
    id: 'usg',
    nameNp: 'भिडियो एक्स-रे (USG)',
    nameEn: 'Ultrasound (USG)',
    descriptionNp: 'भिडियो एक्स-रे अर्थात् अल्ट्रासाउन्ड तथा एनोमली स्क्यान सेवा — महिनाको दुई पटक।',
    descriptionEn:
        'Video X-ray (ultrasound) and anomaly scans — twice every month.',
    icon: CoolIcons.monitor,
  ),
  Department(
    id: 'ecg',
    nameNp: 'ई.सि.जी. (ECG)',
    nameEn: 'ECG',
    descriptionNp: 'मुटुको विद्युतीय गतिविधि जाँच सेवा।',
    descriptionEn: 'Heart electrical activity test.',
    icon: CoolIcons.waveform,
  ),
  Department(
    id: 'echo',
    nameNp: 'इकोकार्डियोग्राफी',
    nameEn: 'Echocardiography',
    descriptionNp:
        'इकोकार्डियोग्राफी सेवा — मुटु विशेषज्ञसहित महिनाको अन्तिम शनिबार।',
    descriptionEn:
        'Echocardiography with a cardiologist — last Saturday of the month.',
    icon: CoolIcons.heartbeat,
    doctorIds: ['sujan'],
  ),
  Department(
    id: 'family',
    nameNp: 'परिवार नियोजन',
    nameEn: 'Family Planning',
    descriptionNp: 'परिवार नियोजन साधन तथा परामर्श सेवा।',
    descriptionEn: 'Family planning methods and counselling.',
    icon: CoolIcons.usersThree,
    doctorIds: ['sunita'],
  ),
  Department(
    id: 'physio',
    nameNp: 'फिजियोथेरापी',
    nameEn: 'Physiotherapy',
    descriptionNp:
        'दुखाइ र चोटपटकका लागि फिजियोथेरापी सेवा। साँझ सिधै आउन सकिन्छ।',
    descriptionEn:
        'Physiotherapy for pain and injuries. Walk in during evening hours.',
    icon: CoolIcons.personSimpleWalk,
    doctorIds: ['sarita'],
  ),
  Department(
    id: 'ortho',
    nameNp: 'हाडजोर्नी',
    nameEn: 'Orthopedics',
    descriptionNp:
        'हाड, जोर्नी र नसा सम्बन्धी जाँच तथा उपचार — महिनाको तेस्रो शनिबार।',
    descriptionEn: 'Bone, joint and nerve care — 3rd Saturday of the month.',
    icon: CoolIcons.bone,
    doctorIds: ['rajan'],
  ),
  Department(
    id: 'emergency',
    nameNp: 'आपत्कालीन सेवा',
    nameEn: 'Emergency Care',
    descriptionNp: 'क्लिनिक खुल्ने समयभर आपत्कालीन उपचार। आपत्कालमा सिधै फोन गर्नुहोस्: ०१०-५६१६०६',
    descriptionEn:
        'Emergency care during clinic hours. For urgent help, call 010-561606.',
    icon: CoolIcons.siren,
  ),
  Department(
    id: 'pharmacy',
    nameNp: 'फार्मेसी',
    nameEn: 'Pharmacy',
    descriptionNp: 'OPD नजिकै पूर्ण रूपमा उपलब्ध नैतिक फार्मेसी।',
    descriptionEn:
        'A fully stocked, ethical pharmacy right beside the OPD floor.',
    icon: CoolIcons.pill,
  ),
  Department(
    id: 'daycare',
    nameNp: 'आईसीयू तथा डे केयर',
    nameEn: 'ICU & Day Care',
    descriptionNp: 'आधुनिक उपकरण र तालिमप्राप्त नर्सिङ टिमसहितको निगरानी तथा डे केयर सेवा।',
    descriptionEn: 'Monitored care and day care with modern equipment and trained nursing staff.',
    icon: CoolIcons.bed,
  ),
];

const _shippedDoctors = <Doctor>[
  Doctor(
    id: 'ashish',
    nameNp: 'डा. आशिष श्रेष्ठ',
    nameEn: 'Dr. Ashish Shrestha',
    specialtyNp: 'सामान्य चिकित्सक',
    specialtyEn: 'General Physician',
    qualification: 'MBBS',
    departmentId: 'opd',
    availabilityNp: 'दैनिक · क्लिनिक खुल्ने समयभर',
    availabilityEn: 'Daily · All clinic hours',
    bioNp: 'सामान्य स्वास्थ्य समस्या, ज्वरो, संक्रमण तथा दीर्घ रोगको प्राथमिक उपचारमा अनुभवी।',
    bioEn: 'Experienced in primary care for common illnesses, fever, infections and chronic conditions.',
    fee: 500,
    avatar: 'assets/avatars/ashish.png',
    weekdays: {1, 2, 3, 4, 5, 6, 7},
    shifts: {SlotShift.morning, SlotShift.afternoon, SlotShift.evening},
  ),
  Doctor(
    id: 'navin',
    nameNp: 'डा. नविन अधिकारी',
    nameEn: 'Dr. Navin Adhikari',
    specialtyNp: 'भित्री रोग विशेषज्ञ',
    specialtyEn: 'Internal Medicine Specialist',
    qualification: 'MD (Internal Medicine)',
    departmentId: 'physician',
    availabilityNp: '२औँ शनिबार · दिउँसो १२–४',
    availabilityEn: '2nd Saturday · 12–4 PM',
    bioNp:
        'भित्री रोग, दीर्घ रोग व्यवस्थापन तथा स्वास्थ्य परामर्शमा विशेषज्ञता।',
    bioEn: 'Specialises in internal medicine, chronic disease management and health counselling.',
    fee: 800,
    avatar: 'assets/avatars/navin.png',
    weekdays: {1, 2, 3, 4, 5, 7},
    shifts: {SlotShift.afternoon},
    startTime: '12:00',
    endTime: '16:00',
    saturdayGroup: SaturdayGroup.second,
  ),
  Doctor(
    id: 'sunita',
    nameNp: 'डा. सुनिता तामाङ',
    nameEn: 'Dr. Sunita Tamang',
    specialtyNp: 'स्त्री रोग विशेषज्ञ',
    specialtyEn: 'Gynecologist',
    qualification: 'MS (Obs/Gyn)',
    departmentId: 'gyn',
    availabilityNp: '२औँ शनिबार · बिहान १०–२',
    availabilityEn: '2nd Saturday · 10 AM – 2 PM',
    bioNp: 'गर्भवती जाँच, स्त्री रोग परामर्श तथा परिवार नियोजन सेवामा अनुभवी।',
    bioEn: 'Experienced in antenatal care, gynecology consultations and family planning.',
    fee: 800,
    avatar: 'assets/avatars/sunita.png',
    weekdays: {6},
    shifts: {SlotShift.morning, SlotShift.afternoon},
    startTime: '10:00',
    endTime: '14:00',
    saturdayGroup: SaturdayGroup.second,
  ),
  Doctor(
    id: 'rajan',
    nameNp: 'डा. राजन कार्की',
    nameEn: 'Dr. Rajan Karki',
    specialtyNp: 'हाडजोर्नी तथा नसा रोग विशेषज्ञ',
    specialtyEn: 'Orthopedic Specialist',
    qualification: 'MS (Ortho)',
    departmentId: 'ortho',
    availabilityNp: '३औँ शनिबार · दिउँसो १२–४',
    availabilityEn: '3rd Saturday · 12–4 PM',
    bioNp: 'हाड, जोर्नी, नसा र चोटपटक सम्बन्धी उपचारमा विशेषज्ञ।',
    bioEn: 'Specialist in bone, joint, nerve and injury care.',
    fee: 800,
    avatar: 'assets/avatars/rajan.png',
    weekdays: {6},
    shifts: {SlotShift.afternoon},
    startTime: '12:00',
    endTime: '16:00',
    saturdayGroup: SaturdayGroup.third,
  ),
  Doctor(
    id: 'pratibha',
    nameNp: 'डा. प्रतिभा जोशी',
    nameEn: 'Dr. Pratibha Joshi',
    specialtyNp: 'छाला रोग विशेषज्ञ',
    specialtyEn: 'Dermatologist',
    qualification: 'MD (Dermatology)',
    departmentId: 'derma',
    availabilityNp: '१औँ शनिबार · बिहान १०–१',
    availabilityEn: '1st Saturday · 10 AM – 1 PM',
    bioNp: 'छाला संक्रमण, एलर्जी तथा सौन्दर्य सम्बन्धी उपचारमा विशेषज्ञ।',
    bioEn: 'Specialist in skin infections, allergies and cosmetic dermatology.',
    fee: 700,
    avatar: 'assets/avatars/pratibha.png',
    weekdays: {6},
    shifts: {SlotShift.morning},
    startTime: '10:00',
    endTime: '13:00',
    saturdayGroup: SaturdayGroup.first,
  ),
  Doctor(
    id: 'bikas',
    nameNp: 'डा. विकास पौडेल',
    nameEn: 'Dr. Bikas Poudel',
    specialtyNp: 'नाक, कान, घाँटी विशेषज्ञ',
    specialtyEn: 'ENT Specialist',
    qualification: 'MS (ENT)',
    departmentId: 'ent',
    availabilityNp: '१औँ शनिबार · बिहान १०–१',
    availabilityEn: '1st Saturday · 10 AM – 1 PM',
    bioNp: 'कान, नाक र घाँटी सम्बन्धी जाँच तथा शल्य उपचारमा अनुभवी।',
    bioEn: 'Experienced in ear, nose and throat evaluation and surgical care.',
    fee: 700,
    avatar: 'assets/avatars/bikas.png',
    weekdays: {6},
    shifts: {SlotShift.morning},
    startTime: '10:00',
    endTime: '13:00',
    saturdayGroup: SaturdayGroup.first,
  ),
  Doctor(
    id: 'manish',
    nameNp: 'डा. मनीष गुरुङ',
    nameEn: 'Dr. Manish Gurung',
    specialtyNp: 'दन्त चिकित्सक',
    specialtyEn: 'Dentist',
    qualification: 'BDS',
    departmentId: 'dental',
    availabilityNp: 'दैनिक · बिहान ८–१२',
    availabilityEn: 'Daily · 8 AM – 12 PM',
    bioNp: 'दाँत सफाइ, दाँत दुख्ने समस्या तथा सामान्य दन्त उपचारमा अनुभवी।',
    bioEn: 'Experienced in dental cleaning, toothache and routine dental treatment.',
    fee: 500,
    avatar: 'assets/avatars/manish.png',
    weekdays: {1, 2, 3, 4, 5, 6, 7},
    shifts: {SlotShift.morning},
    startTime: '08:00',
    endTime: '12:00',
  ),
  Doctor(
    id: 'suman',
    nameNp: 'डा. सुमन प्रसाद अधिकारी',
    nameEn: 'Dr. Suman Prasad Adhikari',
    specialtyNp: 'मनोरोग विशेषज्ञ',
    specialtyEn: 'Psychiatrist',
    qualification: 'MD (Psychiatry)',
    departmentId: 'psych',
    availabilityNp: 'अन्तिम शनिबार · दिउँसो २–५',
    availabilityEn: 'Last Saturday · 2–5 PM',
    bioNp: 'काठमाडौँबाट भ्रमणमा आउने मनोरोग विशेषज्ञ; मानसिक तनाव, चिन्ता र निद्रा समस्यामा परामर्श।',
    bioEn: 'Visiting psychiatrist from Kathmandu; consultations for stress, anxiety and sleep problems.',
    fee: 1000,
    avatar: 'assets/avatars/suman.png',
    weekdays: {6},
    shifts: {SlotShift.afternoon},
    startTime: '14:00',
    endTime: '17:00',
    saturdayGroup: SaturdayGroup.last,
    visiting: true,
  ),
  Doctor(
    id: 'sujan',
    nameNp: 'डा. सुजन शाक्य',
    nameEn: 'Dr. Sujan Shakya',
    specialtyNp: 'मुटु रोग विशेषज्ञ',
    specialtyEn: 'Cardiologist',
    qualification: 'MD (Cardiology)',
    departmentId: 'echo',
    availabilityNp: 'अन्तिम शनिबार · दिउँसो १–५',
    availabilityEn: 'Last Saturday · 1–5 PM',
    bioNp: 'सहिद गंगालाल मुटु अस्पतालबाट भ्रमणमा आउने वरिष्ठ मुटु रोग विशेषज्ञ; इकोकार्डियोग्राफी सेवा।',
    bioEn: 'Senior visiting cardiologist from Shahid Gangalal Heart Centre; echocardiography service.',
    fee: 1000,
    avatar: 'assets/avatars/sujan.png',
    weekdays: {6},
    shifts: {SlotShift.afternoon},
    startTime: '13:00',
    endTime: '17:00',
    saturdayGroup: SaturdayGroup.last,
    visiting: true,
  ),
  Doctor(
    id: 'sarita',
    nameNp: 'सरिता कार्की',
    nameEn: 'Sarita Karki',
    specialtyNp: 'फिजियोथेरापिस्ट',
    specialtyEn: 'Physiotherapist',
    qualification: 'BPT',
    departmentId: 'physio',
    availabilityNp: 'दैनिक · दिउँसो ४–७',
    availabilityEn: 'Daily · 4–7 PM',
    bioNp: 'दुखाइ व्यवस्थापन, जोर्नी चलायमान तथा पुनर्स्थापना सेवामा अनुभवी।',
    bioEn: 'Experienced in pain management, joint mobility and rehabilitation.',
    fee: 500,
    avatar: 'assets/avatars/sarita.png',
    weekdays: {1, 2, 3, 4, 5, 6, 7},
    shifts: {SlotShift.afternoon, SlotShift.evening},
    startTime: '16:00',
    endTime: '19:00',
  ),
];

const _shippedSpecialistOrder = <String>[
  'derma',
  'ent',
  'physician',
  'gyn',
  'ortho',
  'psych',
  'echo',
];

Set<String>? _saturdayOverrideFor(DateTime date) =>
    saturdayScheduleOverrides[saturdayDateKey(date)];

bool doctorScheduledOn(Doctor doctor, DateTime date) {
  final override = _saturdayOverrideFor(date);
  if (override != null) return override.contains(doctor.id);
  return doctor.saturdayGroup != null &&
      doctor.saturdayGroup == saturdayGroupForDate(date);
}

List<Doctor> saturdayDoctorsForDate(DateTime date) {
  final override = _saturdayOverrideFor(date);
  final doctorsForDate = override != null
      ? doctors.where((doctor) => override.contains(doctor.id))
      : doctors.where(
          (doctor) =>
              doctor.saturdayGroup != null &&
              doctor.saturdayGroup == saturdayGroupForDate(date),
        );
  final result = doctorsForDate.toList()..sort(_saturdayDoctorOrder);
  return result;
}

List<Doctor> doctorsForSaturdayGroup(SaturdayGroup group) {
  final result =
      doctors.where((doctor) => doctor.saturdayGroup == group).toList()
        ..sort(_saturdayDoctorOrder);
  return result;
}

int _saturdayDoctorOrder(Doctor a, Doctor b) {
  final aIndex = saturdaySpecialistDepartmentIds.indexOf(a.departmentId);
  final bIndex = saturdaySpecialistDepartmentIds.indexOf(b.departmentId);
  if (aIndex != bIndex) return aIndex.compareTo(bIndex);
  return a.id.compareTo(b.id);
}

Doctor? doctorById(String? id) {
  if (id == null) return null;
  for (final doctor in doctors) {
    if (doctor.id == id) return doctor;
  }
  return null;
}

Department departmentById(String id) {
  return departments.firstWhere((department) => department.id == id);
}

Department? departmentByIdOrNull(String? id) {
  if (id == null) return null;
  for (final department in departments) {
    if (department.id == id) return department;
  }
  return null;
}

List<Doctor> doctorsForDepartment(String departmentId) {
  return doctors
      .where((doctor) => doctor.departmentId == departmentId)
      .toList();
}

List<Department> get bookableDepartments => [
  for (final id in saturdaySpecialistDepartmentIds) departmentById(id),
];

List<Doctor> get specialistDoctors {
  final result = doctors.where((doctor) => doctor.isSpecialist).toList()
    ..sort((a, b) {
      final groupCompare = a.saturdayGroup!.index.compareTo(
        b.saturdayGroup!.index,
      );
      return groupCompare != 0 ? groupCompare : _saturdayDoctorOrder(a, b);
    });
  return result;
}


/// The clinic's own catalog, and the single place any of it is read from.
///
/// The shipped defaults below are exactly what
/// `backend/pb_migrations/1766300010_seed_catalog.js` inserts — that file is
/// generated from this one, so the app and a fresh server start from the same
/// facts and an offline first run still shows the real clinic. Once the backend
/// answers, [Catalog.apply] replaces everything and the server is the source of
/// truth from then on.
///
/// Nothing here describes a patient. Profiles, bookings and notifications only
/// ever come from the server, so there is no invented history to fall back to.
abstract final class Catalog {
  Catalog._();

  static List<Department> departments = _shippedDepartments;
  static List<Doctor> doctors = _shippedDoctors;
  static List<String> specialistOrder = _shippedSpecialistOrder;
  static List<Notice> notices = const [];
  static Map<String, Set<String>> saturdayOverrides = const {};

  /// True once the server has supplied the catalog, so the UI can tell a
  /// shipped default apart from what the clinic actually has configured.
  static bool served = false;

  static void apply({
    List<Department>? departments,
    List<Doctor>? doctors,
    List<String>? specialistOrder,
    List<Notice>? notices,
    Map<String, Set<String>>? saturdayOverrides,
  }) {
    if (departments != null) Catalog.departments = departments;
    if (doctors != null) Catalog.doctors = doctors;
    if (specialistOrder != null) Catalog.specialistOrder = specialistOrder;
    if (notices != null) Catalog.notices = notices;
    if (saturdayOverrides != null) {
      Catalog.saturdayOverrides = saturdayOverrides;
    }
    served = true;
  }

  static void reset() {
    departments = _shippedDepartments;
    doctors = _shippedDoctors;
    specialistOrder = _shippedSpecialistOrder;
    notices = const [];
    saturdayOverrides = const {};
    served = false;
  }
}

List<Department> get departments => Catalog.departments;
List<Doctor> get doctors => Catalog.doctors;
List<Notice> get notices => Catalog.notices;
List<String> get saturdaySpecialistDepartmentIds => Catalog.specialistOrder;
Map<String, Set<String>> get saturdayScheduleOverrides =>
    Catalog.saturdayOverrides;
