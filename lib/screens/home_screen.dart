import 'package:flutter/material.dart';

import '../core/icons.dart';

import 'package:provider/provider.dart';

import '../core/clinic.dart';
import '../core/l10n.dart';
import '../core/launcher.dart';
import '../core/saturday_schedule.dart';
import '../core/tokens.dart';
import '../data/demo_data.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';
import '../widgets/notice_carousel.dart';
import 'booking_screen.dart';
import 'contact_screen.dart';
import 'department_detail_screen.dart';
import 'doctor_detail_screen.dart';
import 'notifications_screen.dart';
import 'saturday_schedule_screen.dart';
import 'services_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenTab,
    required this.isActive,
    this.scrollController,
  });

  final ValueChanged<int> onOpenTab;
  final bool isActive;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final isOpen = Clinic.isOpenAt(now);
    final featuredDepartments = [
      departmentById('gyn'),
      departmentById('ortho'),
      departmentById('ent'),
      departmentById('derma'),
      departmentById('psych'),
      departmentById('echo'),
    ];
    final featuredDoctors = [
      for (final id in ['sunita', 'sujan', 'rajan', 'bikas'])
        if (doctorById(id) != null) doctorById(id)!,
    ];
    final nextSaturday = nextBookableSaturday(now);
    final nextSaturdayGroup = saturdayGroupForDate(nextSaturday);
    final nextSaturdayDoctors = saturdayDoctorsForDate(nextSaturday);

    return SafeArea(
      bottom: false,
      child: AppRefreshView(
        onRefresh: demoRefresh,
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTokens.gutter,
            10,
            AppTokens.gutter,
            36,
          ),
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
                        Text(
                          l10n.primaryDateLine(now, state.datePrimary),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.secondaryDateLine(now, state.datePrimary),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // The wave lives inside the greeting run so it shares
                        // the text baseline instead of floating beside it.
                        Text(
                          '${l10n.greeting(l10n.personName(state.profile.firstName))} 👋',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.homePrompt,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Badge.count(
                    count: state.unreadCount,
                    isLabelVisible: state.unreadCount > 0,
                    backgroundColor: scheme.primary,
                    textColor: scheme.onPrimary,
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                      tooltip: l10n.notificationsLabel,
                      icon: const Icon(CoolIcons.bell),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionHeader(title: l10n.noticesTitle),
              const SizedBox(height: 12),
              NoticeCarousel(notices: notices, active: isActive),
              const SizedBox(height: AppTokens.sectionGap),
              Row(
                // Start-aligned so the reports action can carry its
                // coming-soon line without pushing the other circles off line.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: CoolIcons.calendarPlus,
                      label: l10n.quickBook,
                      onTap: () => _startBooking(context),
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: CoolIcons.stethoscope,
                      label: l10n.quickDoctors,
                      onTap: () => _openServices(context),
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: CoolIcons.fileText,
                      label: l10n.quickReports,
                      comingSoon: true,
                      onTap: () => onOpenTab(2),
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: CoolIcons.phoneCall,
                      label: l10n.quickContact,
                      onTap: () => _openContact(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.sectionGap),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                onTap: () => _openContact(context),
                child: Row(
                  children: [
                    TonalIcon(
                      icon: CoolIcons.clock,
                      background: isOpen
                          ? scheme.primary
                          : scheme.surfaceContainerHigh,
                      foreground: isOpen
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isOpen
                                      ? scheme.primary
                                      : scheme.outline,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOpen ? l10n.openToday : l10n.closedNow,
                                style: theme.textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOpen ? l10n.hoursToday : l10n.nextOpening(now),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(CoolIcons.caretRight, color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.sectionGap),
              SectionHeader(
                title: l10n.saturdaySpecialistsTitle,
                actionLabel: l10n.viewSaturdaySchedule,
                onAction: () => _openSaturdaySchedule(context),
              ),
              const SizedBox(height: 10),
              _SaturdaySpotlightCard(
                date: nextSaturday,
                group: nextSaturdayGroup,
                doctors: nextSaturdayDoctors,
                onTap: () => _openSaturdaySchedule(context),
              ),
              const SizedBox(height: AppTokens.sectionGap),
              SectionHeader(
                title: l10n.departmentsServices,
                actionLabel: l10n.viewAll,
                onAction: () => _openServices(context, departments: true),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 12.0;
                  final width = (constraints.maxWidth - spacing) / 2;
                  if (width <= 0) return const SizedBox.shrink();
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final department in featuredDepartments)
                        SizedBox(
                          width: width,
                          height: AppTokens.scaled(context, 145),
                          child: _DepartmentCard(department: department),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppTokens.sectionGap),
              SectionHeader(
                title: l10n.ourDoctors,
                actionLabel: l10n.viewAll,
                onAction: () => _openServices(context),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: AppTokens.scaled(context, 258),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: featuredDoctors.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 268,
                      child: _DoctorCard(doctor: featuredDoctors[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTokens.sectionGap),
              SectionHeader(title: l10n.contactLocation),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(14),
                onTap: () => _openContact(context),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => callClinic(context),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, AppTokens.minTap),
                        ),
                        icon: const Icon(CoolIcons.phoneCall, size: 18),
                        label: Text(l10n.callClinic),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => openClinicMap(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, AppTokens.minTap),
                        ),
                        icon: const Icon(CoolIcons.navigationArrow, size: 18),
                        label: Text(l10n.directions),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startBooking(BuildContext context) async {
    final created = await startBooking(context);
    if (created == true && context.mounted) {
      onOpenTab(1);
    }
  }

  void _openSaturdaySchedule(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SaturdayScheduleScreen()),
    );
  }

  void _openServices(BuildContext context, {bool departments = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServicesScreen(showDepartmentsInitially: departments),
      ),
    );
  }

  void _openContact(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ContactScreen()));
  }
}

class _SaturdaySpotlightCard extends StatelessWidget {
  const _SaturdaySpotlightCard({
    required this.date,
    required this.group,
    required this.doctors,
    required this.onTap,
  });

  final DateTime date;
  final SaturdayGroup? group;
  final List<Doctor> doctors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final datePrimary = context.watch<AppState>().datePrimary;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      color: scheme.surfaceContainerHigh,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 60,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.primaryDayShort(date, datePrimary),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimary,
                        fontSize: 21,
                      ),
                    ),
                    Text(
                      l10n.primaryWeekdayShort(date, datePrimary),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.thisSaturday,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.primaryDateText(date, datePrimary),
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      l10n.secondaryDateText(date, datePrimary),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (group != null) ...[
                const SizedBox(width: 8),
                StatusPill(
                  label: l10n.saturdayGroupShort(group!),
                  background: scheme.primaryContainer,
                  foreground: scheme.onPrimaryContainer,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (doctors.isEmpty)
            Text(
              l10n.noSpecialistThisSaturday,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            for (final doctor in doctors) ...[
              Row(
                children: [
                  DoctorAvatar(doctor: doctor, size: 34),
                  const SizedBox(width: 10),
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
                        Text(
                          doctor.displaySpecialty,
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
                    size: 17,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (doctor != doctors.last) const SizedBox(height: 10),
            ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(CoolIcons.calendarDots, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                l10n.viewSaturdaySchedule,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.comingSoon = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (comingSoon) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.comingSoonLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({required this.department});

  final Department department;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DepartmentDetailScreen(department: department),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TonalIcon(icon: department.icon, size: 38, iconSize: 19),
          const Spacer(),
          Text(
            department.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: 2),
          Text(
            department.doctorIds.isEmpty
                ? l10n.serviceAvailable
                : l10n.doctorCount(department.doctorIds.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor});

  final Doctor doctor;

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
            children: [
              DoctorAvatar(doctor: doctor),
              const Spacer(),
              if (doctor.visiting)
                StatusPill(
                  label: l10n.visiting,
                  background: scheme.secondaryContainer,
                  foreground: scheme.onSecondaryContainer,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            doctor.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(fontSize: 14.5),
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
          const Spacer(),
          Row(
            children: [
              Icon(CoolIcons.clock, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  doctor.availability(language),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => startBooking(
                context,
                departmentId: doctor.departmentId,
                doctorId: doctor.id,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppTokens.minTap),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: Text(l10n.bookShort),
            ),
          ),
        ],
      ),
    );
  }
}
