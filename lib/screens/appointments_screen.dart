import 'package:flutter/material.dart';

import '../core/icons.dart';

import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/tokens.dart';
import '../data/demo_data.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';
import 'appointment_detail_screen.dart';
import 'booking_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _showUpcoming = true;

  Future<void> _book() async {
    final created = await startBooking(context);
    if (created == true && mounted) {
      setState(() => _showUpcoming = true);
    }
  }

  void _openDetail(Appointment appointment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppointmentDetailScreen(appointmentId: appointment.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = L10n.of(context);
    final upcoming = state.upcomingAppointments;
    final past = state.pastAppointments;
    final appointments = _showUpcoming ? upcoming : past;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabPageHeader(
            title: l10n.appointmentsTitle,
            subtitle: l10n.appointmentsSubtitle,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.gutter),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _book,
                icon: const Icon(CoolIcons.plus, size: 20),
                label: Text(l10n.newAppointment),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.gutter),
            child: PillTabBar(
              labels: [
                '${l10n.tabUpcoming}  ${l10n.digits(upcoming.length)}',
                '${l10n.tabPast}  ${l10n.digits(past.length)}',
              ],
              selectedIndex: _showUpcoming ? 0 : 1,
              onChanged: (index) => setState(() => _showUpcoming = index == 0),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: appointments.isEmpty
                ? AppRefreshEmpty(
                    onRefresh: demoRefresh,
                    child: _showUpcoming
                        ? EmptyState(
                            icon: CoolIcons.calendarCheck,
                            title: l10n.emptyUpcomingTitle,
                            message: l10n.emptyUpcomingMessage,
                            action: FilledButton.icon(
                              onPressed: _book,
                              icon: const Icon(CoolIcons.plus, size: 18),
                              label: Text(l10n.bookSlot),
                            ),
                          )
                        : EmptyState(
                            icon: CoolIcons.clockCounterClockwise,
                            title: l10n.emptyPastTitle,
                            message: l10n.emptyPastMessage,
                          ),
                  )
                : AppRefreshView(
                    onRefresh: demoRefresh,
                    child: ListView.separated(
                      controller: widget.scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.gutter,
                        12,
                        AppTokens.gutter,
                        32,
                      ),
                      itemCount: appointments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        return _AppointmentCard(
                          appointment: appointment,
                          onTap: () => _openDetail(appointment),
                          onCancel: _showUpcoming
                              ? () =>
                                    cancelAppointmentFlow(context, appointment)
                              : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
    this.onCancel,
  });

  final Appointment appointment;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final doctor = doctorById(appointment.doctorId);
    final department = departmentById(appointment.departmentId);
    final doctorName =
        doctor?.displayName ??
        (appointment.doctorId == null
            ? l10n.clinicServiceName
            : appointment.doctorName);
    final departmentName = department.displayName;

    final cancelled = appointment.status == AppointmentStatus.cancelled;
    final completed =
        appointment.status == AppointmentStatus.completed ||
        (appointment.status == AppointmentStatus.booked &&
            !appointment.isUpcoming);

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

    final active = !cancelled && !completed;
    final dateBackground = active
        ? scheme.primaryContainer
        : scheme.surfaceContainerHigh;
    final dateForeground = active
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (doctor != null)
                DoctorAvatar(doctor: doctor, size: 50)
              else
                TonalIcon(icon: CoolIcons.stethoscope, size: 50, iconSize: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: label,
                background: background,
                foreground: foreground,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: dateBackground,
              borderRadius: BorderRadius.circular(AppTokens.radiusInner),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CoolIcons.calendarBlank, size: 17, color: dateForeground),
                const SizedBox(width: 8),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.patientLabel(l10n.personName(appointment.patientName)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (appointment.fee > 0) ...[
                const SizedBox(width: 12),
                Text(
                  l10n.money(appointment.fee),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (onCancel != null) ...[
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.error,
                    minimumSize: const Size(0, AppTokens.minTap),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(CoolIcons.x, size: 15),
                  label: Text(l10n.cancelAppointment),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
