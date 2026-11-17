import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/l10n.dart';
import '../core/saturday_schedule.dart';
import '../core/tokens.dart';
import '../data/demo_data.dart';
import '../models.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';
import 'booking_screen.dart';
import 'doctor_calendar_screen.dart';

class SaturdayScheduleScreen extends StatelessWidget {
  const SaturdayScheduleScreen({super.key});

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
    final nextSaturday = nextBookableSaturday(DateTime.now());
    final nextGroup = saturdayGroupForDate(nextSaturday);
    final nextDoctors = saturdayDoctorsForDate(nextSaturday);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.saturdayScheduleTitle),
        actions: [
          IconButton(
            tooltip: l10n.viewDoctorCalendar,
            icon: const Icon(CoolIcons.calendarDots),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DoctorCalendarScreen(),
              ),
            ),
          ),
        ],
      ),
      body: AppRefreshView(
        onRefresh: demoRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTokens.gutter,
            4,
            AppTokens.gutter,
            40,
          ),
          children: [
            Text(
              l10n.saturdaySpecialistsSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.55,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _HoursChip(icon: CoolIcons.clock, label: l10n.specialistHours),
                const SizedBox(width: 8),
                _HoursChip(
                  icon: CoolIcons.stethoscope,
                  label: l10n.mbbsOpdDaily,
                ),
              ],
            ),
            const SizedBox(height: 28),
            SectionHeader(title: l10n.thisSaturday),
            const SizedBox(height: 10),
            _ThisSaturdayCard(
              date: nextSaturday,
              group: nextGroup,
              doctors: nextDoctors,
              onBook: (doctor) => _book(context, doctor),
            ),
            const SizedBox(height: 28),
            SectionHeader(title: l10n.monthlyRotation),
            const SizedBox(height: 4),
            Text(
              l10n.tapDoctorToBook,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final group in SaturdayGroup.values) ...[
              _RotationCard(
                group: group,
                doctors: doctorsForSaturdayGroup(group),
                onBook: (doctor) => _book(context, doctor),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CoolIcons.info, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.saturdayScheduleNote} ${l10n.fiveSaturdayNote}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.55,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HoursChip extends StatelessWidget {
  const _HoursChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThisSaturdayCard extends StatelessWidget {
  const _ThisSaturdayCard({
    required this.date,
    required this.group,
    required this.doctors,
    required this.onBook,
  });

  final DateTime date;
  final SaturdayGroup? group;
  final List<Doctor> doctors;
  final ValueChanged<Doctor> onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);

    return AppCard(
      padding: const EdgeInsets.all(16),
      color: scheme.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  label: l10n.saturdayGroupLabel(group!),
                  background: scheme.primary,
                  foreground: scheme.onPrimary,
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (doctors.isEmpty)
            Text(
              l10n.noSpecialistThisSaturday,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.55,
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            for (final doctor in doctors) ...[
              _ScheduleDoctorTile(doctor: doctor, onTap: () => onBook(doctor)),
              if (doctor != doctors.last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _RotationCard extends StatelessWidget {
  const _RotationCard({
    required this.group,
    required this.doctors,
    required this.onBook,
  });

  final SaturdayGroup group;
  final List<Doctor> doctors;
  final ValueChanged<Doctor> onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    final next = nextSaturdayForGroup(group);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.saturdayGroupLabel(group),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            l10n.nextDateLabel(next),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          for (final doctor in doctors) ...[
            _ScheduleDoctorTile(
              doctor: doctor,
              onTap: () => onBook(doctor),
              compact: true,
            ),
            if (doctor != doctors.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ScheduleDoctorTile extends StatelessWidget {
  const _ScheduleDoctorTile({
    required this.doctor,
    required this.onTap,
    this.compact = false,
  });

  final Doctor doctor;
  final VoidCallback onTap;
  final bool compact;

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
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 4),
        child: Row(
          children: [
            DoctorAvatar(doctor: doctor, size: compact ? 38 : 42),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${doctor.displaySpecialty} · ${_hoursFor(l10n, doctor)}',
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
