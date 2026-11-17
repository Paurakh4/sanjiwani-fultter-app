import 'dart:async';

import 'package:flutter/material.dart';

import '../core/icons.dart';

import '../core/l10n.dart';
import '../core/launcher.dart';
import '../core/tokens.dart';
import '../data/demo_data.dart';
import '../models.dart';
import '../screens/booking_screen.dart';

class NoticeCarousel extends StatefulWidget {
  const NoticeCarousel({
    super.key,
    required this.notices,
    this.active = true,
    this.onNoticeTap,
  });

  final List<Notice> notices;
  final bool active;
  final ValueChanged<Notice>? onNoticeTap;

  @override
  State<NoticeCarousel> createState() => _NoticeCarouselState();
}

class _NoticeCarouselState extends State<NoticeCarousel> {
  late final PageController _controller;
  Timer? _timer;
  Timer? _resumeTimer;
  int _index = 0;
  bool _paused = false;
  bool _interacting = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.93);
    _scheduleAutoplay();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      _scheduleAutoplay();
    }
  }

  @override
  void didUpdateWidget(covariant NoticeCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _scheduleAutoplay();
      } else {
        _timer?.cancel();
        _resumeTimer?.cancel();
      }
    }
  }

  bool get _canAutoplay =>
      widget.active && !_paused && !_reduceMotion && widget.notices.length >= 2;

  void _scheduleAutoplay() {
    _timer?.cancel();
    _resumeTimer?.cancel();
    if (!mounted || !_canAutoplay) return;
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

  void _onPointerDown(PointerDownEvent _) {
    _interacting = true;
    _timer?.cancel();
    _resumeTimer?.cancel();
  }

  void _onPointerUp(PointerUpEvent _) => _resumeAfterIdle();
  void _onPointerCancel(PointerCancelEvent _) => _resumeAfterIdle();

  void _resumeAfterIdle() {
    _interacting = false;
    _resumeTimer?.cancel();
    if (!mounted || !_canAutoplay) return;
    _resumeTimer = Timer(const Duration(seconds: 8), _scheduleAutoplay);
  }

  void _togglePaused() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _timer?.cancel();
      _resumeTimer?.cancel();
    } else {
      _scheduleAutoplay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resumeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final total = widget.notices.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: AppTokens.scaled(context, 252),
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: PageView.builder(
              controller: _controller,
              padEnds: false,
              itemCount: total,
              onPageChanged: (index) {
                setState(() => _index = index);
                if (!_interacting) _scheduleAutoplay();
              },
              itemBuilder: (context, index) {
                final notice = widget.notices[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _NoticeCard(
                    notice: notice,
                    highlighted: index == 0,
                    onTap: () {
                      final handler = widget.onNoticeTap;
                      if (handler != null) {
                        handler(notice);
                      } else {
                        openNotice(context, notice);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              Semantics(
                label: l10n.noticePageOf(i + 1, total),
                child: AnimatedContainer(
                  duration: AppTokens.motionFast,
                  curve: AppTokens.ease,
                  width: i == _index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                ),
              ),
              if (i != total - 1) const SizedBox(width: 5),
            ],
            const Spacer(),
            if (total >= 2)
              IconButton(
                tooltip: _paused ? l10n.playNotices : l10n.pauseNotices,
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: EdgeInsets.zero,
                onPressed: _togglePaused,
                icon: Icon(_paused ? CoolIcons.playFill : CoolIcons.pauseFill),
              ),
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
                  Icon(CoolIcons.arrowRight, size: 18, color: muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Specialist announcements go straight to a booking pre-filled for the
/// announced doctor and their next scheduled Saturday; other notices open the
/// full notice sheet.
void openNotice(BuildContext context, Notice notice) {
  final doctor = doctorById(notice.doctorId);
  if (doctor == null) {
    showNoticeSheet(context, notice);
    return;
  }
  startBooking(context, departmentId: doctor.departmentId, doctorId: doctor.id);
}

void showNoticeSheet(BuildContext context, Notice notice) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final scheme = theme.colorScheme;
      final l10n = L10n.of(sheetContext);
      final doctor = doctorById(notice.doctorId);
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
              if (doctor != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      startBooking(
                        context,
                        departmentId: doctor.departmentId,
                        doctorId: doctor.id,
                      );
                    },
                    icon: const Icon(CoolIcons.calendarPlus, size: 18),
                    label: Text(l10n.bookAppointment),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => callClinic(sheetContext),
                    icon: const Icon(CoolIcons.phoneCall, size: 18),
                    label: Text(l10n.noticeRegisterCall),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => callClinic(sheetContext),
                    icon: const Icon(CoolIcons.phoneCall, size: 18),
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
