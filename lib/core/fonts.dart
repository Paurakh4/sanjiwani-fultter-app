enum NepaliFont {
  anek(
    family: 'AnekDevanagari',
    label: 'Anek Devanagari',
    labelNp: 'अनेक देवनागरी',
  ),
  mukta(family: 'Mukta', label: 'Mukta', labelNp: 'मुक्ता'),
  hind(family: 'Hind', label: 'Hind', labelNp: 'हिन्द'),
  baloo2(family: 'Baloo2', label: 'Baloo 2', labelNp: 'बालू २');

  const NepaliFont({
    required this.family,
    required this.label,
    required this.labelNp,
  });

  final String family;
  final String label;
  final String labelNp;
}

enum EnglishFont {
  poppins(family: 'Poppins', label: 'Poppins'),
  inter(family: 'Inter', label: 'Inter');

  const EnglishFont({required this.family, required this.label});

  final String family;
  final String label;
}

class AppFonts {
  const AppFonts({
    this.nepaliHeading = NepaliFont.anek,
    this.nepaliBody = NepaliFont.mukta,
    this.english = EnglishFont.poppins,
  });

  final NepaliFont nepaliHeading;
  final NepaliFont nepaliBody;
  final EnglishFont english;

  String get primary => english.family;

  List<String> get headingChain => [
    english.family,
    nepaliHeading.family,
    'Roboto',
  ];

  List<String> get bodyChain => [english.family, nepaliBody.family, 'Roboto'];
}
