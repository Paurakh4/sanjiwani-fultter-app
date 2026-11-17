import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bs_date.dart' as bs;
import '../core/icons.dart';
import '../core/l10n.dart';
import '../core/saturday_schedule.dart';
import '../core/tokens.dart';
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
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  static final DateTime _minMonth = DateTime(1944, 1);
  static final DateTime _maxMonth = DateTime(2032, 12);

  void _shift(int months) {
    final next = DateTime(_month.year, _month.month + months);
    if (next.isBefore(_minMonth) || next.isAfter(_maxMonth)) return;
    setState(() => _month = next);
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
                        DateText(
                          date: date,
                          primaryStyle: theme.textTheme.titleMedium,
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
    await startBooking(
      context,
      departmentId: doctor.departmentId,
      doctorId: doctor.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final datePrimary = context.watch<AppState>().datePrimary;
    final bsPrimary = datePrimary == DatePrimary.nepali;
    final today = dateOnly(DateTime.now());
    final bookedDates = {
      for (final appointment in context.watch<AppState>().appointments)
        if (appointment.isUpcoming) dateOnly(appointment.date),
    };
    final nextSaturday = nextBookableSaturday(DateTime.now());
    final canPrev = _month.isAfter(_minMonth);
    final canNext = _month.isBefore(_maxMonth);

    final firstOffset = _month.weekday % 7; // Sunday-first grid
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final sundayAnchor = today.subtract(Duration(days: today.weekday % 7));
    final weekdayLabels = [
      for (var i = 0; i < 7; i++)
        l10n.weekdayShort(sundayAnchor.add(Duration(days: i))),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.doctorCalendarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.gutter,
          4,
          AppTokens.gutter,
          32,
        ),
        children: [
          // Gradient month header with a peek at this Saturday's doctors.
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary,
                  Color.lerp(scheme.primary, Colors.black, 0.18)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _HeaderIconButton(
                      icon: CoolIcons.caretLeft,
                      tooltip: l10n.prevMonth,
                      onPressed: canPrev ? () => _shift(-1) : null,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            bsPrimary
                                ? l10n.bsMonthYear(_month)
                                : l10n.adMonthYear(_month),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            bsPrimary
                                ? l10n.adMonthYear(_month)
                                : l10n.bsMonthYear(_month),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onPrimary.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _HeaderIconButton(
                      icon: CoolIcons.caretRight,
                      tooltip: l10n.nextMonth,
                      onPressed: canNext ? () => _shift(1) : null,
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
                          CoolIcons.starFourFill,
                          size: 14,
                          color: scheme.onPrimary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l10n.thisSaturday} · ${l10n.primaryDateMedium(nextSaturday, datePrimary)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _PeekAvatars(
                          doctors: saturdayDoctorsForDate(nextSaturday),
                        ),
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
              for (var i = 0; i < weekdayLabels.length; i++)
                Expanded(
                  child: Text(
                    weekdayLabels[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: i == DateTime.saturday
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              mainAxisExtent: math.max(48.0, AppTokens.scaled(context, 56)),
            ),
            itemCount: firstOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstOffset) return const SizedBox.shrink();
              final day = index - firstOffset + 1;
              final date = DateTime(_month.year, _month.month, day);
              return _DayCell(
                date: date,
                doctors: saturdayDoctorsForDate(date),
                bsPrimary: bsPrimary,
                isToday: today == date,
                isPast: date.isBefore(today),
                hasAppointment: bookedDates.contains(date),
                onOpenDay: (date) => _showDaySheet(context, date),
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CoolIcons.handTap, size: 18, color: scheme.onSurfaceVariant),
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
  final VoidCallback? onPressed;

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
    required this.bsPrimary,
    required this.isToday,
    required this.isPast,
    required this.hasAppointment,
    required this.onOpenDay,
  });

  final DateTime date;
  final List<Doctor> doctors;
  final bool bsPrimary;
  final bool isToday;
  final bool isPast;
  final bool hasAppointment;
  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final hasDoctors = doctors.isNotEmpty;
    final isSaturday = date.weekday == DateTime.saturday;

    // Saturdays read red throughout: a stronger tint on days with
    // visiting specialists, a lighter one on the rest.
    final isDark = theme.brightness == Brightness.dark;
    final Color background;
    final Color foreground;
    if (hasDoctors) {
      final base = scheme.errorContainer.withValues(alpha: isDark ? 0.6 : 1);
      background = isPast ? base.withValues(alpha: base.a * 0.6) : base;
      foreground = scheme.onErrorContainer;
    } else if (isSaturday) {
      background = scheme.errorContainer.withValues(alpha: isDark ? 0.22 : 0.4);
      foreground = scheme.error;
    } else {
      background = Colors.transparent;
      foreground = scheme.onSurface;
    }

    // Bikram Sambat always uses Devanagari numerals; the Gregorian date
    // always stays in Latin numerals.
    final bigDay = bsPrimary ? bs.bsDayNp(date) : '${date.day}';
    final smallDay = bsPrimary ? '${date.day}' : bs.bsDayNp(date);
    final digitColor = isToday && !isSaturday ? scheme.primary : foreground;
    final todayRing = hasDoctors
        ? scheme.onErrorContainer
        : isSaturday
        ? scheme.error
        : scheme.primary;

    Widget cell = Container(
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.radiusCell),
        border: isToday && !hasDoctors
            ? Border.all(color: todayRing, width: 1.4)
            : null,
      ),
      child: Column(
        children: [
          Text(
            bigDay,
            style: theme.textTheme.titleSmall?.copyWith(
              color: digitColor,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          Text(
            smallDay,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              height: 1.1,
              color: digitColor.withValues(alpha: 0.66),
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
                ? Icon(CoolIcons.calendarCheck, size: 13, color: scheme.primary)
                : null,
          ),
        ],
      ),
    );

    if (isToday && hasDoctors) {
      cell = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusCell),
          border: Border.all(color: todayRing, width: 1.6),
        ),
        child: cell,
      );
    }

    final tappable = isSaturday && hasDoctors && !isPast;
    if (tappable) {
      return Semantics(
        button: true,
        label: l10n.dateBoth(date),
        child: InkWell(
          onTap: () => onOpenDay(date),
          borderRadius: BorderRadius.circular(AppTokens.radiusCell),
          child: cell,
        ),
      );
    }
    if (isPast && hasDoctors) {
      return Semantics(label: l10n.pastDateNote, child: cell);
    }
    return cell;
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
              CoolIcons.caretRight,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
