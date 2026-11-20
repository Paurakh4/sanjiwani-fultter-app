import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/l10n.dart';
import '../core/saturday_schedule.dart';
import '../core/slot_availability.dart';
import '../core/tokens.dart';
import '../data/backend.dart';
import '../data/catalog.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_refresh.dart';
import '../widgets/booking_pickers.dart';
import '../widgets/common.dart';
import 'saturday_schedule_screen.dart';

Future<bool?> startBooking(
  BuildContext context, {
  String? departmentId,
  String? doctorId,
  DateTime? initialDate,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => BookingScreen(
        initialDepartmentId: departmentId,
        initialDoctorId: doctorId,
        initialDate: initialDate,
      ),
    ),
  );
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    this.initialDepartmentId,
    this.initialDoctorId,
    this.initialDate,
  });

  final String? initialDepartmentId;
  final String? initialDoctorId;
  final DateTime? initialDate;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final ScrollController _dateController;
  late final String _initialName;
  late final String _initialPhone;
  late Department _department;
  late Doctor _doctor;
  late DateTime _date;
  late final DateTime _initialDate;
  late final String _initialDoctorId;
  late final String _initialDepartmentId;
  bool _submitting = false;
  bool _done = false;

  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();

    final requested = departmentByIdOrNull(widget.initialDepartmentId);
    Doctor? initialDoctor;
    if (requested != null &&
        bookableDepartments.any((item) => item.id == requested.id)) {
      initialDoctor = _doctorFor(requested, widget.initialDoctorId);
    } else {
      final nextDoctors = saturdayDoctorsForDate(
        nextBookableSaturday(DateTime.now()),
      );
      initialDoctor = nextDoctors.isEmpty ? null : nextDoctors.first;
    }
    _doctor = initialDoctor ?? specialistDoctors.first;
    _department = departmentById(_doctor.departmentId);

    _dates = _upcomingSaturdays(8);
    final requestedDate = widget.initialDate;
    if (requestedDate != null &&
        _dates.any((date) => _sameDay(date, requestedDate)) &&
        _selectable(dateOnly(requestedDate))) {
      _date = dateOnly(requestedDate);
    } else {
      _date = _findFirstBookableDate(_doctor);
    }
    _initialDate = _date;
    _initialDoctorId = _doctor.id;
    _initialDepartmentId = _department.id;
    _dateController = ScrollController();
    _initialName = state.profile.name;
    _initialPhone = state.profile.phone;
    _nameController = TextEditingController(text: _initialName);
    _phoneController = TextEditingController(text: _initialPhone);
    _scrollToSelectedDate(animate: false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  bool get _dirty =>
      !_done &&
      (_nameController.text != _initialName ||
          _phoneController.text != _initialPhone ||
          !_sameDay(_date, _initialDate) ||
          _doctor.id != _initialDoctorId ||
          _department.id != _initialDepartmentId);

  List<DateTime> _upcomingSaturdays(int count) {
    final start = nextBookableSaturday(DateTime.now());
    return [for (var i = 0; i < count; i++) start.add(Duration(days: 7 * i))];
  }

  Doctor? _doctorFor(Department department, [String? preferredId]) {
    final candidates = doctorsForDepartment(department.id)
        .where((doctor) => doctor.isSpecialist)
        .toList();
    if (preferredId != null) {
      for (final doctor in candidates) {
        if (doctor.id == preferredId) return doctor;
      }
    }
    return candidates.isEmpty ? null : candidates.first;
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
      final target = (index * (kDateChipWidth + kDateChipGap)).clamp(
        0.0,
        _dateController.position.maxScrollExtent,
      );
      if (animate) {
        _dateController.animateTo(
          target,
          duration: AppTokens.motionMedium,
          curve: AppTokens.ease,
        );
      } else {
        _dateController.jumpTo(target);
      }
    });
  }

  bool _selectable(DateTime date, [Doctor? doctor]) {
    final target = doctor ?? _doctor;
    return isDateBookable(doctor: target, date: date) &&
        !hasBookingOn(
          appointments: context.read<AppState>().appointments,
          doctorId: target.id,
          date: date,
        );
  }

  DateTime _findFirstBookableDate(Doctor doctor) {
    for (final candidate in _dates) {
      if (_selectable(candidate, doctor)) return candidate;
    }
    for (final candidate in _dates) {
      if (doctorScheduledOn(doctor, candidate)) return candidate;
    }
    return _dates.first;
  }

  void _selectDepartment(Department department) {
    final doctor = _doctorFor(department);
    if (doctor == null) return;
    setState(() {
      _department = department;
      _doctor = doctor;
      if (!_selectable(_date)) {
        _date = _findFirstBookableDate(_doctor);
        _scrollToSelectedDate();
      }
    });
  }

  void _selectDate(DateTime date) {
    if (!_selectable(date)) return;
    setState(() => _date = date);
  }

  void _selectDoctor(Doctor doctor) {
    setState(() {
      _doctor = doctor;
      if (!_selectable(_date, doctor)) {
        _date = _findFirstBookableDate(doctor);
        _scrollToSelectedDate();
      }
    });
  }

  String? get _doctorHours {
    final start = _doctor.startTime;
    final end = _doctor.endTime;
    if (start == null || end == null) return null;
    return L10n.of(context).timeRange(start, end);
  }

  /// The server says why a date cannot be booked; the patient hears it in
  /// their own language rather than as an error string from the clinic's API.
  static String _rejectionText(L10n l10n, BookingFailure? failure) =>
      switch (failure) {
        BookingFailure.offline => l10n.signInNetworkError,
        BookingFailure.notScheduled => l10n.bookingNotScheduledSnack,
        BookingFailure.alreadyBooked => l10n.alreadyBookedSnack,
        BookingFailure.full => l10n.bookingFullSnack,
        BookingFailure.past || BookingFailure.cutoff => l10n.bookingDatePassedSnack,
        _ => l10n.bookingFailedSnack,
      };

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = L10n.of(context);
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final state = context.read<AppState>();
    if (!_selectable(_date)) {
      showAppSnack(context, l10n.alreadyBookedSnack);
      return;
    }

    setState(() => _submitting = true);
    final result = await runWithLogoLoading<BookingResult>(
      context,
      () => state.bookAppointment(
        department: _department,
        doctor: _doctor,
        date: _date,
        patientName: _nameController.text,
        phone: _phoneController.text,
      ),
      minimum: const Duration(milliseconds: 1200),
      barrierLabel: l10n.loading,
    );

    if (!mounted) return;
    final confirmed = result.appointment;
    if (confirmed == null) {
      setState(() => _submitting = false);
      showAppSnack(context, _rejectionText(l10n, result.failure));
      return;
    }
    _done = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;
        final dialogL10n = L10n.of(dialogContext);
        return AlertDialog(
          icon: TonalIcon(
            icon: CoolIcons.check,
            size: 56,
            iconSize: 28,
            background: scheme.primary,
            foreground: scheme.onPrimary,
          ),
          title: Text(dialogL10n.appointmentConfirmedTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DateText(
                date: confirmed.date,
                crossAxisAlignment: CrossAxisAlignment.center,
                primaryStyle: theme.textTheme.titleMedium,
                secondaryStyle: theme.textTheme.bodySmall,
              ),
              if (_doctorHours != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${dialogL10n.doctorHours} · $_doctorHours',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
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

  Future<void> _confirmDiscard() async {
    final l10n = L10n.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.discardTitle),
        content: Text(l10n.discardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.keepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.discardChanges),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final departmentDoctors = doctorsForDepartment(_department.id)
        .where((doctor) => doctor.isSpecialist)
        .toList();

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(l10n.bookingNew),
        ),
        body: AppRefreshView(
          child: Form(
            key: _formKey,
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
                  l10n.bookingIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoNote(
                  icon: CoolIcons.calendarCheck,
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
                BookingDateRail(
                  doctor: _doctor,
                  dates: _doctorDates,
                  selectedDate: _date,
                  onSelected: _selectDate,
                  controller: _dateController,
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
                      minimumSize: const Size(0, AppTokens.minTap),
                    ),
                    icon: const Icon(CoolIcons.calendarDots, size: 17),
                    label: Text(l10n.viewSaturdaySchedule),
                  ),
                ),
                const SizedBox(height: 22),
                _StepTitle(number: '4', title: l10n.bookingStepPatient),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: l10n.bookingPatientNameHint,
                    prefixIcon: const Icon(CoolIcons.user),
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
                    prefixIcon: const Icon(CoolIcons.phone),
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
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  ),
                  child: Column(
                    children: [
                      DetailRow(
                        label: l10n.summaryDepartment,
                        value: _department.displayName,
                      ),
                      const SizedBox(height: 10),
                      DetailRow(
                        label: l10n.summaryDoctor,
                        value: _doctor.displayName,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              l10n.summaryDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(flex: 3, child: DateText(date: _date)),
                        ],
                      ),
                      _doctorHours == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: DetailRow(
                                label: l10n.doctorHours,
                                value: _doctorHours!,
                              ),
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
                  onPressed: _submitting ? null : _submit,
                  child: Text(l10n.confirmAppointment),
                ),
              ],
            ),
          ),
        ),
      ),
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
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusField),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                  selected ? CoolIcons.checkCircleFill : CoolIcons.circle,
                  size: 22,
                  color: selected ? scheme.primary : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
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
