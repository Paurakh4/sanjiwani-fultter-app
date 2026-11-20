import 'package:flutter/material.dart';

import '../core/icons.dart';

import '../core/l10n.dart';
import '../core/tokens.dart';
import '../data/catalog.dart';
import '../models.dart';
import '../widgets/app_refresh.dart';
import '../widgets/app_search_field.dart';
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
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _showDepartments = widget.showDepartmentsInitially;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bookDoctor(Doctor doctor) async {
    await startBooking(
      context,
      departmentId: doctor.departmentId,
      doctorId: doctor.id,
    );
  }

  void _switchTab(int index) {
    setState(() {
      _showDepartments = index == 1;
      _query = '';
      _searchController.clear();
    });
  }

  bool _doctorMatches(Doctor doctor, String query) {
    return doctor.nameNp.toLowerCase().contains(query) ||
        doctor.nameEn.toLowerCase().contains(query) ||
        doctor.specialtyNp.toLowerCase().contains(query) ||
        doctor.specialtyEn.toLowerCase().contains(query) ||
        doctor.qualification.toLowerCase().contains(query);
  }

  bool _departmentMatches(Department department, String query) {
    return department.nameNp.toLowerCase().contains(query) ||
        department.nameEn.toLowerCase().contains(query) ||
        department.descriptionNp.toLowerCase().contains(query) ||
        department.descriptionEn.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.servicesTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.gutter,
              4,
              AppTokens.gutter,
              12,
            ),
            child: PillTabBar(
              labels: [l10n.tabDoctors, l10n.tabDepartments],
              selectedIndex: _showDepartments ? 1 : 0,
              onChanged: _switchTab,
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppTokens.motionFast,
              switchInCurve: AppTokens.ease,
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
    var filtered = _departmentFilter == null
        ? ([...specialistDoctors, ...doctors.where((d) => !d.isSpecialist)])
        : doctors
              .where((doctor) => doctor.departmentId == _departmentFilter)
              .toList();
    filtered.sort((a, b) {
      if (a.isSpecialist == b.isSpecialist) return 0;
      return a.isSpecialist ? -1 : 1;
    });
    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((doctor) => _doctorMatches(doctor, query))
          .toList();
    }
    final doctorFilters = departments
        .where((department) => department.doctorIds.isNotEmpty)
        .toList();

    return Column(
      key: const ValueKey('doctors'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.gutter,
            0,
            AppTokens.gutter,
            10,
          ),
          child: AppSearchField(
            controller: _searchController,
            hint: l10n.searchDoctorsHint,
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.gutter),
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
          padding: const EdgeInsets.fromLTRB(
            AppTokens.gutter,
            4,
            AppTokens.gutter,
            4,
          ),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SaturdayScheduleScreen(),
              ),
            ),
            borderRadius: BorderRadius.circular(AppTokens.radiusCell),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppTokens.minTap),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      CoolIcons.calendarDots,
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
                      CoolIcons.caretRight,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? AppRefreshEmpty(
                  child: EmptyState(
                    icon: CoolIcons.stethoscope,
                    title: query.isNotEmpty
                        ? l10n.noResultsTitle
                        : l10n.noDoctorsTitle,
                    message: query.isNotEmpty
                        ? l10n.noResultsMessage
                        : l10n.noDoctorsMessage,
                  ),
                )
              : AppRefreshView(
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.gutter,
                      8,
                      AppTokens.gutter,
                      32,
                    ),
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
    final l10n = L10n.of(context);
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? departments
        : departments
              .where((department) => _departmentMatches(department, query))
              .toList();

    return Column(
      key: const ValueKey('departments'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.gutter,
            0,
            AppTokens.gutter,
            10,
          ),
          child: AppSearchField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? AppRefreshEmpty(
                  child: EmptyState(
                    icon: CoolIcons.folderOpen,
                    title: l10n.noResultsTitle,
                    message: l10n.noResultsMessage,
                  ),
                )
              : AppRefreshView(
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.gutter,
                      8,
                      AppTokens.gutter,
                      32,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final department = filtered[index];
                      return _DepartmentListCard(department: department);
                    },
                  ),
                ),
        ),
      ],
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
              Icon(CoolIcons.clock, size: 15, color: scheme.onSurfaceVariant),
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
                  minimumSize: const Size(0, AppTokens.minTap),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
          Icon(CoolIcons.caretRight, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
