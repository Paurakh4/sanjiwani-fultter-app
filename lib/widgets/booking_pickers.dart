import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/l10n.dart';
import '../core/slot_availability.dart';
import '../core/tokens.dart';
import '../models.dart';
import '../state/app_state.dart';

const double kDateChipWidth = 122.0;
const double kDateChipGap = 8.0;

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Horizontal rail of the doctor's upcoming Saturdays. A date is selectable
/// when the doctor is scheduled that day; booking is date-only.
class BookingDateRail extends StatelessWidget {
  const BookingDateRail({
    super.key,
    required this.doctor,
    required this.dates,
    required this.selectedDate,
    required this.onSelected,
    this.excludingAppointmentId,
    this.controller,
  });

  final Doctor doctor;
  final List<DateTime> dates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;
  final String? excludingAppointmentId;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final appointments = context.watch<AppState>().appointments;
    if (dates.isEmpty) {
      return _Note(icon: CoolIcons.calendarX, text: l10n.bookingNoDates);
    }
    return SizedBox(
      height: AppTokens.scaled(context, 92),
      child: ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: kDateChipGap),
        itemBuilder: (context, index) {
          final date = dates[index];
          return _DateChip(
            date: date,
            scheduleLabel: doctor.saturdayGroup == null
                ? l10n.specialistHoursShort
                : l10n.saturdayGroupShort(doctor.saturdayGroup!),
            selected: _sameDay(date, selectedDate),
            enabled:
                isDateBookable(doctor: doctor, date: date) &&
                !hasBookingOn(
                  appointments: appointments,
                  doctorId: doctor.id,
                  date: date,
                  excludingAppointmentId: excludingAppointmentId,
                ),
            disabledHint: l10n.bookingDateUnavailable,
            onTap: () => onSelected(date),
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.scheduleLabel,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.disabledHint,
  });

  final DateTime date;
  final String scheduleLabel;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final primary = context.watch<AppState>().datePrimary;
    final background = selected
        ? scheme.primary
        : enabled
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerLow;
    final foreground = selected
        ? scheme.onPrimary
        : enabled
        ? scheme.onSurface
        : scheme.onSurfaceVariant.withValues(alpha: 0.45);
    final muted = selected
        ? scheme.onPrimary.withValues(alpha: 0.78)
        : enabled
        ? scheme.onSurfaceVariant
        : scheme.onSurfaceVariant.withValues(alpha: 0.4);

    final chip = Material(
      color: background,
      borderRadius: BorderRadius.circular(AppTokens.radiusField),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: kDateChipWidth,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.primaryDateChip(date, primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.secondaryDateChip(date, primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(CoolIcons.calendarBlank, size: 12, color: muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        scheduleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final semantic = Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label:
          '${l10n.primaryDateChip(date, primary)} · '
          '${l10n.secondaryDateChip(date, primary)}',
      child: chip,
    );
    if (!enabled && disabledHint != null) {
      return Tooltip(message: disabledHint, child: semantic);
    }
    return semantic;
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusInner),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
