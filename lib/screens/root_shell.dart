import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';

import '../core/l10n.dart';
import '../core/tokens.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'appointments_screen.dart';
import 'doctor_calendar_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'records_screen.dart';

/// Tab ids: 0 home, 1 appointments, 2 records, 3 profile, 4 calendar.
/// Display order comes from AppState.tabOrder; screen widgets are listed by id.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _selectedId = 0;
  final _controllers = List.generate(5, (_) => ScrollController());
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

  /// Opens a tab by id regardless of its display position.
  void _openTab(int id) {
    if (id == _selectedId) {
      final controller = _controllers[id];
      if (controller.hasClients) {
        controller.animateTo(
          0,
          duration: AppTokens.motionMedium,
          curve: AppTokens.ease,
        );
      }
      return;
    }
    setState(() => _selectedId = id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = L10n.of(context);
    final order = context.watch<AppState>().tabOrder;

    final screens = <int, Widget>{
      0: HomeScreen(
        onOpenTab: _openTab,
        isActive: _selectedId == 0,
        scrollController: _controllers[0],
      ),
      1: AppointmentsScreen(scrollController: _controllers[1]),
      2: RecordsScreen(scrollController: _controllers[2]),
      3: ProfileScreen(
        onOpenTab: _openTab,
        scrollController: _controllers[3],
      ),
      4: DoctorCalendarScreen(
        embedded: true,
        scrollController: _controllers[4],
      ),
    };

    final destinations = <int, NavigationDestination>{
      0: NavigationDestination(
        icon: const Icon(CoolIcons.house),
        selectedIcon: const Icon(CoolIcons.houseFill),
        label: l10n.navHome,
      ),
      1: NavigationDestination(
        // A clipboard list, not a second calendar: the calendar tab sits right
        // beside it and two calendar glyphs read as the same destination.
        icon: CoolSvgIcon(
          'clipboard-list-round',
          color: scheme.onSurfaceVariant,
        ),
        selectedIcon: CoolSvgIcon(
          'clipboard-list-fill-round',
          color: context.brand.onStrong,
        ),
        label: l10n.navAppointments,
      ),
      2: NavigationDestination(
        icon: const Icon(CoolIcons.folderOpen),
        selectedIcon: const Icon(CoolIcons.folderOpenFill),
        label: l10n.navRecords,
      ),
      3: NavigationDestination(
        icon: const Icon(CoolIcons.userCircle),
        selectedIcon: const Icon(CoolIcons.userCircleFill),
        label: l10n.navProfile,
      ),
      4: NavigationDestination(
        icon: CoolSvgIcon(
          'calendar-round',
          color: scheme.onSurfaceVariant,
        ),
        selectedIcon: CoolSvgIcon(
          'calendar-fill-round',
          color: context.brand.onStrong,
        ),
        label: l10n.navCalendar,
      ),
    };

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
          index: order.indexOf(_selectedId),
          children: [for (final id in order) screens[id]!],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              top: BorderSide(color: scheme.outlineVariant, width: 0.7),
            ),
          ),
          child: NavigationBar(
            selectedIndex: order.indexOf(_selectedId),
            onDestinationSelected: (position) => _openTab(order[position]),
            destinations: [for (final id in order) destinations[id]!],
          ),
        ),
      ),
    );
  }
}
