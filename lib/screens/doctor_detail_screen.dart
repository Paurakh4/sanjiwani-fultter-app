import 'package:flutter/material.dart';

import '../core/icons.dart';

import '../core/clinic.dart';
import '../core/l10n.dart';
import '../data/demo_data.dart';
import '../models.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';
import 'booking_screen.dart';
import 'saturday_schedule_screen.dart';

class DoctorDetailScreen extends StatelessWidget {
  const DoctorDetailScreen({super.key, required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final language = l10n.language;
    final department = departmentById(doctor.departmentId);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.doctorDetails)),
      body: AppRefreshView(
        onRefresh: demoRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 40),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DoctorAvatar(doctor: doctor, size: 76),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        doctor.displaySpecialty,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          StatusPill(
                            label: doctor.qualification,
                            background: scheme.surfaceContainerHigh,
                            foreground: scheme.onSurfaceVariant,
                          ),
                          if (doctor.saturdayGroup != null)
                            StatusPill(
                              label: l10n.saturdayGroupLabel(
                                doctor.saturdayGroup!,
                              ),
                              background: scheme.primaryContainer,
                              foreground: scheme.onPrimaryContainer,
                            ),
                          if (doctor.visiting)
                            StatusPill(
                              label: l10n.visiting,
                              background: scheme.secondaryContainer,
                              foreground: scheme.onSecondaryContainer,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                children: [
                  _InfoRow(
                    icon: PhosphorIconsRegular.stethoscope,
                    label: l10n.departmentLabel,
                    value: department.displayName,
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: PhosphorIconsRegular.clock,
                    label: l10n.availabilityLabel,
                    value: doctor.availability(language),
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: PhosphorIconsRegular.wallet,
                    label: l10n.consultationFee,
                    value: l10n.money(doctor.fee),
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: PhosphorIconsRegular.mapPin,
                    label: l10n.locationLabel,
                    value: Clinic.address(language),
                  ),
                ],
              ),
            ),
            if (doctor.isSpecialist) ...[
              const SizedBox(height: 8),
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
                    minimumSize: const Size(0, 36),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(PhosphorIconsRegular.calendarDots, size: 17),
                  label: Text(l10n.viewSaturdaySchedule),
                ),
              ),
            ],
            const SizedBox(height: 26),
            Text(l10n.aboutDoctor, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              doctor.bio(language),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
            ),
            if (doctor.visiting) ...[
              const SizedBox(height: 20),
              AppCard(
                color: scheme.secondaryContainer,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIconsRegular.megaphone,
                      size: 20,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.visitingNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.55,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (doctor.isSpecialist) ...[
              FilledButton.icon(
                onPressed: () async {
                  final created = await startBooking(
                    context,
                    departmentId: doctor.departmentId,
                    doctorId: doctor.id,
                  );
                  if (created == true && context.mounted) {
                    showAppSnack(context, l10n.appointmentConfirmedSnack);
                  }
                },
                icon: const Icon(PhosphorIconsRegular.calendarPlus, size: 18),
                label: Text(l10n.bookAppointment),
              ),
              const SizedBox(height: 10),
              Text(
                '${l10n.specialistOnlyNote} ${l10n.payAtClinic}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ] else
              AppCard(
                color: scheme.surfaceContainer,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIconsRegular.info,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.walkInNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.55,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: scheme.onSurfaceVariant),
        const SizedBox(width: 12),
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
