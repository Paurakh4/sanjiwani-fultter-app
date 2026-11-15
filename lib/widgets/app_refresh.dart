import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_loading.dart';

Future<void> demoRefresh() {
  return Future<void>.delayed(const Duration(milliseconds: 1400));
}

class AppRefreshView extends StatefulWidget {
  const AppRefreshView({super.key, required this.child, this.onRefresh});

  final Widget child;
  final Future<void> Function()? onRefresh;

  @override
  State<AppRefreshView> createState() => _AppRefreshViewState();
}

class _AppRefreshViewState extends State<AppRefreshView> {
  bool _visible = false;
  bool _refreshing = false;
  Key _logoKey = UniqueKey();

  void _onStatus(RefreshIndicatorStatus? status) {
    if (status == RefreshIndicatorStatus.armed) {
      HapticFeedback.selectionClick();
    }
    final show =
        status == RefreshIndicatorStatus.armed ||
        status == RefreshIndicatorStatus.snap ||
        status == RefreshIndicatorStatus.refresh;
    final refreshing =
        status == RefreshIndicatorStatus.snap ||
        status == RefreshIndicatorStatus.refresh;

    if (show != _visible || refreshing != _refreshing) {
      setState(() {
        if (show && !_visible) _logoKey = UniqueKey();
        _visible = show;
        _refreshing = refreshing;
      });
    }
    if (status == RefreshIndicatorStatus.canceled ||
        status == RefreshIndicatorStatus.done) {
      if (_visible || _refreshing) {
        setState(() {
          _visible = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        if (!_visible) _logoKey = UniqueKey();
        _visible = true;
        _refreshing = true;
      });
    }
    try {
      await (widget.onRefresh ?? demoRefresh)();
    } finally {
      if (mounted) {
        setState(() {
          _visible = false;
          _refreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = math.min(MediaQuery.sizeOf(context).width * 0.6, 280.0);

    return Stack(
      children: [
        RefreshIndicator.noSpinner(
          onRefresh: _refresh,
          onStatusChange: _onStatus,
          child: widget.child,
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_refreshing,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: _visible
                  ? AbsorbPointer(
                      absorbing: _refreshing,
                      child: ColoredBox(
                        color: scheme.surface.withValues(alpha: 0.88),
                        child: Center(
                          child: AppLogoLoader(
                            key: _logoKey,
                            width: width,
                            duration: const Duration(milliseconds: 1300),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
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
