import 'package:bikram_sambat/bikram_sambat.dart';

import 'nepali.dart' as np;

const _monthsNp = [
  'बैशाख',
  'जेठ',
  'असार',
  'साउन',
  'भदौ',
  'असोज',
  'कात्तिक',
  'मंसिर',
  'पुस',
  'माघ',
  'फागुन',
  'चैत',
];

const _monthsNpShort = [
  'बैशाख',
  'जेठ',
  'असार',
  'साउन',
  'भदौ',
  'असोज',
  'कात्तिक',
  'मंसिर',
  'पुस',
  'माघ',
  'फागुन',
  'चैत',
];

const _monthsEn = [
  'Baishakh',
  'Jestha',
  'Ashadh',
  'Shrawan',
  'Bhadra',
  'Ashwin',
  'Kartik',
  'Mangsir',
  'Poush',
  'Magh',
  'Falgun',
  'Chaitra',
];

const _monthsEnShort = [
  'Bai',
  'Jes',
  'Ash',
  'Shr',
  'Bha',
  'Asw',
  'Kar',
  'Man',
  'Pou',
  'Mag',
  'Fal',
  'Cha',
];

BikramSambat _bs(DateTime value) => value.toBikramSambat();

String bsDateNp(DateTime value) {
  final bs = _bs(value);
  return '${np.nepNum(bs.day)} ${_monthsNp[bs.month - 1]} ${np.nepNum(bs.year)}';
}

String bsDateNpShort(DateTime value) {
  final bs = _bs(value);
  return '${np.nepNum(bs.day)} ${_monthsNpShort[bs.month - 1]}';
}

String bsMonthNp(DateTime value) => _monthsNp[_bs(value).month - 1];

String bsMonthNpShort(DateTime value) => _monthsNpShort[_bs(value).month - 1];

String bsDateEn(DateTime value) {
  final bs = _bs(value);
  return '${bs.day} ${_monthsEn[bs.month - 1]} ${bs.year}';
}

String bsDateEnShort(DateTime value) {
  final bs = _bs(value);
  return '${bs.day} ${_monthsEnShort[bs.month - 1]}';
}

String bsMonthEn(DateTime value) => _monthsEn[_bs(value).month - 1];

String bsMonthEnShort(DateTime value) => _monthsEnShort[_bs(value).month - 1];

String bsWeekdayNp(DateTime value) => np.nepWeekday(value);

String bsWeekdayNpShort(DateTime value) => np.nepWeekdayShort(value);

String bsYearNp(DateTime value) => np.nepNum(_bs(value).year);

String bsDayNp(DateTime value) => np.nepNum(_bs(value).day);

int bsDay(DateTime value) => _bs(value).day;
