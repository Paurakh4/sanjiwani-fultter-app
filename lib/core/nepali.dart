import 'package:characters/characters.dart';

const _digits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];

const _weekdays = [
  'आइतबार',
  'सोमबार',
  'मङ्गलबार',
  'बुधबार',
  'बिहीबार',
  'शुक्रबार',
  'शनिबार',
];

const _weekdaysShort = ['आइत', 'सोम', 'मङ्गल', 'बुध', 'बिही', 'शुक्र', 'शनि'];

String nepDigits(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= 48 && rune <= 57) {
      buffer.write(_digits[rune - 48]);
    } else {
      buffer.write(String.fromCharCode(rune));
    }
  }
  return buffer.toString();
}

String asciiDigits(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= 48 && rune <= 57) {
      buffer.writeCharCode(rune);
    } else if (rune >= 0x0966 && rune <= 0x096F) {
      buffer.writeCharCode(48 + rune - 0x0966);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

String nepNum(Object value) => nepDigits(value.toString());

String nepWeekday(DateTime date) => _weekdays[date.weekday % 7];

String nepWeekdayShort(DateTime date) => _weekdaysShort[date.weekday % 7];

String slotLabel(String slot) {
  final parts = slot.split(':');
  final hour = int.parse(parts[0]);
  final minute = parts[1];
  final prefix = hour < 12
      ? 'बिहान'
      : hour < 17
      ? 'दिउँसो'
      : hour < 20
      ? 'साँझ'
      : 'राति';
  final h12 = hour > 12 ? hour - 12 : hour;
  return '$prefix ${nepNum(h12)}:${nepDigits(minute)}';
}

String slotTime(String slot) {
  final parts = slot.split(':');
  final hour = int.parse(parts[0]);
  final minute = parts[1];
  final h12 = hour > 12 ? hour - 12 : hour;
  return '${nepNum(h12)}:${nepDigits(minute)}';
}

String initials(String name) {
  final cleaned = name.replaceFirst('डा. ', '').replaceFirst('Dr. ', '').trim();
  if (cleaned.isEmpty) return '?';
  final firstWord = cleaned.split(RegExp(r'\s+')).first;
  return firstWord.characters.first;
}
