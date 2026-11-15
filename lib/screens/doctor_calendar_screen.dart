import 'package:bikram_sambat/bikram_sambat.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bs_date.dart' as bs;
import '../core/icons.dart';
import '../core/l10n.dart';
import '../core/nepali.dart' as np;
import '../core/saturday_schedule.dart';
import '../data/demo_data.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'booking_screen.dart';

/// Month calendar marking which Saturdays carry which visiting specialists.
class DoctorCalendarScreen extends StatefulWidget {
  const DoctorCalendarScreen({super.key});

  @override
  State<DoctorCalendarScreen> createState() => _DoctorCalendarScreenState();
}

class _DoctorCalendarScreenState extends State<DoctorCalendarScreen> {
  late DateTime _month = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  void _shift(int months) {
    setState(() {
      _month = DateTime(_month.year, _month.month + months);
    });
  }

  Future<void> _showDaySheet(BuildContext context, DateTime date) async {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final doctors = saturdayDoctorsForDate(date);
    final group = saturdayGroupForDate(date);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.weekdayBoth(date),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10n.dateBoth(date),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  if (group != null)
                    StatusPill(
                      label: l10n.saturdayGroupLabel(group),
                      background: scheme.primary,
                      foreground: scheme.onPrimary,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              for (final doctor in doctors) ...[
                _SheetDoctorTile(
                  doctor: doctor,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _book(context, doctor);
                  },
                ),
                if (doctor != doctors.last) const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _book(BuildContext context, Doctor doctor) async {
    final l10n = L10n.of(context);
    final created = await startBooking(
      context,
      departmentId: doctor.departmentId,
      doctorId: doctor.id,
    );
    if (created == true && context.mounted) {
      showAppSnack(context, l10n.appointmentConfirmedSnack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final isNp = !l10n.isEn;
    final today = dateOnly(DateTime.now());
    final bookedDates = {
      for (final appointment in context.watch<AppState>().appointments)
        if (appointment.isUpcoming) dateOnly(appointment.date),
    };
    final nextSaturday = nextSaturdayFrom(DateTime.now());

    final material = MaterialLocalizations.of(context);
    final bsMonth = _month.toBikramSambat();
    final firstOffset = _month.weekday % 7; // Sunday-first grid
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final weekdayLabels = [
      for (var i = 0; i < 7; i++)
        l10n.weekdayShort(DateTime(2026, 11, 15 + i)), // 2026-11-15 is a Sunday
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.doctorCalendarTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
        children: [
          // Gradient month header with a peek at this Saturday's doctors.
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _HeaderIconButton(
                      icon: PhosphorIconsRegular.caretLeft,
                      tooltip: l10n.prevMonth,
                      onPressed: () => _shift(-1),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            isNp
                                ? '${bs.bsMonthNp(_month)} ${np.nepNum(bsMonth.year)}'
                                : '${bs.bsMonthEn(_month)} ${bsMonth.year} BS',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            material.formatMonthYear(_month),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onPrimary.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _HeaderIconButton(
                      icon: PhosphorIconsRegular.caretRight,
                      tooltip: l10n.nextMonth,
                      onPressed: () => _shift(1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showDaySheet(context, nextSaturday),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIconsRegular.starFour,
                          size: 14,
                          color: scheme.onPrimary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l10n.thisSaturday} · ${bs.bsDateNpShort(nextSaturday)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _PeekAvatars(doctors: saturdayDoctorsForDate(nextSaturday)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Weekday letters, Sunday-first.
          Row(
            children: [
              for (final label in weekdayLabels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.82,
            children: [
              for (var i = 0; i < firstOffset; i++) const SizedBox.shrink(),
              for (var day = 1; day <= daysInMonth; day++)
                _DayCell(
                  date: DateTime(_month.year, _month.month, day),
                  doctors: saturdayDoctorsForDate(
                    DateTime(_month.year, _month.month, day),
                  ),
                  isNp: isNp,
                  isToday: today == DateTime(_month.year, _month.month, day),
                  isPast: DateTime(
                    _month.year,
                    _month.month,
                    day,
                  ).isBefore(today),
                  hasAppointment: bookedDates.contains(
                    DateTime(_month.year, _month.month, day),
                  ),
                  onOpenDay: (date) => _showDaySheet(context, date),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                PhosphorIconsRegular.handTap,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l10n.doctorCalendarHint} ${l10n.tapDoctorToBook}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.55,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => _shiftToMonth(context, today),
            child: Text(l10n.goToday),
          ),
        ],
      ),
    );
  }

  void _shiftToMonth(BuildContext context, DateTime today) {
    final target = DateTime(today.year, today.month);
    if (target == _month) return;
    setState(() => _month = target);
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 20, color: scheme.onPrimary),
    );
  }
}

class _PeekAvatars extends StatelessWidget {
  const _PeekAvatars({required this.doctors});

  final List<Doctor> doctors;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: doctors.isEmpty ? 0 : 15.0 + 8.0 * (doctors.length - 1),
      height: 15,
      child: Stack(
        children: [
          for (final doctor in doctors)
            Positioned(
              left: 8.0 * doctors.indexOf(doctor),
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: scheme.onPrimary,
                  shape: BoxShape.circle,
                ),
                child: DoctorAvatar(doctor: doctor, size: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.doctors,
    required this.isNp,
    required this.isToday,
    required this.isPast,
    required this.hasAppointment,
    required this.onOpenDay,
  });

  final DateTime date;
  final List<Doctor> doctors;
  final bool isNp;
  final bool isToday;
  final bool isPast;
  final bool hasAppointment;
  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasDoctors = doctors.isNotEmpty;
    final isSaturday = date.weekday == DateTime.saturday;

    final Color background;
    final Color foreground;
    if (hasDoctors) {
      background = isPast
          ? scheme.primaryContainer.withValues(alpha: 0.45)
          : scheme.primaryContainer;
      foreground = scheme.onPrimaryContainer;
    } else if (isSaturday) {
      background = scheme.surfaceContainerHighest.withValues(alpha: 0.55);
      foreground = scheme.onSurfaceVariant;
    } else {
      background = Colors.transparent;
      foreground = scheme.onSurface;
    }

    final bigDay = isNp ? bs.bsDayNp(date) : date.day;
    final smallDay = isNp ? date.day : bs.bsDay(date);

    Widget cell = Container(
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: isToday && !hasDoctors
            ? Border.all(color: scheme.primary, width: 1.4)
            : null,
      ),
      child: Column(
        children: [
          Text(
            '$bigDay',
            style: theme.textTheme.titleSmall?.copyWith(
              color: isToday && hasDoctors ? scheme.primary : foreground,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          Text(
            '$smallDay',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              height: 1.1,
              color: isToday && hasDoctors ? scheme.primary : foreground,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 15,
            child: hasDoctors
                ? Stack(
                    children: [
                      for (final doctor in doctors)
                        Positioned(
                          left: 8.0 * doctors.indexOf(doctor),
                          child: Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              shape: BoxShape.circle,
                            ),
                            child: DoctorAvatar(doctor: doctor, size: 12),
                          ),
                        ),
                    ],
                  )
                : hasAppointment
                ? Icon(
                    PhosphorIconsRegular.calendarCheck,
                    size: 13,
                    color: scheme.primary,
                  )
                : null,
          ),
        ],
      ),
    );

    if (isToday && hasDoctors) {
      cell = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.primary, width: 1.6),
        ),
        child: cell,
      );
    }

    final tappable = isSaturday && hasDoctors;
    if (!tappable) return cell;
    return InkWell(
      onTap: () => onOpenDay(date),
      borderRadius: BorderRadius.circular(12),
      child: cell,
    );
  }
}

class _SheetDoctorTile extends StatelessWidget {
  const _SheetDoctorTile({required this.doctor, required this.onTap});

  final Doctor doctor;
  final VoidCallback onTap;

  String _hoursFor(L10n l10n, Doctor doctor) {
    final start = doctor.startTime;
    final end = doctor.endTime;
    if (start == null || end == null) {
      return doctor.availability(l10n.language);
    }
    return l10n.timeRange(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            DoctorAvatar(doctor: doctor, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          doctor.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (doctor.visiting)
                        StatusPill(
                          label: l10n.visiting,
                          background: scheme.tertiaryContainer,
                          foreground: scheme.onTertiaryContainer,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${doctor.displaySpecialty} · ${_hoursFor(l10n, doctor)} · ${l10n.money(doctor.fee)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
