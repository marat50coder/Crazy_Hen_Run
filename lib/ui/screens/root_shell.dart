import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/hen_state.dart';
import '../widgets/hen_nav_bar.dart';
import 'coop/coop_screen.dart';
import 'home/today_screen.dart';
import 'profile/profile_screen.dart';
import 'run/run_hub_screen.dart';
import 'stats/stats_screen.dart';
import 'shared/celebration.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _RootShellState();
}

class _RootShellState extends State<AppShell> {
  static const List<HenNavItem> _items = <HenNavItem>[
    HenNavItem(
      icon: Icons.directions_run_outlined,
      activeIcon: Icons.directions_run_rounded,
      label: 'Run',
    ),
    HenNavItem(
      icon: Icons.bolt_outlined,
      activeIcon: Icons.bolt_rounded,
      label: 'Today',
    ),
    HenNavItem(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      label: 'Stats',
    ),
    HenNavItem(
      icon: Icons.egg_outlined,
      activeIcon: Icons.egg_rounded,
      label: 'Coop',
    ),
    HenNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'You',
    ),
  ];

  int _index = 0;
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HenState>().promptChimesOnFirstLaunch();
      _drainCelebrations();
    });
  }

  void _drainCelebrations() {
    if (!mounted) return;
    final app = context.read<HenState>();
    if (app.pendingCelebrations.isEmpty) return;
    final unlocked = app.pendingCelebrations.first;
    app.consumeCelebrations();
    if (!app.celebrate) return;
    showAchievementCelebration(context, unlocked);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<HenState>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _drainCelebrations());

    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.015),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey<int>(_index),
            child: _page(_index),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: HenNavBar(
          items: _items,
          index: _index,
          onSelected: (i) => setState(() => _index = i),
        ),
      ),
    );
  }

  Widget _page(int index) {
    switch (index) {
      case 0:
        return const RunHubScreen();
      case 1:
        return const TodayScreen();
      case 2:
        return const StatsScreen();
      case 3:
        return const CoopScreen();
      default:
        return const ProfileScreen();
    }
  }
}
