import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/saturday_schedule.dart';
import '../core/slot_availability.dart';
import '../core/tokens.dart';
import '../data/catalog.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/booking_pickers.dart';
import '../widgets/common.dart';

/// Reschedule an existing appointment with the same doctor. Returns true when
/// the appointment was moved; the caller shows the confirmation snackbar.
Future<bool?> showRescheduleSheet(
  BuildContext context,
  Appointment appointment,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RescheduleSheet(appointment: appointment),
  );
}

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({required this.appointment});

  final Appointment appointment;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late final Doctor _doctor;
  late final List<DateTime> _dates;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _doctor = doctorById(widget.appointment.doctorId)!;
    final start = nextBookableSaturday(DateTime.now());
    _dates = [for (var i = 0; i < 8; i++) start.add(Duration(days: 7 * i))];
    _date = _initialDate();
  }

  List<DateTime> get _doctorDates => [
    for (final date in _dates)
      if (doctorScheduledOn(_doctor, date)) date,
  ];

  DateTime _initialDate() {
    final current = widget.appointment.date;
    for (final date in _doctorDates) {
      if (_sameDay(date, current)) return date;
    }
    for (final date in _doctorDates) {
      if (isDateBookable(doctor: _doctor, date: date)) return date;
    }
    return _doctorDates.isEmpty ? current : _doctorDates.first;
  }

  Future<void> _confirm() async {
    final l10n = L10n.of(context);
    final state = context.read<AppState>();
    final ok = await state.rescheduleAppointment(
      widget.appointment.id,
      date: _date,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      showAppSnack(
        context,
        state.offline ? l10n.signInNetworkError : l10n.alreadyBookedSnack,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.rescheduleTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                l10n.rescheduleIntro,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  DoctorAvatar(doctor: _doctor, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _doctor.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          _doctor.displaySpecialty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BookingDateRail(
                doctor: _doctor,
                dates: _doctorDates,
                selectedDate: _date,
                onSelected: (date) => setState(() => _date = date),
                excludingAppointmentId: widget.appointment.id,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppTokens.radiusInner),
                ),
                child: DateText(date: _date),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _confirm,
                  child: Text(l10n.reschedule),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
