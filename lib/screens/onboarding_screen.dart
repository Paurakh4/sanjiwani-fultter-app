import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/icons.dart';

import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/palette.dart';
import '../core/tokens.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final selectedTheme = state.themeMode == ThemeMode.dark
        ? ThemeMode.dark
        : ThemeMode.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: scheme.surface,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.gutter,
              24,
              AppTokens.gutter,
              36,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppWordmark(height: 56),
                const SizedBox(height: 36),
                Text(l10n.welcomeTitle, style: theme.textTheme.displaySmall),
                const SizedBox(height: 8),
                Text(
                  l10n.welcomeBody,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                _Label(text: l10n.chooseLanguage),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _LanguageOption(
                        label: l10n.languageNepali,
                        selected: state.language == AppLanguage.np,
                        onTap: () => context.read<AppState>().setLanguage(
                          AppLanguage.np,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LanguageOption(
                        label: l10n.languageEnglish,
                        selected: state.language == AppLanguage.en,
                        onTap: () => context.read<AppState>().setLanguage(
                          AppLanguage.en,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _Label(text: l10n.chooseTheme),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ThemeOption(
                        label: l10n.themeLight,
                        icon: CoolIcons.sun,
                        background: const Color(0xFFF7FAF5),
                        foreground: const Color(0xFF101710),
                        selected: selectedTheme == ThemeMode.light,
                        onTap: () => context.read<AppState>().setThemeMode(
                          ThemeMode.light,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ThemeOption(
                        label: l10n.themeDark,
                        icon: CoolIcons.moonStars,
                        background: const Color(0xFF121712),
                        foreground: const Color(0xFFE5EAE3),
                        selected: selectedTheme == ThemeMode.dark,
                        onTap: () => context.read<AppState>().setThemeMode(
                          ThemeMode.dark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _Label(text: l10n.chooseAccent),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 10.0;
                    final itemWidth = (constraints.maxWidth - spacing * 2) / 3;
                    if (itemWidth <= 0) return const SizedBox.shrink();
                    return Wrap(
                      spacing: spacing,
                      runSpacing: 14,
                      children: [
                        for (final palette in AppPalette.values)
                          SizedBox(
                            width: itemWidth,
                            child: _PaletteOption(
                              palette: palette,
                              selected: state.palette == palette,
                              onTap: () =>
                                  context.read<AppState>().setPalette(palette),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final appState = context.read<AppState>();
                      if (appState.themeMode == ThemeMode.system) {
                        appState.setThemeMode(ThemeMode.light);
                      }
                      appState.completeOnboarding();
                    },
                    child: Text(l10n.getStarted),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    l10n.settingsLater,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHigh,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppTokens.scaled(context, 126),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 24, color: foreground),
                  const Spacer(),
                  if (selected)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CoolIcons.check,
                        size: 15,
                        color: scheme.onPrimary,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteOption extends StatelessWidget {
  const _PaletteOption({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = L10n.of(context).language;
    return Semantics(
      button: true,
      selected: selected,
      label: language == AppLanguage.en ? palette.labelEn : palette.labelNp,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.strong,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? scheme.onSurface : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Icon(
                        CoolIcons.check,
                        color: palette.onStrong(false),
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                language == AppLanguage.en ? palette.labelEn : palette.labelNp,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
