import 'package:battar_sanjibani/core/bs_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Anchors verified against the bundled Bikram Sambat table.
  final baishakh1 = DateTime(2026, 4, 14); // 1 Baishakh 2083 — Nepali new year
  final kartik28 = DateTime(2026, 11, 14); // 28 Kartik 2083
  final poush17 = DateTime(2026, 1, 1); // 17 Poush 2082

  group('bsDateNp', () {
    test('renders day, month and year in Nepali digits', () {
      expect(bsDateNp(kartik28), '२८ कात्तिक २०८३');
      expect(bsDateNp(baishakh1), '१ बैशाख २०८३');
      expect(bsDateNp(poush17), '१७ पुस २०८२');
    });
  });

  test('bsDateNpShort drops the year', () {
    expect(bsDateNpShort(kartik28), '२८ कात्तिक');
    expect(bsDateNpShort(poush17), '१७ पुस');
  });

  test('month names agree across the two scripts', () {
    expect(bsMonthNp(kartik28), 'कात्तिक');
    expect(bsMonthEn(kartik28), 'Kartik');
    expect(bsMonthEnShort(kartik28), 'Kar');
    expect(bsMonthEn(poush17), 'Poush');
    expect(bsMonthEnShort(baishakh1), 'Bai');
  });

  test('day and year parts match the composed string', () {
    expect(bsDay(kartik28), 28);
    expect(bsDayNp(kartik28), '२८');
    expect(bsYearNp(kartik28), '२०८३');
    expect(bsYearNp(poush17), '२०८२');
  });

  test('the BS year lags the AD year across New Year', () {
    expect(bsYearNp(DateTime(2026, 12, 31)), '२०८३');
    expect(bsDay(DateTime(2027, 1, 1)), 17);
    expect(bsMonthEn(DateTime(2027, 1, 1)), 'Poush');
  });
}
