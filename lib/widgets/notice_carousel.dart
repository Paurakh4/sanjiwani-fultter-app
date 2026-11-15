import 'dart:async';

import 'package:flutter/material.dart';

import '../core/icons.dart';

import '../core/l10n.dart';
import '../core/launcher.dart';
import '../models.dart';

class NoticeCarousel extends StatefulWidget {
  const NoticeCarousel({super.key, required this.notices, this.active = true});

  final List<Notice> notices;
  final bool active;

  @override
  State<NoticeCarousel> createState() => _NoticeCarouselState();
}

class _NoticeCarouselState extends State<NoticeCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.93);
    _scheduleAutoplay();
  }

  @override
  void didUpdateWidget(covariant NoticeCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _scheduleAutoplay();
      } else {
        _timer?.cancel();
      }
    }
  }

  void _scheduleAutoplay() {
    _timer?.cancel();
    if (!widget.active || widget.notices.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.notices.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 252,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: widget.notices.length,
            onPageChanged: (index) {
              setState(() => _index = index);
              _scheduleAutoplay();
            },
            itemBuilder: (context, index) {
              final notice = widget.notices[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _NoticeCard(
                  notice: notice,
                  highlighted: index == 0,
                  onTap: () => _showNoticeDetail(context, notice),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < widget.notices.length; i++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: i == _index ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index ? scheme.primary : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              if (i != widget.notices.length - 1) const SizedBox(width: 5),
            ],
            const Spacer(),
            Text(
              l10n.swipeHint,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.notice,
    required this.highlighted,
    required this.onTap,
  });

  final Notice notice;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final background = highlighted
        ? scheme.primary
        : scheme.surfaceContainerHigh;
    final foreground = highlighted ? scheme.onPrimary : scheme.onSurface;
    final tagBackground = highlighted
        ? Colors.white
        : scheme.surfaceContainerLowest;
    final tagForeground = highlighted ? scheme.primary : scheme.onSurface;
    final muted = highlighted
        ? scheme.onPrimary.withValues(alpha: 0.85)
        : scheme.onSurfaceVariant;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tagBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      notice.tag,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: tagForeground,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      notice.dateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                notice.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  notice.body,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                    color: foreground,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.noticeTapHint,
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    ),
                  ),
                  Icon(PhosphorIconsRegular.arrowRight, size: 18, color: muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showNoticeDetail(BuildContext context, Notice notice) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final scheme = theme.colorScheme;
      final l10n = L10n.of(sheetContext);
      return Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewPaddingOf(sheetContext).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      notice.tag,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    notice.dateLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(notice.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                notice.body,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.65),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => callClinic(sheetContext),
                  icon: const Icon(PhosphorIconsRegular.phoneCall, size: 18),
                  label: Text(l10n.noticeRegisterCall),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(l10n.okay),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
