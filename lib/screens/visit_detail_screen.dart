import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';

import '../core/l10n.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';

class VisitDetailScreen extends StatelessWidget {
  const VisitDetailScreen({super.key, required this.record});

  final VisitRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final isLab = record.kind == RecordKind.lab;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.reportDetails),
      ),
      body: AppRefreshView(
        onRefresh: demoRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 40),
          children: [
            Row(
              children: [
                TonalIcon(
                  icon: isLab ? CoolIcons.testTube : CoolIcons.stethoscope,
                  size: 56,
                  iconSize: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${l10n.primaryDateText(record.date, context.watch<AppState>().datePrimary)}'
                        ' · ${record.doctor}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              record.summary,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            if (record.vitals.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(l10n.sectionResults, style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  children: [
                    for (final entry in record.vitals.entries) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            entry.value,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (entry.key != record.vitals.keys.last)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
            if (record.labs.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(l10n.sectionLabResults, style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  children: [
                    for (var i = 0; i < record.labs.length; i++) ...[
                      _LabRow(lab: record.labs[i]),
                      if (i != record.labs.length - 1)
                        const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ],
            if (record.medicines.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(l10n.sectionMedicines, style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  children: [
                    for (var i = 0; i < record.medicines.length; i++) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TonalIcon(
                            icon: CoolIcons.pill,
                            size: 38,
                            iconSize: 19,
                            background: scheme.surfaceContainerHigh,
                            foreground: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.medicines[i].name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    record.medicines[i].dose,
                                    if (record.medicines[i].duration.isNotEmpty)
                                      record.medicines[i].duration,
                                  ].join(' · '),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (i != record.medicines.length - 1)
                        const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ],
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(l10n.sectionNotes, style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              for (final note in record.notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          note,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 28),
            Text(
              l10n.recordDisclaimer,
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

class _LabRow extends StatelessWidget {
  const _LabRow({required this.lab});

  final LabResult lab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lab.name, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                l10n.referenceLabel('${lab.reference} ${lab.unit}'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${lab.value} ${lab.unit}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
