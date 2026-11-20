// One-shot: dumps the catalog currently hardcoded in lib/data/demo_data.dart so
// it can become the PocketBase seed migration. Run with:
//   flutter test test/_export_catalog_seed_test.dart --reporter=quiet
import 'dart:convert';
import 'dart:io';

import 'package:battar_sanjibani/core/clinic.dart';
import 'package:battar_sanjibani/data/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('export catalog', () {
    // Reverse-map each IconData codepoint back to its CoolIcons member name so
    // the backend can store a stable label instead of a raw codepoint.
    final iconsSource = File('lib/core/icons.dart').readAsStringSync();
    final byCode = <int, String>{};
    for (final match in RegExp(
      r'static const IconData (\w+) = IconData\(\s*0x([0-9a-fA-F]+)',
    ).allMatches(iconsSource)) {
      byCode[int.parse(match.group(2)!, radix: 16)] = match.group(1)!;
    }

    final out = <String, dynamic>{
      'clinic': {
        'nameNp': Clinic.nameNp,
        'nameEn': Clinic.nameEn,
        'shortNameNp': Clinic.shortNameNp,
        'shortNameEn': Clinic.shortNameEn,
        'addressNp': Clinic.addressNp,
        'addressEn': Clinic.addressEn,
        'phonePrimary': Clinic.phonePrimary,
        'phoneMobile': Clinic.phoneMobile,
        'whatsapp': Clinic.whatsapp,
        'email': Clinic.email,
        'website': Clinic.website,
        'facebookUrl': Clinic.facebookUrl,
        'mapsUrl': Clinic.mapsUrl,
        'openHour': Clinic.openHour,
        'closeHour': Clinic.closeHour,
        'specialistCutoffHour': 17,
      },
      'departments': [
        for (final d in departments)
          {
            'code': d.id,
            'nameNp': d.nameNp,
            'nameEn': d.nameEn,
            'descNp': d.descriptionNp,
            'descEn': d.descriptionEn,
            'icon': byCode[d.icon.codePoint] ?? '',
            'sortOrder': departments.indexOf(d),
            if (saturdaySpecialistDepartmentIds.contains(d.id))
              'specialistOrder':
                  saturdaySpecialistDepartmentIds.indexOf(d.id),
          },
      ],
      'doctors': [
        for (final doc in doctors)
          {
            'code': doc.id,
            'nameNp': doc.nameNp,
            'nameEn': doc.nameEn,
            'specialtyNp': doc.specialtyNp,
            'specialtyEn': doc.specialtyEn,
            'qualification': doc.qualification,
            'departmentCode': doc.departmentId,
            'fee': doc.fee,
            'startTime': doc.startTime,
            'endTime': doc.endTime,
            'weekdays': doc.weekdays.toList(),
            'shifts': doc.shifts.map((s) => s.name).toList(),
            'saturdayGroup': doc.saturdayGroup?.name,
            'visiting': doc.visiting,
            'avatar': doc.avatar,
            'bioNp': doc.bioNp,
            'bioEn': doc.bioEn,
            'availabilityNp': doc.availabilityNp,
            'availabilityEn': doc.availabilityEn,
          },
      ],
      'notices': [
        for (final n in notices)
          {
            'title': n.title,
            'body': n.body,
            'tag': n.tag,
            'dateLabel': n.dateLabel,
            'doctorCode': n.doctorId,
          },
      ],
      'bookableDepartmentCodes': saturdaySpecialistDepartmentIds,
    };

    File('/tmp/bsp_seed.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(out),
    );
    stderr.writeln(
      'wrote ${out['departments'].length} departments, '
      '${out['doctors'].length} doctors, ${out['notices'].length} notices',
    );
  });
}
