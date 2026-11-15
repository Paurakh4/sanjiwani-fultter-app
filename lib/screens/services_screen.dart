import 'package:flutter/material.dart';

import '../core/icons.dart';

import '../core/l10n.dart';
import '../data/demo_data.dart';
import '../models.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';
import 'booking_screen.dart';
import 'department_detail_screen.dart';
import 'doctor_detail_screen.dart';
import 'saturday_schedule_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, this.showDepartmentsInitially = false});

  final bool showDepartmentsInitially;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late bool _showDepartments;
  String? _departmentFilter;

  @override
  void initState() {
    super.initState();
    _showDepartments = widget.showDepartmentsInitially;
  }

  Future<void> _bookDoctor(Doctor doctor) async {
    final l10n = L10n.of(context);
    final created = await startBooking(
      context,
      departmentId: doctor.departmentId,
      doctorId: doctor.id,
    );
    if (created == true && mounted) {
      showAppSnack(context, l10n.appointmentConfirmedSnack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.servicesTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: PillTabBar(
              labels: [l10n.tabDoctors, l10n.tabDepartments],
              selectedIndex: _showDepartments ? 1 : 0,
              onChanged: (index) {
                setState(() => _showDepartments = index == 1);
              },
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _showDepartments
                  ? _buildDepartments(context)
                  : _buildDoctors(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctors(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final filtered =
        _departmentFilter == null
              ? ([
                  ...specialistDoctors,
                  ...doctors.where((d) => !d.isSpecialist),
                ])
              : doctors
                    .where((doctor) => doctor.departmentId == _departmentFilter)
                    .toList()
          ..sort((a, b) {
            if (a.isSpecialist == b.isSpecialist) return 0;
            return a.isSpecialist ? -1 : 1;
          });
    final doctorFilters = departments
        .where((department) => department.doctorIds.isNotEmpty)
        .toList();

    return Column(
      key: const ValueKey('doctors'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              ChoicePill(
                label: l10n.all,
                selected: _departmentFilter == null,
                onTap: () => setState(() => _departmentFilter = null),
              ),
              for (final department in doctorFilters) ...[
                const SizedBox(width: 8),
                ChoicePill(
                  label: department.displayName,
                  selected: _departmentFilter == department.id,
                  onTap: () =>
                      setState(() => _departmentFilter = department.id),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SaturdayScheduleScreen(),
              ),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.calendarDots,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.specialistRotationNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    PhosphorIconsRegular.caretRight,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? AppRefreshEmpty(
                  onRefresh: demoRefresh,
                  child: EmptyState(
                    icon: PhosphorIconsRegular.stethoscope,
                    title: l10n.noDoctorsTitle,
                    message: l10n.noDoctorsMessage,
                  ),
                )
              : AppRefreshView(
                  onRefresh: demoRefresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doctor = filtered[index];
                      return _DoctorListCard(
                        doctor: doctor,
                        onBook: () => _bookDoctor(doctor),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDepartments(BuildContext context) {
    return AppRefreshView(
      key: const ValueKey('departments'),
      onRefresh: demoRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        itemCount: departments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final department = departments[index];
          return _DepartmentListCard(department: department);
        },
      ),
    );
  }
}

class _DoctorListCard extends StatelessWidget {
  const _DoctorListCard({required this.doctor, required this.onBook});

  final Doctor doctor;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final language = l10n.language;
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DoctorDetailScreen(doctor: doctor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DoctorAvatar(doctor: doctor, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doctor.displaySpecialty} · ${doctor.qualification}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (doctor.visiting)
                StatusPill(
                  label: l10n.visiting,
                  background: scheme.secondaryContainer,
                  foreground: scheme.onSecondaryContainer,
                )
              else if (!doctor.isSpecialist)
                StatusPill(
                  label: l10n.walkInOnly,
                  background: scheme.surfaceContainerHighest,
                  foreground: scheme.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                PhosphorIconsRegular.clock,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  doctor.availability(language),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.money(doctor.fee),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (doctor.isSpecialist)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onBook,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: Text(l10n.bookAppointment),
              ),
            )
          else
            Text(
              l10n.walkInNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
        ],
      ),
    );
  }
}

class _DepartmentListCard extends StatelessWidget {
  const _DepartmentListCard({required this.department});

  final Department department;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final language = l10n.language;
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DepartmentDetailScreen(department: department),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TonalIcon(icon: department.icon, size: 48, iconSize: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  department.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 15.5),
                ),
                const SizedBox(height: 3),
                Text(
                  department.description(language),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  department.doctorIds.isEmpty
                      ? l10n.serviceAvailable
                      : l10n.doctorCount(department.doctorIds.length),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(PhosphorIconsRegular.caretRight, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
