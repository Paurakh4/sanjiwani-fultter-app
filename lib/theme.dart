import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'core/fonts.dart';
import 'core/palette.dart';
import 'core/tokens.dart';

class BrandTokens extends ThemeExtension<BrandTokens> {
  const BrandTokens({
    required this.strong,
    required this.onStrong,
    required this.soft,
    required this.onSoft,
    required this.text,
  });

  final Color strong;
  final Color onStrong;
  final Color soft;
  final Color onSoft;
  final Color text;

  @override
  BrandTokens copyWith({
    Color? strong,
    Color? onStrong,
    Color? soft,
    Color? onSoft,
    Color? text,
  }) {
    return BrandTokens(
      strong: strong ?? this.strong,
      onStrong: onStrong ?? this.onStrong,
      soft: soft ?? this.soft,
      onSoft: onSoft ?? this.onSoft,
      text: text ?? this.text,
    );
  }

  @override
  BrandTokens lerp(covariant BrandTokens? other, double t) {
    if (other == null) return this;
    return BrandTokens(
      strong: Color.lerp(strong, other.strong, t)!,
      onStrong: Color.lerp(onStrong, other.onStrong, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      onSoft: Color.lerp(onSoft, other.onSoft, t)!,
      text: Color.lerp(text, other.text, t)!,
    );
  }
}

extension BrandThemeX on BuildContext {
  BrandTokens get brand =>
      Theme.of(this).extension<BrandTokens>() ?? _fallbackBrand;
}

final _fallbackBrand = BrandTokens(
  strong: const Color(0xFF3D6B52),
  onStrong: Colors.white,
  soft: const Color(0xFFDFEDE3),
  onSoft: const Color(0xFF143526),
  text: const Color(0xFF345C46),
);

abstract final class AppTheme {
  static ThemeData light([
    AppPalette palette = AppPalette.green,
    AppFonts fonts = const AppFonts(),
  ]) => _build(Brightness.light, palette, fonts);

  static ThemeData dark([
    AppPalette palette = AppPalette.green,
    AppFonts fonts = const AppFonts(),
  ]) => _build(Brightness.dark, palette, fonts);

  static const _textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 36,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.25,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
    ),
    headlineSmall: TextStyle(
      fontSize: 23,
      height: 1.3,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    titleLarge: TextStyle(
      fontSize: 19,
      height: 1.35,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.4,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.55,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontSize: 12.5,
      height: 1.45,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      fontSize: 12.5,
      height: 1.2,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
    ),
  );

  static ThemeData _build(
    Brightness brightness,
    AppPalette palette,
    AppFonts fonts,
  ) {
    final isDark = brightness == Brightness.dark;
    final englishFont = fonts.primary;
    final bodyChain = fonts.bodyChain;
    final headingChain = fonts.headingChain;
    final base = ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );

    final strong = palette.strong;
    final onStrong = palette.onStrong(isDark);
    final soft = isDark ? palette.softDark : palette.softLight;
    final onSoft = isDark ? palette.onSoftDark : palette.onSoftLight;
    final accentText = isDark ? palette.textDark : palette.textLight;

    final scheme = base.copyWith(
      primary: strong,
      onPrimary: onStrong,
      primaryContainer: soft,
      onPrimaryContainer: onSoft,
      secondary: accentText,
      onSecondary: isDark ? Colors.black : Colors.white,
      secondaryContainer: soft,
      onSecondaryContainer: onSoft,
      surface: base.surface,
      onSurface: base.onSurface,
      onSurfaceVariant: base.onSurfaceVariant,
      outlineVariant: base.outlineVariant,
    );

    final applied = _textTheme.apply(
      fontFamily: englishFont,
      fontFamilyFallback: bodyChain,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    TextStyle? heading(TextStyle? style) => style?.copyWith(
      fontFamily: englishFont,
      fontFamilyFallback: headingChain,
    );
    final textTheme = applied.copyWith(
      displaySmall: heading(applied.displaySmall),
      headlineMedium: heading(applied.headlineMedium),
      headlineSmall: heading(applied.headlineSmall),
      titleLarge: heading(applied.titleLarge),
      titleMedium: heading(applied.titleMedium),
      titleSmall: heading(applied.titleSmall),
      bodyLarge: applied.bodyLarge?.copyWith(color: scheme.onSurface),
      bodyMedium: applied.bodyMedium?.copyWith(color: scheme.onSurface),
      bodySmall: applied.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: englishFont,
      fontFamilyFallback: bodyChain,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: strong,
        selectionColor: soft,
        selectionHandleColor: strong,
      ),
      extensions: [
        BrandTokens(
          strong: strong,
          onStrong: onStrong,
          soft: soft,
          onSoft: onSoft,
          text: accentText,
        ),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 8,
        toolbarHeight: 64,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 20),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 0.7,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: strong,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: englishFont,
            fontFamilyFallback: bodyChain,
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? onStrong : scheme.onSurfaceVariant,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: const StadiumBorder(),
          backgroundColor: strong,
          foregroundColor: onStrong,
          textStyle: TextStyle(
            fontFamily: englishFont,
            fontFamilyFallback: bodyChain,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant),
          foregroundColor: scheme.onSurface,
          textStyle: TextStyle(
            fontFamily: englishFont,
            fontFamilyFallback: bodyChain,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentText,
          shape: const StadiumBorder(),
          textStyle: TextStyle(
            fontFamily: englishFont,
            fontFamilyFallback: bodyChain,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusField),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusField),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusField),
          borderSide: BorderSide(color: strong, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusField),
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusField),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        errorStyle: TextStyle(
          fontFamily: englishFont,
          fontFamilyFallback: bodyChain,
          fontSize: 12.5,
          color: scheme.error,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusOverlay),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surfaceContainerLow,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusOverlay),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInner),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: soft,
        disabledColor: scheme.surfaceContainerLow,
        side: BorderSide.none,
        showCheckmark: false,
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium?.copyWith(color: onSoft),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontFamily: englishFont,
              fontFamilyFallback: bodyChain,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? strong
                : Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? onStrong
                : scheme.onSurfaceVariant;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.onSurfaceVariant),
        ),
      ),
      badgeTheme: BadgeThemeData(backgroundColor: strong, textColor: onStrong),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusField),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: strong),
    );
  }
}
