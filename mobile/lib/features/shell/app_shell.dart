import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/components/state_banners.dart';
import '../wardrobe/wardrobe_view.dart';
import '../productivity/productivity_container_view.dart';
import '../personal_ai/views/ask_omni_view.dart';
import '../profile/profile_view.dart';
import '../money/views/money_container_view.dart';
import '../wellness/views/wellness_container_view.dart';
import '../learning/views/learn_dashboard_view.dart';
import 'home_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  final bool _isOffline = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (_isOffline) const OfflineBanner(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  HomeView(
                    onExploreWardrobe: () => setState(() => _currentIndex = 1),
                    onAskOPAI: () => setState(() => _currentIndex = 2),
                    onOpenProductivity: () => setState(() => _currentIndex = 3),
                    onOpenMoney: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MoneyContainerView()),
                    ),
                    onOpenWellness: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WellnessContainerView()),
                    ),
                    onOpenLearning: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LearnDashboardView()),
                    ),
                  ),
                  const WardrobeView(),
                  const AskOmniView(),
                  const ProductivityContainerView(),
                  const ProfileView(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: colors.surface,
          indicatorColor: colors.primarySoft,
          elevation: 0,
          destinations: [
            const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            const NavigationDestination(icon: Icon(Icons.checkroom_outlined), selectedIcon: Icon(Icons.checkroom), label: 'Wardrobe'),
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              label: 'OP AI',
            ),
            const NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Plan'),
            const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'You'),
          ],
        ),
      ),
    );
  }
}
