import 'package:flutter/material.dart';

import '../core/icons.dart';

import 'package:provider/provider.dart';

import '../core/clinic.dart';
import '../core/l10n.dart';
import '../core/saturday_schedule.dart';
import '../data/demo_data.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';
import 'saturday_schedule_screen.dart';

Future<bool?> startBooking(
  BuildContext context, {
  String? departmentId,
  String? doctorId,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => BookingScreen(
        initialDepartmentId: departmentId,
        initialDoctorId: doctorId,
      ),
    ),
  );
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    this.initialDepartmentId,
    this.initialDoctorId,
  });

  final String? initialDepartmentId;
  final String? initialDoctorId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const _dateChipWidth = 122.0;
  static const _dateChipGap = 8.0;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final ScrollController _dateController;
  late Department _department;
  late Doctor _doctor;
  late DateTime _date;
  String? _slot;
  bool _submitting = false;

  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();

    final requested = departmentByIdOrNull(widget.initialDepartmentId);
    if (requested != null &&
        bookableDepartments.any((item) => item.id == requested.id)) {
      _department = requested;
      _doctor = _doctorFor(_department, widget.initialDoctorId);
    } else {
      final nextDoctors = saturdayDoctorsForDate(
        nextSaturdayFrom(DateTime.now()),
      );
      final defaultDoctor = nextDoctors.isEmpty ? null : nextDoctors.first;
      _department = defaultDoctor == null
          ? bookableDepartments.first
          : departmentById(defaultDoctor.departmentId);
      _doctor = defaultDoctor ?? _doctorFor(_department);
    }

    _dates = _upcomingSaturdays(8);
    _date = _findFirstBookableDate(_doctor);
    _dateController = ScrollController();
    _nameController = TextEditingController(text: state.profile.name);
    _phoneController = TextEditingController(text: state.profile.phone);
    _scrollToSelectedDate(animate: false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  List<DateTime> _upcomingSaturdays(int count) {
    final now = DateTime.now();
    var candidate = DateTime(now.year, now.month, now.day);
    while (candidate.weekday != DateTime.saturday) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return [
      for (var i = 0; i < count; i++) candidate.add(Duration(days: 7 * i)),
    ];
  }

  Doctor _doctorFor(Department department, [String? preferredId]) {
    final candidates = doctorsForDepartment(department.id)
        .where((doctor) => doctor.isSpecialist)
        .toList();
    if (preferredId != null) {
      for (final doctor in candidates) {
        if (doctor.id == preferredId) return doctor;
      }
    }
    return candidates.first;
  }

  List<DateTime> get _doctorDates => [
    for (final date in _dates)
      if (doctorScheduledOn(_doctor, date)) date,
  ];

  void _scrollToSelectedDate({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_dateController.hasClients) return;
      final index = _doctorDates.indexWhere((date) => _sameDay(date, _date));
      if (index < 0) return;
      final target = (index * (_dateChipWidth + _dateChipGap)).clamp(
        0.0,
        _dateController.position.maxScrollExtent,
      );
      if (animate) {
        _dateController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        _dateController.jumpTo(target);
      }
    });
  }

  DateTime _findFirstBookableDate(Doctor doctor) {
    DateTime? firstScheduled;
    for (final candidate in _dates) {
      if (!doctorScheduledOn(doctor, candidate)) continue;
      firstScheduled ??= candidate;
      if (_hasAnyAvailableSlot(doctor, candidate)) return candidate;
    }
    return firstScheduled ?? _dates.first;
  }

  bool _hasAnyAvailableSlot(Doctor doctor, DateTime date) {
    if (!doctorScheduledOn(doctor, date)) return false;
    for (final shift in SlotShift.values) {
      if (!doctor.shifts.contains(shift)) continue;
      for (final slot in clinicSlots[shift] ?? const <String>[]) {
        if (_isSlotAvailableFor(doctor, date, slot)) return true;
      }
    }
    return false;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSlotAvailable(String slot) =>
      _isSlotAvailableFor(_doctor, _date, slot);

  bool _isSlotAvailableFor(Doctor doctor, DateTime date, String slot) {
    if (!doctorScheduledOn(doctor, date)) return false;
    final parts = slot.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    if (hour >= Clinic.closeHour) return false;

    if (doctor.startTime != null && slot.compareTo(doctor.startTime!) < 0) {
      return false;
    }
    if (doctor.endTime != null && slot.compareTo(doctor.endTime!) >= 0) {
      return false;
    }

    if (_isToday(date)) {
      final now = DateTime.now();
      final slotTime = DateTime(date.year, date.month, date.day, hour, minute);
      if (slotTime.isBefore(now.add(const Duration(minutes: 30)))) {
        return false;
      }
    }

    final seed = '${doctor.id}-${date.year}-${date.month}-${date.day}-$slot';
    var hash = 7;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash % 6 != 0;
  }

  void _selectDepartment(Department department) {
    setState(() {
      _department = department;
      _doctor = _doctorFor(department);
      _slot = null;
      if (!_hasAnyAvailableSlot(_doctor, _date)) {
        _date = _findFirstBookableDate(_doctor);
        _scrollToSelectedDate();
      }
    });
  }

  void _selectDate(DateTime date) {
    if (!_hasAnyAvailableSlot(_doctor, date)) return;
    setState(() {
      _date = date;
      _slot = null;
    });
  }

  void _selectDoctor(Doctor doctor) {
    setState(() {
      _doctor = doctor;
      _slot = null;
      if (!_hasAnyAvailableSlot(doctor, _date)) {
        _date = _findFirstBookableDate(doctor);
        _scrollToSelectedDate();
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = L10n.of(context);
    FocusScope.of(context).unfocus();
    if (_slot == null) {
      showAppSnack(context, l10n.chooseSlotSnack);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final state = context.read<AppState>();
    late final Appointment appointment;
    try {
      appointment = await runWithLogoLoading(context, () async {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        return state.bookAppointment(
          department: _department,
          doctor: _doctor,
          date: _date,
          slot: _slot!,
          patientName: _nameController.text,
          phone: _phoneController.text,
        );
      });
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
      rethrow;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;
        final dialogL10n = L10n.of(dialogContext);
        return AlertDialog(
          icon: TonalIcon(
            icon: PhosphorIconsRegular.check,
            size: 56,
            iconSize: 28,
            background: scheme.primary,
            foreground: scheme.onPrimary,
          ),
          title: Text(dialogL10n.appointmentConfirmedTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dialogL10n.weekdayBoth(appointment.date),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dialogL10n.dateBoth(appointment.date),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dialogL10n.appointmentTime(appointment.slot),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(
                '${_department.displayName}\n${_doctor.displayName}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop(true);
                },
                child: Text(dialogL10n.okay),
              ),
            ),
          ],
        );
      },
    );
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final departmentDoctors = doctorsForDepartment(_department.id)
        .where((doctor) => doctor.isSpecialist)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingNew)),
      body: AppRefreshView(
        onRefresh: demoRefresh,
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 40),
            children: [
              Text(
                l10n.bookingIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _InfoNote(
                icon: PhosphorIconsRegular.calendarCheck,
                text: l10n.bookingSaturdayNote,
              ),
              const SizedBox(height: 24),
              _StepTitle(number: '1', title: l10n.bookingStepDepartment),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final department in bookableDepartments)
                    ChoicePill(
                      label: department.displayName,
                      selected: department.id == _department.id,
                      onTap: () => _selectDepartment(department),
                    ),
                ],
              ),
              const SizedBox(height: 26),
              _StepTitle(number: '2', title: l10n.bookingStepDoctor),
              const SizedBox(height: 12),
              for (final doctor in departmentDoctors) ...[
                _DoctorChoice(
                  doctor: doctor,
                  selected: doctor.id == _doctor.id,
                  onTap: () => _selectDoctor(doctor),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 18),
              _StepTitle(number: '3', title: l10n.bookingStepDate),
              const SizedBox(height: 12),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  controller: _dateController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _doctorDates.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: _dateChipGap),
                  itemBuilder: (context, index) {
                    final date = _doctorDates[index];
                    return _DateChip(
                      date: date,
                      scheduleLabel: _doctor.saturdayGroup == null
                          ? l10n.specialistHoursShort
                          : l10n.saturdayGroupShort(_doctor.saturdayGroup!),
                      selected: _sameDay(date, _date),
                      enabled: _hasAnyAvailableSlot(_doctor, date),
                      onTap: () => _selectDate(date),
                    );
                  },
                ),
              ),
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
              const SizedBox(height: 18),
              _StepTitle(number: '4', title: l10n.bookingStepTime),
              const SizedBox(height: 12),
              _buildSlots(theme, scheme, l10n),
              const SizedBox(height: 26),
              _StepTitle(number: '5', title: l10n.bookingStepPatient),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: l10n.bookingPatientNameHint,
                  prefixIcon: const Icon(PhosphorIconsRegular.user),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.bookingNameError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: l10n.bookingPhoneHint,
                  prefixIcon: const Icon(PhosphorIconsRegular.phone),
                ),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(
                    RegExp(r'[^0-9०-९]'),
                    '',
                  );
                  if (digits.length < 7) {
                    return l10n.bookingPhoneError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: l10n.summaryDepartment,
                      value: _department.displayName,
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: l10n.summaryDoctor,
                      value: _doctor.displayName,
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: l10n.summaryDate,
                      value:
                          '${l10n.weekdayBoth(_date)}\n${l10n.dateBoth(_date)}',
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: l10n.summaryTime,
                      value: _slot == null
                          ? l10n.summaryNotSelected
                          : l10n.appointmentTime(_slot!),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          l10n.summaryFee,
                          style: theme.textTheme.titleSmall,
                        ),
                        const Spacer(),
                        Text(
                          l10n.money(_doctor.fee),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.bookingNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                child: Text(l10n.confirmAppointment),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlots(ThemeData theme, ColorScheme scheme, L10n l10n) {
    var hasAvailable = false;
    final labels = {
      SlotShift.morning: l10n.shiftMorning,
      SlotShift.afternoon: l10n.shiftAfternoon,
      SlotShift.evening: l10n.shiftEvening,
    };

    final groups = <Widget>[];
    for (final shift in SlotShift.values) {
      if (!_doctor.shifts.contains(shift)) continue;
      final slots = clinicSlots[shift] ?? const <String>[];
      if (slots.isEmpty) continue;

      final children = <Widget>[];
      for (final slot in slots) {
        if (!_isSlotAvailable(slot)) continue;
        hasAvailable = true;
        children.add(
          ChoicePill(
            label: l10n.timeShort(slot),
            selected: _slot == slot,
            onTap: () => setState(() => _slot = slot),
          ),
        );
      }
      if (children.isEmpty) continue;

      groups.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labels[shift]!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: children),
            ],
          ),
        ),
      );
    }

    if (!hasAvailable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoNote(
            icon: PhosphorIconsRegular.calendarX,
            text: l10n.bookingNoSlots,
          ),
          const SizedBox(height: 12),
          ...groups,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups,
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            L10n.of(context).digits(number),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
      ],
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
  });

  final DateTime date;
  final String scheduleLabel;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
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

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: _BookingScreenState._dateChipWidth,
          height: 88,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dateChipAd(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.dateChipBs(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.calendarBlank,
                      size: 12,
                      color: selected
                          ? scheme.onPrimary.withValues(alpha: 0.85)
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      scheduleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        color: selected
                            ? scheme.onPrimary.withValues(alpha: 0.85)
                            : scheme.onSurfaceVariant,
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
  }
}

class _DoctorChoice extends StatelessWidget {
  const _DoctorChoice({
    required this.doctor,
    required this.selected,
    required this.onTap,
  });

  final Doctor doctor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? scheme.primary : Colors.transparent,
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              DoctorAvatar(doctor: doctor, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.displaySpecialty,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.bookingDoctorNote(
                        doctor.availability(l10n.language),
                        doctor.fee,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? PhosphorIconsFill.checkCircle
                    : PhosphorIconsRegular.circle,
                size: 22,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
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

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.icon, required this.text});

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
        borderRadius: BorderRadius.circular(16),
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
