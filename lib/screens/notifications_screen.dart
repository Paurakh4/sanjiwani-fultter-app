import 'package:flutter/material.dart';

import '../core/icons.dart';

import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/tokens.dart';
import '../data/catalog.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';
import '../widgets/notice_carousel.dart';
import 'contact_screen.dart';
import 'appointment_detail_screen.dart';
import 'appointments_screen.dart';

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
        leading: const AppBackButton(),
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
              child: EmptyState(
                icon: CoolIcons.bellSimple,
                title: l10n.noNotificationsTitle,
                message: l10n.noNotificationsMessage,
              ),
            )
          : AppRefreshView(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.gutter,
                  4,
                  AppTokens.gutter,
                  32,
                ),
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
                        onOpen: () => _open(context, notification),
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

  void _open(BuildContext context, AppNotification notification) {
    final state = context.read<AppState>();
    state.markNotificationRead(notification.id);
    final l10n = L10n.of(context);
    final refId = notification.refId;

    switch (notification.kind) {
      case 'appointment':
        final exists =
            refId != null && state.appointments.any((a) => a.id == refId);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => exists
                ? AppointmentDetailScreen(appointmentId: refId)
                : const AppointmentsScreen(),
          ),
        );
      case 'record':
        // No in-app report viewer yet, so point at the clinic/lab instead of
        // opening the sample record.
        showAppSnack(
          context,
          l10n.reportsComingSnack,
          actionLabel: l10n.callClinic,
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ContactScreen()),
          ),
        );
      default:
        // Open exactly the notice this notification points at. Falling back to
        // an unrelated one is misleading, and would throw when the list is
        // empty.
        if (refId != null) {
          for (final notice in notices) {
            if (notice.id == refId) {
              openNotice(context, notice);
              return;
            }
          }
        }
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.language,
    required this.onOpen,
  });

  final AppNotification notification;
  final AppLanguage language;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final unread = !notification.read;

    return AppCard(
      padding: const EdgeInsets.all(16),
      color: unread ? scheme.surfaceContainerHigh : null,
      onTap: onOpen,
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
                        child: Semantics(
                          label: l10n.unread,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        notification.displayTitle(language),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
      'appointment' => CoolIcons.calendarCheck,
      'record' => CoolIcons.testTube,
      _ => CoolIcons.megaphone,
    };
  }
}
