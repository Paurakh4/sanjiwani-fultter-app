import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_logo.dart';

class AppLogoLoader extends StatelessWidget {
  const AppLogoLoader({
    super.key,
    this.width = 250,
    this.duration = const Duration(milliseconds: 1500),
    this.showProgress = true,
    this.pulse = true,
  });

  final double width;
  final Duration duration;
  final bool showProgress;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(width: width, duration: duration, pulse: pulse),
        if (showProgress) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.3,
              color: scheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}

Future<T> runWithLogoLoading<T>(
  BuildContext context,
  Future<T> Function() task, {
  Duration minimum = const Duration(milliseconds: 1900),
}) async {
  final stopwatch = Stopwatch()..start();
  BuildContext? overlayContext;

  final overlay = showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Loading',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, _, _) {
      overlayContext = dialogContext;
      final width = math.min(
        MediaQuery.sizeOf(dialogContext).width * 0.66,
        320.0,
      );
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Theme.of(dialogContext).colorScheme.surface,
          body: SafeArea(
            child: Center(
              child: AppLogoLoader(
                width: width,
                duration: const Duration(milliseconds: 1500),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );

  try {
    final result = await task();
    final remaining = minimum - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    return result;
  } finally {
    if (overlayContext == null) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
    final dialogContext = overlayContext;
    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    await overlay;
  }
}
