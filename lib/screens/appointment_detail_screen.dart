import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/l10n.dart';
import '../core/launcher.dart';
import '../core/tokens.dart';
import '../data/catalog.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';
import 'doctor_detail_screen.dart';
import 'reschedule_sheet.dart';

class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = L10n.of(context);

    Appointment? appointment;
    for (final item in state.appointments) {
      if (item.id == appointmentId) {
        appointment = item;
        break;
      }
    }
    if (appointment == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final doctor = doctorById(appointment.doctorId);
    final departmentName =
        departmentByIdOrNull(appointment.departmentId)?.displayName ??
        appointment.departmentName;
    final doctorName =
        doctor?.displayName ??
        (appointment.doctorId == null
            ? l10n.clinicServiceName
            : appointment.doctorName);

    final cancelled = appointment.status == AppointmentStatus.cancelled;
    final completed = appointment.status == AppointmentStatus.completed;
    final active =
        appointment.status == AppointmentStatus.booked &&
        appointment.isUpcoming;

    final (label, background, foreground) = cancelled
        ? (l10n.statusCancelled, scheme.errorContainer, scheme.onErrorContainer)
        : completed
        ? (
            l10n.statusCompleted,
            scheme.surfaceContainerHighest,
            scheme.onSurfaceVariant,
          )
        : (
            l10n.statusUpcoming,
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
          );

    final dateBackground = active
        ? scheme.primaryContainer
        : scheme.surfaceContainerHigh;
    final dateForeground = active
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.appointmentDetailTitle),
      ),
      body: AppRefreshView(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTokens.gutter,
            4,
            AppTokens.gutter,
            40,
          ),
          children: [
            AppCard(
              onTap: doctor == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DoctorDetailScreen(doctor: doctor),
                      ),
                    ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (doctor != null)
                    DoctorAvatar(doctor: doctor, size: 56)
                  else
                    TonalIcon(
                      icon: CoolIcons.stethoscope,
                      size: 56,
                      iconSize: 26,
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          departmentName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StatusPill(
                          label: label,
                          background: background,
                          foreground: foreground,
                        ),
                      ],
                    ),
                  ),
                  if (doctor != null)
                    Icon(
                      CoolIcons.caretRight,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: dateBackground,
                borderRadius: BorderRadius.circular(AppTokens.radiusInner),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CoolIcons.calendarBlank,
                    size: 20,
                    color: dateForeground,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DateText(
                      date: appointment.date,
                      color: dateForeground,
                      mutedColor: dateForeground.withValues(alpha: 0.72),
                      primaryStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      secondaryStyle: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  DetailRow(
                    label: l10n.patientWord,
                    value: l10n.personName(appointment.patientName),
                  ),
                  const SizedBox(height: 12),
                  DetailRow(
                    label: l10n.summaryFee,
                    value: appointment.fee > 0
                        ? l10n.money(appointment.fee)
                        : l10n.payAtClinic,
                  ),
                  const SizedBox(height: 12),
                  DetailRow(
                    label: l10n.bookedLabel,
                    value: l10n.primaryDateMedium(
                      appointment.createdAt,
                      state.datePrimary,
                    ),
                  ),
                  if (doctor?.startTime != null && doctor?.endTime != null) ...[
                    const SizedBox(height: 12),
                    DetailRow(
                      label: l10n.doctorHours,
                      value: l10n.timeRange(
                        doctor!.startTime!,
                        doctor.endTime!,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.bookingNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (active) ...[
              FilledButton.icon(
                onPressed: () async {
                  final moved = await showRescheduleSheet(
                    context,
                    appointment!,
                  );
                  if (moved == true && context.mounted) {
                    showAppSnack(context, l10n.rescheduleDoneSnack);
                  }
                },
                icon: const Icon(CoolIcons.clockCounterClockwise, size: 18),
                label: Text(l10n.reschedule),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => cancelAppointmentFlow(context, appointment!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                  side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
                ),
                icon: const Icon(CoolIcons.x, size: 18),
                label: Text(l10n.cancelAppointment),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: () => callClinic(context),
              icon: const Icon(CoolIcons.phoneCall, size: 18),
              label: Text(l10n.callClinic),
            ),
          ],
        ),
      ),
    );
  }
}
