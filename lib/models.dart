import 'package:flutter/material.dart';

import 'core/l10n.dart';
import 'core/saturday_schedule.dart';

enum SlotShift { morning, afternoon, evening }

enum AppointmentStatus { booked, completed, cancelled }

enum RecordKind { visit, lab }

class PatientProfile {
  const PatientProfile({
    required this.name,
    required this.phone,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.address,
    required this.patientId,
  });

  final String name;
  final String phone;
  final String age;
  final String gender;
  final String bloodGroup;
  final String address;
  final String patientId;

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.first.isEmpty ? '' : parts.first;
  }

  PatientProfile copyWith({
    String? name,
    String? phone,
    String? age,
    String? gender,
    String? bloodGroup,
    String? address,
  }) {
    return PatientProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      patientId: patientId,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'age': age,
    'gender': gender,
    'bloodGroup': bloodGroup,
    'address': address,
    'patientId': patientId,
  };

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      age: json['age'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      bloodGroup: json['bloodGroup'] as String? ?? '',
      address: json['address'] as String? ?? '',
      patientId: json['patientId'] as String? ?? 'BSP-0000',
    );
  }
}

class Department {
  const Department({
    required this.id,
    required this.nameNp,
    required this.nameEn,
    required this.descriptionNp,
    required this.descriptionEn,
    required this.icon,
    this.doctorIds = const [],
  });

  final String id;
  final String nameNp;
  final String nameEn;
  final String descriptionNp;
  final String descriptionEn;
  final IconData icon;
  final List<String> doctorIds;

  String name(AppLanguage language) =>
      language == AppLanguage.en ? nameEn : nameNp;

  String get displayName => '$nameEn / $nameNp';

  String description(AppLanguage language) =>
      language == AppLanguage.en ? descriptionEn : descriptionNp;
}

class Doctor {
  const Doctor({
    required this.id,
    required this.nameNp,
    required this.nameEn,
    required this.specialtyNp,
    required this.specialtyEn,
    required this.qualification,
    required this.departmentId,
    required this.availabilityNp,
    required this.availabilityEn,
    required this.bioNp,
    required this.bioEn,
    required this.fee,
    required this.avatar,
    required this.weekdays,
    required this.shifts,
    this.startTime,
    this.endTime,
    this.saturdayGroup,
    this.visiting = false,
  });

  final String id;
  final String nameNp;
  final String nameEn;
  final String specialtyNp;
  final String specialtyEn;
  final String qualification;
  final String departmentId;
  final String availabilityNp;
  final String availabilityEn;
  final String bioNp;
  final String bioEn;
  final int fee;
  final String avatar;

  /// DateTime weekday values (Mon = 1 … Sun = 7).
  final Set<int> weekdays;
  final Set<SlotShift> shifts;

  /// Optional consultation window ("HH:mm", end exclusive) used for slots.
  final String? startTime;
  final String? endTime;

  /// The monthly Saturday rotation for this specialist.
  final SaturdayGroup? saturdayGroup;

  final bool visiting;

  String name(AppLanguage language) =>
      language == AppLanguage.en ? nameEn : nameNp;

  String get displayName => '$nameEn / $nameNp';

  String specialty(AppLanguage language) =>
      language == AppLanguage.en ? specialtyEn : specialtyNp;

  String get displaySpecialty => '$specialtyEn / $specialtyNp';

  String availability(AppLanguage language) =>
      language == AppLanguage.en ? availabilityEn : availabilityNp;

  String bio(AppLanguage language) =>
      language == AppLanguage.en ? bioEn : bioNp;

  bool get isSpecialist => saturdayGroup != null;

  bool get allClinicHours =>
      weekdays.length == 7 && shifts.length == SlotShift.values.length;
}

class Notice {
  const Notice({
    required this.id,
    required this.tag,
    required this.title,
    required this.body,
    required this.dateLabel,
    required this.createdAt,
    this.doctorId,
  });

  final String id;
  final String tag;
  final String title;
  final String body;
  final String dateLabel;

  /// Specialist announcement: tapping it opens a booking pre-filled for this
  /// doctor.
  final String? doctorId;

  /// When the clinic published it, which is what orders the notifications tab.
  final DateTime createdAt;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.departmentId,
    required this.departmentName,
    required this.doctorName,
    required this.date,
    required this.slot,
    required this.patientName,
    required this.phone,
    required this.fee,
    required this.status,
    required this.createdAt,
    this.doctorId,
  });

  final String id;
  final String departmentId;
  final String departmentName;
  final String? doctorId;
  final String doctorName;
  final DateTime date;
  final String slot;
  final String patientName;
  final String phone;
  final int fee;
  final AppointmentStatus status;
  final DateTime createdAt;

  bool get isUpcoming {
    if (status != AppointmentStatus.booked) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return !target.isBefore(today);
  }

  Appointment copyWith({AppointmentStatus? status, DateTime? date}) {
    return Appointment(
      id: id,
      departmentId: departmentId,
      departmentName: departmentName,
      doctorId: doctorId,
      doctorName: doctorName,
      date: date ?? this.date,
      slot: slot,
      patientName: patientName,
      phone: phone,
      fee: fee,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'departmentId': departmentId,
    'departmentName': departmentName,
    'doctorId': doctorId,
    'doctorName': doctorName,
    'date': date.toIso8601String(),
    'slot': slot,
    'patientName': patientName,
    'phone': phone,
    'fee': fee,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      departmentName: json['departmentName'] as String? ?? '',
      doctorId: json['doctorId'] as String?,
      doctorName: json['doctorName'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      slot: json['slot'] as String? ?? '07:00',
      patientName: json['patientName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      fee: (json['fee'] as num?)?.toInt() ?? 0,
      status: AppointmentStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => AppointmentStatus.booked,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.kind,
    this.titleEn,
    this.bodyEn,
    this.read = false,
    this.refId,
  });

  final String id;
  final String title;
  final String body;
  final String? titleEn;
  final String? bodyEn;
  final DateTime time;
  final String kind;
  final bool read;
  final String? refId;

  String displayTitle(AppLanguage language) =>
      language == AppLanguage.en ? (titleEn ?? title) : title;

  String displayBody(AppLanguage language) =>
      language == AppLanguage.en ? (bodyEn ?? body) : body;

  AppNotification copyWith({bool? read, String? refId}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      titleEn: titleEn,
      bodyEn: bodyEn,
      time: time,
      kind: kind,
      read: read ?? this.read,
      refId: refId ?? this.refId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'titleEn': titleEn,
    'bodyEn': bodyEn,
    'time': time.toIso8601String(),
    'kind': kind,
    'read': read,
    'refId': refId,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      titleEn: json['titleEn'] as String?,
      bodyEn: json['bodyEn'] as String?,
      time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      kind: json['kind'] as String? ?? 'notice',
      read: json['read'] as bool? ?? false,
      refId: json['refId'] as String?,
    );
  }
}

class Medicine {
  const Medicine({required this.name, required this.dose, this.duration = ''});

  final String name;
  final String dose;
  final String duration;
}

class LabResult {
  const LabResult({
    required this.name,
    required this.value,
    required this.unit,
    required this.reference,
  });

  final String name;
  final String value;
  final String unit;
  final String reference;
}

class VisitRecord {
  const VisitRecord({
    required this.id,
    required this.date,
    required this.kind,
    required this.title,
    required this.department,
    required this.doctor,
    required this.summary,
    this.vitals = const {},
    this.notes = const [],
    this.medicines = const [],
    this.labs = const [],
  });

  final String id;
  final DateTime date;
  final RecordKind kind;
  final String title;
  final String department;
  final String doctor;
  final String summary;
  final Map<String, String> vitals;
  final List<String> notes;
  final List<Medicine> medicines;
  final List<LabResult> labs;
}
