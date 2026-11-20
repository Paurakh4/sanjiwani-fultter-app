import 'package:flutter/material.dart';

import '../core/icons.dart';

import '../core/clinic.dart';
import '../core/l10n.dart';
import '../core/launcher.dart';
import '../core/tokens.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';
import 'saturday_schedule_screen.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final language = l10n.language;
    final now = DateTime.now();
    final isOpen = Clinic.isOpenAt(now);
    final isSaturday = now.weekday == DateTime.saturday;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.contactTitle),
      ),
      body: AppRefreshView(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTokens.gutter,
            8,
            AppTokens.gutter,
            40,
          ),
          children: [
            const Center(child: AppWordmark(height: 68)),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOpen
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isOpen ? scheme.primary : scheme.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOpen ? l10n.openToday : l10n.closedNow,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOpen
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final width = (constraints.maxWidth - spacing) / 2;
                if (width <= 0) return const SizedBox.shrink();
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: width,
                      height: AppTokens.scaled(context, 112),
                      child: _ContactAction(
                        icon: CoolIcons.phoneCall,
                        label: l10n.contactCall,
                        detail: l10n.digits(Clinic.phonePrimaryDisplay),
                        accent: true,
                        onTap: () => callClinic(context),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      height: AppTokens.scaled(context, 112),
                      child: _ContactAction(
                        icon: CoolIcons.whatsappLogo,
                        label: l10n.contactWhatsapp,
                        detail: l10n.digits(Clinic.whatsappDisplay),
                        onTap: () => messageClinic(context),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      height: AppTokens.scaled(context, 112),
                      child: _ContactAction(
                        icon: CoolIcons.envelopeSimple,
                        label: l10n.contactEmail,
                        detail: l10n.contactSendEmail,
                        onTap: () => emailClinic(context),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      height: AppTokens.scaled(context, 112),
                      child: _ContactAction(
                        icon: CoolIcons.mapPin,
                        label: l10n.contactMap,
                        detail: l10n.contactOpenMap,
                        onTap: () => openClinicMap(context),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            SectionHeader(title: l10n.clinicHours),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _HoursRow(
                    label: l10n.everyDay,
                    value: l10n.weekdayHours,
                    highlighted: true,
                  ),
                  const SizedBox(height: 12),
                  _HoursRow(
                    label: l10n.specialistHoursTitle,
                    value: l10n.specialistHours,
                    highlighted: isSaturday,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SaturdayScheduleScreen(),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, AppTokens.minTap),
                ),
                icon: const Icon(CoolIcons.calendarDots, size: 17),
                label: Text(l10n.viewSaturdaySchedule),
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(title: l10n.contactDetails),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _ContactRow(
                    icon: CoolIcons.phone,
                    value:
                        '${l10n.digits(Clinic.phonePrimaryDisplay)} ${l10n.phoneClinicSuffix}',
                  ),
                  const SizedBox(height: 14),
                  _ContactRow(
                    icon: CoolIcons.deviceMobile,
                    value:
                        '${l10n.digits(Clinic.phoneMobileDisplay)} ${l10n.phoneMobileSuffix}',
                  ),
                  const SizedBox(height: 14),
                  _ContactRow(
                    icon: CoolIcons.whatsappLogo,
                    value:
                        '${l10n.digits(Clinic.whatsappDisplay)} ${l10n.contactWhatsapp}',
                  ),
                  const SizedBox(height: 14),
                  _ContactRow(
                    icon: CoolIcons.envelopeSimple,
                    value: Clinic.email,
                    onTap: () => emailClinic(context),
                  ),
                  const SizedBox(height: 14),
                  _ContactRow(
                    icon: CoolIcons.globe,
                    value: Clinic.website,
                    onTap: () => openClinicWebsite(context),
                  ),
                  const SizedBox(height: 14),
                  _ContactRow(
                    icon: CoolIcons.mapPin,
                    value: Clinic.address(language),
                    onTap: () => openClinicMap(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.contactNote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: accent ? scheme.primaryContainer : null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TonalIcon(
            icon: icon,
            size: 36,
            iconSize: 18,
            background: accent ? scheme.primary : scheme.surfaceContainerHigh,
            foreground: accent ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
          const Spacer(),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: accent ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  const _HoursRow({
    required this.label,
    required this.value,
    required this.highlighted,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = highlighted ? scheme.secondary : scheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.value, this.onTap});

  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: scheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        if (onTap != null)
          Icon(CoolIcons.caretRight, size: 16, color: scheme.onSurfaceVariant),
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: content,
      ),
    );
  }
}
