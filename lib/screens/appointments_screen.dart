import 'package:flutter/material.dart';

import '../core/icons.dart';

import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../data/demo_data.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';
import 'booking_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _showUpcoming = true;

  Future<void> _book() async {
    final l10n = L10n.of(context);
    final created = await startBooking(context);
    if (created == true && mounted) {
      setState(() => _showUpcoming = true);
      showAppSnack(context, l10n.appointmentConfirmedSnack);
    }
  }

  Future<void> _cancel(Appointment appointment) async {
    final l10n = L10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = L10n.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.cancelDialogTitle),
          content: Text(
            dialogL10n.cancelDialogBody(appointment.date, appointment.slot),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogL10n.keep),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: Text(dialogL10n.cancel),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    context.read<AppState>().cancelAppointment(appointment.id);
    showAppSnack(context, l10n.cancelDoneSnack);
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _book,
                icon: const Icon(PhosphorIconsRegular.plus, size: 20),
                label: Text(l10n.newAppointment),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _TabSwitcher(
              showUpcoming: _showUpcoming,
              upcomingCount: upcoming.length,
              pastCount: past.length,
              onChanged: (value) => setState(() => _showUpcoming = value),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: appointments.isEmpty
                ? AppRefreshEmpty(
                    onRefresh: demoRefresh,
                    child: _showUpcoming
                        ? EmptyState(
                            icon: PhosphorIconsRegular.calendarCheck,
                            title: l10n.emptyUpcomingTitle,
                            message: l10n.emptyUpcomingMessage,
                            action: FilledButton.icon(
                              onPressed: _book,
                              icon: const Icon(
                                PhosphorIconsRegular.plus,
                                size: 18,
                              ),
                              label: Text(l10n.bookSlot),
                            ),
                          )
                        : EmptyState(
                            icon: PhosphorIconsRegular.clockCounterClockwise,
                            title: l10n.emptyPastTitle,
                            message: l10n.emptyPastMessage,
                          ),
                  )
                : AppRefreshView(
                    onRefresh: demoRefresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                      itemCount: appointments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        return _AppointmentCard(
                          appointment: appointment,
                          onCancel: _showUpcoming
                              ? () => _cancel(appointment)
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

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.showUpcoming,
    required this.upcomingCount,
    required this.pastCount,
    required this.onChanged,
  });

  final bool showUpcoming;
  final int upcomingCount;
  final int pastCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: '${l10n.tabUpcoming}  ${l10n.digits(upcomingCount)}',
              selected: showUpcoming,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _Segment(
              label: '${l10n.tabPast}  ${l10n.digits(pastCount)}',
              selected: !showUpcoming,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, this.onCancel});

  final Appointment appointment;
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
    final effectiveCompleted =
        appointment.status == AppointmentStatus.completed ||
        (appointment.status == AppointmentStatus.booked &&
            !appointment.isUpcoming);

    final (label, background, foreground) = cancelled
        ? (l10n.statusCancelled, scheme.errorContainer, scheme.onErrorContainer)
        : effectiveCompleted
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

    final active = !cancelled && !effectiveCompleted;
    final dateBackground = active
        ? scheme.primaryContainer
        : scheme.surfaceContainerHigh;
    final dateForeground = active
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return AppCard(
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
                TonalIcon(
                  icon: PhosphorIconsRegular.stethoscope,
                  size: 50,
                  iconSize: 24,
                ),
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
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  PhosphorIconsRegular.calendarBlank,
                  size: 17,
                  color: dateForeground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.weekdayBoth(appointment.date),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: dateForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        l10n.dateBothShort(appointment.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: dateForeground,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      PhosphorIconsRegular.clock,
                      size: 15,
                      color: dateForeground,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.appointmentTime(appointment.slot),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: dateForeground,
                        fontWeight: FontWeight.w600,
                      ),
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
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(PhosphorIconsRegular.x, size: 15),
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
