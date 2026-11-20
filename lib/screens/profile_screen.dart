import 'package:flutter/material.dart';

import '../core/icons.dart';

import 'package:provider/provider.dart';

import '../core/clinic.dart';
import '../core/fonts.dart';
import '../core/l10n.dart';
import '../core/nepali.dart';
import '../core/palette.dart';
import '../core/tokens.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';
import 'contact_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.onOpenTab,
    this.scrollController,
  });

  final ValueChanged<int> onOpenTab;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = L10n.of(context);
    final language = state.language;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = context.brand;
    final profile = state.profile;

    return SafeArea(
      bottom: false,
      child: AppRefreshView(
        onRefresh: demoRefresh,
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTokens.gutter,
            12,
            AppTokens.gutter,
            40,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.profileTitle,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ),
                  tooltip: l10n.editProfileTooltip,
                  icon: const Icon(CoolIcons.pencilSimple),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.primary, width: 1.5),
                        ),
                        child: Text(
                          initials(l10n.personName(profile.name)),
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.personName(profile.name),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.digits(profile.phone),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.patientIdLabel(profile.patientId),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusPill(
                        label: l10n.bloodGroup(
                          l10n.bloodGroupDisplay(profile.bloodGroup),
                        ),
                        background: scheme.surfaceContainerHigh,
                        foreground: scheme.onSurface,
                      ),
                      StatusPill(
                        label: l10n.age(profile.age),
                        background: scheme.surfaceContainerHigh,
                        foreground: scheme.onSurface,
                      ),
                      StatusPill(
                        label: l10n.gender(profile.gender),
                        background: scheme.surfaceContainerHigh,
                        foreground: scheme.onSurface,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: l10n.digits(state.upcomingAppointments.length),
                    label: l10n.upcomingLabel,
                    accent: brand.text,
                    onTap: () => onOpenTab(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    value: l10n.digits(state.pastAppointments.length),
                    label: l10n.pastVisitsLabel,
                    accent: brand.text,
                    onTap: () => onOpenTab(1),
                  ),
                ),
              ],
            ),
            _SectionLabel(text: l10n.sectionMyHealth),
            _ProfileAction(
              icon: CoolIcons.folderOpen,
              label: l10n.recordsLabel,
              trailing: StatusPill(
                label: l10n.comingSoonLabel,
                background: scheme.surfaceContainerHigh,
                foreground: scheme.onSurfaceVariant,
              ),
              onTap: () => onOpenTab(2),
            ),
            _ProfileAction(
              icon: CoolIcons.bellSimple,
              label: l10n.notificationsLabel,
              trailing: state.unreadCount > 0
                  ? StatusPill(
                      label: l10n.digits(state.unreadCount),
                      background: scheme.primary,
                      foreground: scheme.onPrimary,
                    )
                  : null,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
            ),
            _ProfileAction(
              svgIcon: 'clipboard-list-round',
              label: l10n.appointmentsMenu,
              onTap: () => onOpenTab(1),
            ),
            _SectionLabel(text: l10n.sectionPreferences),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PreferenceHeader(
                    icon: CoolIcons.circleHalf,
                    title: l10n.themeTitle,
                    subtitle: l10n.themeSubtitle,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    expandedInsets: EdgeInsets.zero,
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l10n.themeSystem),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(l10n.themeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(l10n.themeDark),
                      ),
                    ],
                    selected: {state.themeMode},
                    onSelectionChanged: (selection) =>
                        state.setThemeMode(selection.first),
                  ),
                  const SizedBox(height: 22),
                  _PreferenceHeader(
                    icon: CoolIcons.translate,
                    title: l10n.languageTitle,
                    subtitle: l10n.languageSubtitle,
                  ),
                  const SizedBox(height: 12),
                  PillTabBar(
                    labels: [l10n.languageNepali, l10n.languageEnglish],
                    selectedIndex: language == AppLanguage.np ? 0 : 1,
                    onChanged: (index) => state.setLanguage(
                      index == 0 ? AppLanguage.np : AppLanguage.en,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _PreferenceHeader(
                    icon: CoolIcons.calendarDots,
                    title: l10n.dateDisplayTitle,
                    subtitle: l10n.dateDisplaySubtitle,
                  ),
                  const SizedBox(height: 12),
                  PillTabBar(
                    labels: [l10n.dateNepaliOption, l10n.dateEnglishOption],
                    selectedIndex: state.datePrimary == DatePrimary.nepali
                        ? 0
                        : 1,
                    onChanged: (index) => state.setDatePrimary(
                      index == 0 ? DatePrimary.nepali : DatePrimary.english,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _PreferenceHeader(
                    icon: CoolIcons.palette,
                    title: l10n.accentTitle,
                    subtitle: l10n.accentSubtitle,
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 10.0;
                      final itemWidth =
                          (constraints.maxWidth - spacing * 2) / 3;
                      if (itemWidth <= 0) return const SizedBox.shrink();
                      return Wrap(
                        spacing: spacing,
                        runSpacing: 12,
                        children: [
                          for (final palette in AppPalette.values)
                            SizedBox(
                              width: itemWidth,
                              child: _PaletteChoice(
                                palette: palette,
                                selected: state.palette == palette,
                                onTap: () => state.setPalette(palette),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _PreferenceHeader(
                    icon: CoolIcons.textAa,
                    title: l10n.fontsTitle,
                    subtitle: l10n.fontsSubtitle,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.fontRoleNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FontSelector(
                    title: l10n.nepaliHeadingFontTitle,
                    labels: [for (final font in NepaliFont.values) font.label],
                    selectedIndex: NepaliFont.values.indexOf(
                      state.nepaliHeadingFont,
                    ),
                    onSelected: (index) =>
                        state.setNepaliHeadingFont(NepaliFont.values[index]),
                    preview: l10n.nepaliFontSample,
                    previewFamily: state.nepaliHeadingFont.family,
                    previewSize: 19,
                  ),
                  const SizedBox(height: 16),
                  _FontSelector(
                    title: l10n.nepaliBodyFontTitle,
                    labels: [for (final font in NepaliFont.values) font.label],
                    selectedIndex: NepaliFont.values.indexOf(
                      state.nepaliBodyFont,
                    ),
                    onSelected: (index) =>
                        state.setNepaliBodyFont(NepaliFont.values[index]),
                    preview: l10n.nepaliFontSample,
                    previewFamily: state.nepaliBodyFont.family,
                  ),
                  const SizedBox(height: 16),
                  _FontSelector(
                    title: l10n.englishFontTitle,
                    labels: [for (final font in EnglishFont.values) font.label],
                    selectedIndex: EnglishFont.values.indexOf(
                      state.englishFont,
                    ),
                    onSelected: (index) =>
                        state.setEnglishFont(EnglishFont.values[index]),
                    preview: l10n.englishFontSample,
                    previewFamily: state.englishFont.family,
                  ),
                ],
              ),
            ),
            _ProfileAction(
              svgIcon: 'arrow-down-up-round',
              label: l10n.navOrderTitle,
              onTap: () => _showTabOrderSheet(context),
            ),
            _SectionLabel(text: l10n.sectionClinic),
            _ProfileAction(
              icon: CoolIcons.mapPin,
              label: l10n.contactHours,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ContactScreen()),
              ),
            ),
            _ProfileAction(
              icon: CoolIcons.info,
              label: l10n.aboutApp,
              onTap: () => _showAbout(context),
            ),
            _SectionLabel(text: l10n.sectionAccount),
            _ProfileAction(
              svgIcon: 'log-out-round',
              label: l10n.signOut,
              onTap: () => _signOut(context),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.versionLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.demoBuildLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTabOrderSheet(BuildContext context) {
    final l10n = L10n.of(context);
    final labels = <int, String>{
      0: l10n.navHome,
      1: l10n.appointmentsTitle,
      2: l10n.navRecords,
      3: l10n.navProfile,
      4: l10n.navCalendar,
    };
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final sheetL10n = L10n.of(sheetContext);
        final scheme = Theme.of(sheetContext).colorScheme;
        var order = List.of(
          sheetContext.read<AppState>().tabOrder,
        );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sheetL10n.navOrderTitle,
                    style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  sheetL10n.navOrderSubtitle,
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                        color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (sheetContext, setSheetState) => Column(
                    children: [
                      for (var i = 0; i < order.length; i++)
                        ListTile(
                          leading: switch (order[i]) {
                            1 => TonalSvgIcon(
                              svg: 'clipboard-list-round',
                              size: 42,
                              iconSize: 20,
                              background: scheme.surfaceContainerHigh,
                              foreground: scheme.onSurfaceVariant,
                            ),
                            4 => TonalSvgIcon(
                              svg: 'calendar-round',
                              size: 42,
                              iconSize: 20,
                              background: scheme.surfaceContainerHigh,
                              foreground: scheme.onSurfaceVariant,
                            ),
                            _ => TonalIcon(
                              icon: switch (order[i]) {
                                0 => CoolIcons.house,
                                2 => CoolIcons.folderOpen,
                                _ => CoolIcons.userCircle,
                              },
                              size: 42,
                              iconSize: 20,
                              background: scheme.surfaceContainerHigh,
                              foreground: scheme.onSurfaceVariant,
                            ),
                          },
                          title: Text(labels[order[i]] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: i == 0
                                    ? null
                                    : () => setSheetState(() {
                                          final id = order.removeAt(i);
                                          order.insert(i - 1, id);
                                          sheetContext
                                              .read<AppState>()
                                              .setTabOrder(order);
                                        }),
                                icon: CoolSvgIcon(
                                  'chevron-up-round',
                                  size: 22,
                                  color: i == 0
                                      ? scheme.onSurfaceVariant.withValues(
                                          alpha: 0.3,
                                        )
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                              IconButton(
                                onPressed: i == order.length - 1
                                    ? null
                                    : () => setSheetState(() {
                                          final id = order.removeAt(i);
                                          order.insert(i + 1, id);
                                          sheetContext
                                              .read<AppState>()
                                              .setTabOrder(order);
                                        }),
                                icon: CoolSvgIcon(
                                  'chevron-down-round',
                                  size: 22,
                                  color: i == order.length - 1
                                      ? scheme.onSurfaceVariant.withValues(
                                          alpha: 0.3,
                                        )
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          sheetContext.read<AppState>().resetTabOrder();
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(sheetL10n.navOrderReset),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(sheetL10n.close),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _signOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = L10n.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.signOutTitle),
          content: Text(dialogL10n.signOutBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogL10n.keep),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                dialogContext.read<AppState>().signOut();
              },
              child: Text(dialogL10n.signOut),
            ),
          ],
        );
      },
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;
        final l10n = L10n.of(dialogContext);
        return AlertDialog(
          icon: const AppWordmark(height: 50),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.aboutVersion,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.aboutBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 10),
              Text(
                '${l10n.digits(Clinic.phonePrimaryDisplay)} · ${Clinic.email}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.okay),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 4, left: 4),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String value;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 26,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    this.icon,
    this.svgIcon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData? icon;
  final String? svgIcon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final leading = svgIcon != null
        ? TonalSvgIcon(
            svg: svgIcon!,
            size: 42,
            iconSize: 20,
            background: scheme.surfaceContainerHigh,
            foreground: scheme.onSurfaceVariant,
          )
        : TonalIcon(
            icon: icon!,
            size: 42,
            iconSize: 20,
            background: scheme.surfaceContainerHigh,
            foreground: scheme.onSurfaceVariant,
          );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 15),
                ),
              ),
              if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
              Icon(CoolIcons.caretRight, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceHeader extends StatelessWidget {
  const _PreferenceHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        TonalIcon(
          icon: icon,
          size: 38,
          iconSize: 19,
          background: scheme.surfaceContainerHigh,
          foreground: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FontSelector extends StatelessWidget {
  const _FontSelector({
    required this.title,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    required this.preview,
    required this.previewFamily,
    this.previewSize = 15,
  });

  final String title;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String preview;
  final String previewFamily;
  final double previewSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < labels.length; i++)
              ChoicePill(
                label: labels[i],
                selected: selectedIndex == i,
                onTap: () => onSelected(i),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTokens.radiusCell),
          ),
          child: Text(
            preview,
            style: TextStyle(
              fontFamily: previewFamily,
              fontSize: previewSize,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaletteChoice extends StatelessWidget {
  const _PaletteChoice({
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
        borderRadius: BorderRadius.circular(AppTokens.radiusCell),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
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
                        size: 18,
                      )
                    : null,
              ),
              const SizedBox(height: 4),
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
