import 'l10n.dart';

abstract final class Clinic {
  static const nameNp = 'बट्टार सञ्जीवनी पॉलीक्लिनिक';
  static const nameEn = 'Battar Sanjibani Polyclinic';
  static const shortNameNp = 'बट्टार सञ्जीवनी';
  static const shortNameEn = 'Battar Sanjibani';

  static const addressNp = 'विदुर-२, बट्टार, संगमचोक, नुवाकोट';
  static const addressEn = 'Bidur 2, Battar, Sangamchowk, Nuwakot';

  static const phonePrimary = '010561606';
  static const phonePrimaryDisplay = '010-561606';
  static const phoneMobile = '9841595025';
  static const phoneMobileDisplay = '9841595025';
  static const whatsapp = '9779704513324';
  static const whatsappDisplay = '9704513324';
  static const email = 'info@sanjiwani.com.np';
  static const website = 'www.sanjiwani.com.np';
  static const websiteUrl = 'https://www.sanjiwani.com.np';
  static const facebookUrl = 'https://www.facebook.com/sanjiwanipolyclinic';
  static const mapsUrl =
      'https://www.google.com/maps/search/?api=1&query=Battar+Sanjibani+Polyclinic+Sangamchowk+Bidur+Nuwakot';

  static const openHour = 7;
  static const closeHour = 20;
  static const specialistStartHour = 10;
  static const specialistEndHour = 17;

  static String name(AppLanguage language) =>
      language == AppLanguage.en ? nameEn : nameNp;

  static String shortName(AppLanguage language) =>
      language == AppLanguage.en ? shortNameEn : shortNameNp;

  static String address(AppLanguage language) =>
      language == AppLanguage.en ? addressEn : addressNp;

  static int closeHourFor(DateTime date) => closeHour;

  static bool isOpenAt(DateTime date) =>
      date.hour >= openHour && date.hour < closeHourFor(date);
}
