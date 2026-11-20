import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/tokens.dart';
import '../state/app_state.dart';

/// Pull-to-refresh that reveals an indicator from behind the top of the page.
///
/// The page itself slides down with the drag; the indicator sits in the gap
/// that opens above it, so nothing covers the screen while refreshing.
class AppRefreshView extends StatefulWidget {
  const AppRefreshView({super.key, required this.child, this.onRefresh});

  final Widget child;
  final Future<void> Function()? onRefresh;

  @override
  State<AppRefreshView> createState() => _AppRefreshViewState();
}

class _AppRefreshViewState extends State<AppRefreshView>
    with SingleTickerProviderStateMixin {
  static const double _trigger = 72;
  static const double _maxPull = 132;
  static const double _settle = 62;
  static const double _indicatorSize = 34;

  /// Current revealed gap above the page, in logical pixels.
  late final AnimationController _offset;
  bool _dragging = false;
  bool _armed = false;
  bool _refreshing = false;
  double _bounce = 0;

  double get _pull => _offset.value;

  @override
  void initState() {
    super.initState();
    _offset = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (!mounted) return;
        setState(() {});
      });
  }

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  void _addPull(double delta) {
    if (_refreshing || delta <= 0) return;
    _offset.stop();
    final resistance = (1 - _pull / _maxPull * 0.85).clamp(0.15, 1.0);
    final next = (_pull + delta * resistance).clamp(0.0, _maxPull);
    final armed = next >= _trigger;
    if (armed && !_armed) HapticFeedback.selectionClick();
    _offset.value = next;
    if (armed != _armed) setState(() => _armed = armed);
  }

  bool _onNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) {
        _offset.stop();
        _bounce = 0;
        _dragging = !_refreshing;
      }
    } else if (notification is OverscrollNotification) {
      // Android clamping physics reports the unconsumed drag here.
      if (notification.overscroll < 0) {
        _dragging = true;
        _addPull(-notification.overscroll);
      }
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      // iOS bouncing physics moves the scroll offset itself.
      final metrics = notification.metrics;
      final bounce = metrics.minScrollExtent - metrics.pixels;
      if (bounce > 0) {
        final delta = bounce - _bounce;
        _bounce = bounce;
        if (delta > 0) {
          _dragging = true;
          _addPull(delta);
        }
      } else {
        _bounce = 0;
      }
    } else if (notification is ScrollEndNotification) {
      if (_dragging) {
        _dragging = false;
        _release();
      }
    }
    return false;
  }

  void _release() {
    if (_refreshing) return;
    if (_armed) {
      _startRefresh();
    } else {
      _offset.animateTo(
        0,
        duration: AppTokens.motionMedium,
        curve: AppTokens.ease,
      );
    }
    if (_armed) setState(() => _armed = false);
  }

  Future<void> _startRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _refreshing = true);
    _offset.animateTo(
      _settle,
      duration: const Duration(milliseconds: 180),
      curve: AppTokens.ease,
    );
    try {
      // A page that does not name a refresh action still means "show me what
      // the clinic has now", which is the one thing every screen can ask for.
      await (widget.onRefresh ?? () => context.read<AppState>().refresh())();
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
        _offset.animateTo(
          0,
          duration: AppTokens.motionMedium,
          curve: AppTokens.ease,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pull = _pull;
    final progress = (pull / _trigger).clamp(0.0, 1.0);
    final reveal = (pull / (_indicatorSize + 12)).clamp(0.0, 1.0);

    final label = _refreshing
        ? l10n.loading
        : _armed
        ? l10n.releaseToRefresh
        : l10n.pullToRefresh;

    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, pull),
                child: widget.child,
              ),
            ),
            // Sits above the page in paint order only while the gap is open;
            // clipped so it slides out from under the top edge.
            if (pull > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: pull,
                child: IgnorePointer(
                  child: ClipRect(
                    child: Semantics(
                      liveRegion: _refreshing,
                      label: label,
                      child: ExcludeSemantics(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Opacity(
                              opacity: reveal,
                              child: Transform.scale(
                                scale: 0.75 + 0.25 * reveal,
                                child: _Indicator(
                                  armed: _armed || _refreshing,
                                  refreshing: _refreshing,
                                  progress: progress,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.armed,
    required this.refreshing,
    required this.progress,
  });

  final bool armed;
  final bool refreshing;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disc = armed ? scheme.primary : scheme.primaryContainer;
    final ink = armed ? scheme.onPrimary : scheme.onPrimaryContainer;

    return AnimatedContainer(
      duration: AppTokens.motionFast,
      curve: AppTokens.ease,
      width: _AppRefreshViewState._indicatorSize,
      height: _AppRefreshViewState._indicatorSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: disc, shape: BoxShape.circle),
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          value: refreshing ? null : progress,
          strokeWidth: 2.2,
          color: ink,
          backgroundColor: ink.withValues(alpha: 0.18),
          strokeCap: StrokeCap.round,
        ),
      ),
    );
  }
}

class AppRefreshEmpty extends StatelessWidget {
  const AppRefreshEmpty({super.key, required this.child, this.onRefresh});

  final Widget child;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppRefreshView(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
      ),
    );
  }
}
