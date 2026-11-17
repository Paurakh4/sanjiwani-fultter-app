enum SaturdayGroup { first, second, third, last }

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool isLastSaturdayOfMonth(DateTime value) {
  final date = dateOnly(value);
  if (date.weekday != DateTime.saturday) return false;
  return date.add(const Duration(days: 7)).month != date.month;
}

SaturdayGroup? saturdayGroupForDate(DateTime value) {
  final date = dateOnly(value);
  if (date.weekday != DateTime.saturday) return null;
  final ordinal = ((date.day - 1) ~/ 7) + 1;
  return switch (ordinal) {
    1 => SaturdayGroup.first,
    2 => SaturdayGroup.second,
    3 => SaturdayGroup.third,
    _ when isLastSaturdayOfMonth(date) => SaturdayGroup.last,
    _ => null,
  };
}

DateTime nextSaturdayFrom(DateTime from) {
  var date = dateOnly(from).add(const Duration(days: 1));
  while (date.weekday != DateTime.saturday) {
    date = date.add(const Duration(days: 1));
  }
  return date;
}

/// The Saturday a patient can still book: today if it is Saturday and the
/// specialist window (until 17:00) has not closed, otherwise the next one.
DateTime nextBookableSaturday(DateTime now) {
  if (now.weekday == DateTime.saturday && now.hour < 17) {
    return dateOnly(now);
  }
  return nextSaturdayFrom(now);
}

DateTime nextSaturdayForGroup(SaturdayGroup group, {DateTime? from}) {
  var date = nextSaturdayFrom(from ?? DateTime.now());
  for (var i = 0; i < 12; i++) {
    if (saturdayGroupForDate(date) == group) return date;
    date = date.add(const Duration(days: 7));
  }
  return date;
}

String saturdayDateKey(DateTime value) {
  final date = dateOnly(value);
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
