import 'package:flutter/material.dart';

import '../core/icons.dart';

import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final language = l10n.language;
    final notifications = [...state.notifications]
      ..sort((a, b) => b.time.compareTo(a.time));

    final groups = <String, List<AppNotification>>{};
    for (final notification in notifications) {
      final label = _groupLabel(l10n, notification.time);
      groups.putIfAbsent(label, () => []).add(notification);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: state.markAllNotificationsRead,
              child: Text(l10n.markAllRead),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? AppRefreshEmpty(
              onRefresh: demoRefresh,
              child: EmptyState(
                icon: PhosphorIconsRegular.bellSimple,
                title: l10n.noNotificationsTitle,
                message: l10n.noNotificationsMessage,
              ),
            )
          : AppRefreshView(
              onRefresh: demoRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
                children: [
                  for (final entry in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        entry.key,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (final notification in entry.value) ...[
                      _NotificationCard(
                        notification: notification,
                        language: language,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  String _groupLabel(L10n l10n, DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    final diff = today.difference(date).inDays;
    if (diff <= 0) return l10n.groupToday;
    if (diff == 1) return l10n.groupYesterday;
    return l10n.groupEarlier;
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.language});

  final AppNotification notification;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final unread = !notification.read;

    return AppCard(
      padding: const EdgeInsets.all(16),
      color: unread ? scheme.surfaceContainerHigh : null,
      onTap: () =>
          context.read<AppState>().markNotificationRead(notification.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TonalIcon(
            icon: _iconFor(notification.kind),
            size: 42,
            iconSize: 20,
            background: unread
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            foreground: unread
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (unread) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        notification.displayTitle(language),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.notificationStamp(notification.time),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.displayBody(language),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String kind) {
    return switch (kind) {
      'appointment' => PhosphorIconsRegular.calendarCheck,
      'record' => PhosphorIconsRegular.testTube,
      _ => PhosphorIconsRegular.megaphone,
    };
  }
}
