import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/icons.dart';

import '../core/l10n.dart';
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

  void _openTab(int index) {
    if (index == _index) return;
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
            HomeScreen(onOpenTab: _openTab, isActive: _index == 0),
            const AppointmentsScreen(),
            const RecordsScreen(),
            ProfileScreen(onOpenTab: _openTab),
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
                icon: const Icon(PhosphorIconsRegular.house),
                selectedIcon: const Icon(PhosphorIconsFill.house),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(PhosphorIconsRegular.calendarDots),
                selectedIcon: const Icon(PhosphorIconsFill.calendarDots),
                label: l10n.navAppointments,
              ),
              NavigationDestination(
                icon: const Icon(PhosphorIconsRegular.folderOpen),
                selectedIcon: const Icon(PhosphorIconsFill.folderOpen),
                label: l10n.navRecords,
              ),
              NavigationDestination(
                icon: const Icon(PhosphorIconsRegular.userCircle),
                selectedIcon: const Icon(PhosphorIconsFill.userCircle),
                label: l10n.navProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
