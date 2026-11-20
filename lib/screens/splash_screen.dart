import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/app_logo.dart';
import 'auth/login_screen.dart';
import 'onboarding_screen.dart';
import 'root_shell.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  static const _hold = Duration(milliseconds: 2600);

  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_hold, () {
      if (mounted) setState(() => _finished = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 340),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _finished
          ? (state.onboarded
                ? (state.signedIn
                      ? const RootShell(key: ValueKey('root'))
                      : const LoginScreen(key: ValueKey('login')))
                : const OnboardingScreen(key: ValueKey('onboarding')))
          : const _LogoIntroSplash(key: ValueKey('splash')),
    );
  }
}

class _LogoIntroSplash extends StatelessWidget {
  const _LogoIntroSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final logoWidth = math.min(MediaQuery.sizeOf(context).width * 0.82, 360.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: scheme.surface,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: Center(
          child: AppLogo(
            width: logoWidth,
            duration: const Duration(milliseconds: 2100),
          ),
        ),
      ),
    );
  }
}
