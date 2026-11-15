import 'package:flutter/material.dart';

enum AppPalette {
  green(
    id: 'green',
    labelNp: 'सेज हरियो',
    labelEn: 'Sage green',
    seed: Color(0xFF4F6F58),
    strong: Color(0xFF3D6B52),
    textLight: Color(0xFF345C46),
    textDark: Color(0xFFA9D6BC),
    softLight: Color(0xFFDFEDE3),
    onSoftLight: Color(0xFF143526),
    softDark: Color(0xFF1B3328),
    onSoftDark: Color(0xFFE2F2E7),
  ),
  teal(
    id: 'teal',
    labelNp: 'टिल',
    labelEn: 'Teal',
    seed: Color(0xFF00796B),
    strong: Color(0xFF00695C),
    textLight: Color(0xFF00635A),
    textDark: Color(0xFF7CE0D3),
    softLight: Color(0xFFD2F2ED),
    onSoftLight: Color(0xFF00352F),
    softDark: Color(0xFF073D37),
    onSoftDark: Color(0xFFE3FFF9),
  ),
  blue(
    id: 'blue',
    labelNp: 'निलो',
    labelEn: 'Blue',
    seed: Color(0xFF1565C0),
    strong: Color(0xFF1559A6),
    textLight: Color(0xFF124A8B),
    textDark: Color(0xFF9CC7FF),
    softLight: Color(0xFFD8E8FF),
    onSoftLight: Color(0xFF06264A),
    softDark: Color(0xFF0B2F52),
    onSoftDark: Color(0xFFE6F1FF),
  ),
  purple(
    id: 'purple',
    labelNp: 'बैगनी',
    labelEn: 'Purple',
    seed: Color(0xFF6750A4),
    strong: Color(0xFF5B3D9E),
    textLight: Color(0xFF52378F),
    textDark: Color(0xFFCEBDFF),
    softLight: Color(0xFFE9DDFF),
    onSoftLight: Color(0xFF221044),
    softDark: Color(0xFF2C1B4D),
    onSoftDark: Color(0xFFF1E8FF),
  ),
  orange(
    id: 'orange',
    labelNp: 'सुन्तला',
    labelEn: 'Orange',
    seed: Color(0xFFB45309),
    strong: Color(0xFF9A4708),
    textLight: Color(0xFF8B3F06),
    textDark: Color(0xFFFFBE7D),
    softLight: Color(0xFFFFE4CB),
    onSoftLight: Color(0xFF3A1B00),
    softDark: Color(0xFF4A2504),
    onSoftDark: Color(0xFFFFF0E2),
  ),
  rose(
    id: 'rose',
    labelNp: 'गुलाबी',
    labelEn: 'Rose',
    seed: Color(0xFFB3254A),
    strong: Color(0xFF9E1F42),
    textLight: Color(0xFF8C1A39),
    textDark: Color(0xFFFFB3C6),
    softLight: Color(0xFFFFDCE5),
    onSoftLight: Color(0xFF42000F),
    softDark: Color(0xFF531325),
    onSoftDark: Color(0xFFFFE5EB),
  ),
  graphite(
    id: 'graphite',
    labelNp: 'ग्रेफाइट',
    labelEn: 'Graphite',
    seed: Color(0xFF4F5459),
    strong: Color(0xFF363B40),
    textLight: Color(0xFF2D3236),
    textDark: Color(0xFFC3C8CD),
    softLight: Color(0xFFE1E4E7),
    onSoftLight: Color(0xFF171B1E),
    softDark: Color(0xFF2A2E32),
    onSoftDark: Color(0xFFE4E7E9),
  ),
  pixel(
    id: 'pixel',
    labelNp: 'पिक्सेल',
    labelEn: 'Pixel',
    seed: Color(0xFF1A73E8),
    strong: Color(0xFF0B57D0),
    textLight: Color(0xFF174EA6),
    textDark: Color(0xFFA8C7FA),
    softLight: Color(0xFFD3E3FD),
    onSoftLight: Color(0xFF041E49),
    softDark: Color(0xFF0E2A47),
    onSoftDark: Color(0xFFD3E3FD),
  ),
  material(
    id: 'material',
    labelNp: 'मटेरियल यू',
    labelEn: 'Material You',
    seed: Color(0xFF6750A4),
    strong: Color(0xFF6750A4),
    textLight: Color(0xFF4F378B),
    textDark: Color(0xFFD0BCFF),
    softLight: Color(0xFFEADDFF),
    onSoftLight: Color(0xFF21005D),
    softDark: Color(0xFF4A4458),
    onSoftDark: Color(0xFFEADDFF),
  );

  const AppPalette({
    required this.id,
    required this.labelNp,
    required this.labelEn,
    required this.seed,
    required this.strong,
    required this.textLight,
    required this.textDark,
    required this.softLight,
    required this.onSoftLight,
    required this.softDark,
    required this.onSoftDark,
  });

  final String id;
  final String labelNp;
  final String labelEn;
  final Color seed;

  /// Saturated accent used behind white icons and labels.
  final Color strong;

  final Color textLight;
  final Color textDark;
  final Color softLight;
  final Color onSoftLight;
  final Color softDark;
  final Color onSoftDark;

  Color onStrong(bool isDark) => Colors.white;
}
