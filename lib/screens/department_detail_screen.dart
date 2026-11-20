import 'package:flutter/material.dart';

import '../core/icons.dart';

import '../core/clinic.dart';
import '../core/l10n.dart';
import '../core/tokens.dart';
import '../data/catalog.dart';
import '../models.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';
import 'booking_screen.dart';
import 'doctor_detail_screen.dart';

class DepartmentDetailScreen extends StatelessWidget {
  const DepartmentDetailScreen({super.key, required this.department});

  final Department department;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final language = l10n.language;
    final departmentDoctors = doctorsForDepartment(department.id);
    final hasSpecialist = departmentDoctors.any(
      (doctor) => doctor.isSpecialist,
    );

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(department.displayName),
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
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TonalIcon(icon: department.icon, size: 52, iconSize: 25),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      department.description(language),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
            if (departmentDoctors.isNotEmpty) ...[
              const SizedBox(height: 28),
              SectionHeader(title: l10n.departmentDoctors),
              const SizedBox(height: 12),
              for (final doctor in departmentDoctors) ...[
                AppCard(
                  padding: const EdgeInsets.all(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DoctorDetailScreen(doctor: doctor),
                    ),
                  ),
                  child: Row(
                    children: [
                      DoctorAvatar(doctor: doctor, size: 50),
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
                              doctor.availability(language),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CoolIcons.caretRight,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ] else ...[
              const SizedBox(height: 20),
              AppCard(
                color: scheme.surfaceContainer,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CoolIcons.info,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.technicalServiceNote,
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
            if (departmentDoctors.isNotEmpty && !hasSpecialist) ...[
              const SizedBox(height: 16),
              AppCard(
                color: scheme.surfaceContainer,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CoolIcons.info,
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
            const SizedBox(height: 28),
            if (hasSpecialist)
              FilledButton.icon(
                onPressed: () =>
                    startBooking(context, departmentId: department.id),
                icon: const Icon(CoolIcons.calendarPlus, size: 18),
                label: Text(l10n.bookTime),
              ),
            const SizedBox(height: 12),
            Text(
              l10n.departmentPhoneNote(l10n.digits(Clinic.phonePrimaryDisplay)),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
