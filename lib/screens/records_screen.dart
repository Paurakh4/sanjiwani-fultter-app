import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';

import '../core/l10n.dart';
import '../core/tokens.dart';
import '../data/demo_data.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/app_refresh.dart';
import '../widgets/app_search_field.dart';
import '../widgets/common.dart';
import 'visit_detail_screen.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  RecordKind? _filter;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(VisitRecord record, String query) {
    return record.title.toLowerCase().contains(query) ||
        record.department.toLowerCase().contains(query) ||
        record.doctor.toLowerCase().contains(query) ||
        record.summary.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final records = [...demoRecords(l10n.language)]
      ..sort((a, b) => b.date.compareTo(a.date));
    final query = _query.trim().toLowerCase();
    final filtered = records.where((record) {
      if (_filter != null && record.kind != _filter) return false;
      if (query.isNotEmpty && !_matches(record, query)) return false;
      return true;
    }).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabPageHeader(
            title: l10n.recordsTitle,
            subtitle: l10n.recordsSubtitle,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.gutter,
              0,
              AppTokens.gutter,
              10,
            ),
            child: AppSearchField(
              controller: _searchController,
              hint: l10n.searchRecordsHint,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.gutter),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoicePill(
                  label: l10n.all,
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                ChoicePill(
                  label: l10n.filterVisits,
                  selected: _filter == RecordKind.visit,
                  onTap: () => setState(() => _filter = RecordKind.visit),
                ),
                ChoicePill(
                  label: l10n.filterLabs,
                  selected: _filter == RecordKind.lab,
                  onTap: () => setState(() => _filter = RecordKind.lab),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? AppRefreshEmpty(
                    onRefresh: demoRefresh,
                    child: EmptyState(
                      icon: CoolIcons.fileText,
                      title: query.isNotEmpty
                          ? l10n.noResultsTitle
                          : l10n.noRecordsTitle,
                      message: query.isNotEmpty
                          ? l10n.noResultsMessage
                          : l10n.noRecordsMessage,
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
                        24,
                      ),
                      itemCount: filtered.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == filtered.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              l10n.recordsDemoNote,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return _RecordCard(record: filtered[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final VisitRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final datePrimary = context.watch<AppState>().datePrimary;
    final isLab = record.kind == RecordKind.lab;
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VisitDetailScreen(record: record),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TonalIcon(
            icon: isLab ? CoolIcons.testTube : CoolIcons.stethoscope,
            background: scheme.surfaceContainerHigh,
            foreground: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        record.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.primaryDateMedium(record.date, datePrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  record.department == record.doctor
                      ? record.department
                      : '${record.department} · ${record.doctor}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  record.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Icon(CoolIcons.caretRight, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
