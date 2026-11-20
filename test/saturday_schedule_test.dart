import 'package:battar_sanjibani/core/saturday_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // November 2026 has four Saturdays (7, 14, 21, 28);
  // August 2026 has five (1, 8, 15, 22, 29).
  test('dateOnly strips the time without shifting the day', () {
    expect(dateOnly(DateTime(2026, 11, 14, 23, 59, 59)), DateTime(2026, 11, 14));
  });

  group('saturdayGroupForDate', () {
    test('maps all four positions in a four-Saturday month', () {
      expect(saturdayGroupForDate(DateTime(2026, 11, 7)), SaturdayGroup.first);
      expect(saturdayGroupForDate(DateTime(2026, 11, 14)), SaturdayGroup.second);
      expect(saturdayGroupForDate(DateTime(2026, 11, 21)), SaturdayGroup.third);
      expect(saturdayGroupForDate(DateTime(2026, 11, 28)), SaturdayGroup.last);
    });

    test('the fourth of five Saturdays belongs to no group', () {
      expect(saturdayGroupForDate(DateTime(2026, 8, 1)), SaturdayGroup.first);
      expect(saturdayGroupForDate(DateTime(2026, 8, 15)), SaturdayGroup.third);
      expect(saturdayGroupForDate(DateTime(2026, 8, 22)), isNull);
      expect(saturdayGroupForDate(DateTime(2026, 8, 29)), SaturdayGroup.last);
    });

    test('non-Saturdays have no group', () {
      expect(saturdayGroupForDate(DateTime(2026, 11, 13)), isNull);
      expect(saturdayGroupForDate(DateTime(2026, 11, 15)), isNull);
    });
  });

  group('isLastSaturdayOfMonth', () {
    test('is true only for the Saturday that ends the month', () {
      expect(isLastSaturdayOfMonth(DateTime(2026, 11, 28)), isTrue);
      expect(isLastSaturdayOfMonth(DateTime(2026, 8, 29)), isTrue);
      expect(isLastSaturdayOfMonth(DateTime(2026, 8, 22)), isFalse);
    });

    test('is false for a non-Saturday even in the final week', () {
      expect(isLastSaturdayOfMonth(DateTime(2026, 11, 27)), isFalse);
    });
  });

  group('nextSaturdayFrom', () {
    test('always lands after the given date', () {
      expect(nextSaturdayFrom(DateTime(2026, 11, 14)), DateTime(2026, 11, 21));
      expect(nextSaturdayFrom(DateTime(2026, 11, 13)), DateTime(2026, 11, 14));
    });

    test('ignores the time of day', () {
      expect(
        nextSaturdayFrom(DateTime(2026, 11, 14, 23, 30)),
        DateTime(2026, 11, 21),
      );
    });
  });

  group('nextBookableSaturday', () {
    test('keeps today while the specialist window is open', () {
      expect(
        nextBookableSaturday(DateTime(2026, 11, 14, 16, 59)),
        DateTime(2026, 11, 14),
      );
    });

    test('rolls over the moment the window closes at 17:00', () {
      expect(
        nextBookableSaturday(DateTime(2026, 11, 14, 17)),
        DateTime(2026, 11, 21),
      );
    });

    test('a weekday returns the coming Saturday', () {
      expect(nextBookableSaturday(DateTime(2026, 11, 13)), DateTime(2026, 11, 14));
    });
  });

  group('nextSaturdayForGroup', () {
    test('skips to the same position in a later month', () {
      expect(
        nextSaturdayForGroup(SaturdayGroup.third, from: DateTime(2026, 11, 21)),
        DateTime(2026, 12, 19),
      );
    });

    test('never returns an unstaffed fourth Saturday', () {
      final found = nextSaturdayForGroup(
        SaturdayGroup.third,
        from: DateTime(2026, 8, 1),
      );
      expect(saturdayGroupForDate(found), SaturdayGroup.third);
      expect(found.isAfter(DateTime(2026, 8, 1)), isTrue);
    });
  });

  test('saturdayDateKey is zero-padded and time-independent', () {
    expect(saturdayDateKey(DateTime(2026, 11, 7, 9, 30)), '2026-11-07');
    expect(saturdayDateKey(DateTime(2027, 1, 2)), '2027-01-02');
  });
}
