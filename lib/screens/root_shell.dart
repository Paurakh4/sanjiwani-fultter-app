import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';

import '../core/l10n.dart';
import '../core/tokens.dart';
import '../state/app_state.dart';
import 'appointments_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'records_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  final _controllers = List.generate(4, (_) => ScrollController());
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Minute tick: refresh open/closed + today's date, and persist any
    // appointment whose slot end has passed as completed.
    _ticker = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      context.read<AppState>().normalizeCompleted();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _openTab(int index) {
    if (index == _index) {
      final controller = _controllers[index];
      if (controller.hasClients) {
        controller.animateTo(
          0,
          duration: AppTokens.motionMedium,
          curve: AppTokens.ease,
        );
      }
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = L10n.of(context);

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
        body: IndexedStack(
          index: _index,
          children: [
            HomeScreen(
              onOpenTab: _openTab,
              isActive: _index == 0,
              scrollController: _controllers[0],
            ),
            AppointmentsScreen(scrollController: _controllers[1]),
            RecordsScreen(scrollController: _controllers[2]),
            ProfileScreen(
              onOpenTab: _openTab,
              scrollController: _controllers[3],
            ),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              top: BorderSide(color: scheme.outlineVariant, width: 0.7),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _openTab,
            destinations: [
              NavigationDestination(
                icon: const Icon(CoolIcons.house),
                selectedIcon: const Icon(CoolIcons.houseFill),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(CoolIcons.calendarDots),
                selectedIcon: const Icon(CoolIcons.calendarDotsFill),
                label: l10n.navAppointments,
              ),
              NavigationDestination(
                icon: const Icon(CoolIcons.folderOpen),
                selectedIcon: const Icon(CoolIcons.folderOpenFill),
                label: l10n.navRecords,
              ),
              NavigationDestination(
                icon: const Icon(CoolIcons.userCircle),
                selectedIcon: const Icon(CoolIcons.userCircleFill),
                label: l10n.navProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
