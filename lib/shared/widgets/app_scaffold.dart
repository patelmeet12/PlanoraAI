import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../features/events/presentation/providers/event_providers.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';
import 'status_badge.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const AppScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEventAsync = ref.watch(activeEventProvider);
    final allEventsAsync = ref.watch(allEventsProvider);
    final aiSettings = ref.watch(aiSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    final isDesktop = width >= 960;
    final isTablet = width >= 640 && width < 960;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.colorScheme.outline, height: 1),
        ),
        title: Row(
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => context.go('/'),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (width > 500)
                    Text(
                      AppConstants.appTagline,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(160),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // Active Event Switcher Dropdown (if on medium/wide screen)
            if (width > 720)
              Expanded(
                child: activeEventAsync.when(
                  data: (active) {
                    final allEvents = allEventsAsync.value ?? [];
                    if (active == null || allEvents.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: active.event.id,
                            isDense: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 18),
                            items: allEvents.map((agg) {
                              return DropdownMenuItem<String>(
                                value: agg.event.id,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getCategoryIcon(agg.event.category.name),
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: width > 1100 ? 280 : 160,
                                      ),
                                      child: Text(
                                        agg.event.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newId) {
                              if (newId != null && newId != active.event.id) {
                                ref.read(activeEventProvider.notifier).switchEvent(newId);
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
          ],
        ),
        actions: [
          // AI status badge with transparency modal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Semantics(
              button: true,
              label: 'AI Architecture Mode: ${aiSettings.isRealAiEnabled ? "AI-Powered" : "Smart Demo Mode"}. Click to view details.',
              child: Tooltip(
                message: 'AI Planning Mode: Click for details',
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showAiTransparencyDialog(context, aiSettings.isRealAiEnabled),
                  child: StatusBadge(
                    label: aiSettings.isRealAiEnabled ? 'AI-Powered' : 'Smart Demo Mode',
                    icon: aiSettings.isRealAiEnabled ? Icons.bolt : Icons.tune,
                    type: aiSettings.isRealAiEnabled ? BadgeType.success : BadgeType.info,
                    compact: true,
                  ),
                ),
              ),
            ),
          ),

          // Theme toggle
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              final next = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              ref.read(themeModeProvider.notifier).setThemeMode(next);
            },
          ),

          // New Plan CTA
          if (width > 600)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: () => context.go('/wizard'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Plan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ),
        ],
      ),
      drawer: !isDesktop && !isTablet ? _buildDrawer(context) : null,
      body: Row(
        children: [
          if (isDesktop || isTablet)
            _buildNavigationRail(context, isDesktop: isDesktop),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: (!isDesktop && !isTablet)
          ? _buildBottomBar(context)
          : null,
    );
  }

  Widget _buildNavigationRail(BuildContext context, {required bool isDesktop}) {
    final theme = Theme.of(context);
    final items = _navItems;
    final selectedIndex = _getSelectedIndex(currentPath);

    return Container(
      width: isDesktop ? 220 : 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final isSelected = selectedIndex == i;

                if (isDesktop) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    child: Semantics(
                      button: true,
                      selected: isSelected,
                      label: '${item.label} page navigation',
                      child: Material(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => context.go(item.route),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? item.selectedIcon : item.icon,
                                  size: 20,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurface.withAlpha(200),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  // Compact icon-only rail for tablet
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Semantics(
                      button: true,
                      selected: isSelected,
                      label: '${item.label} page navigation',
                      child: IconButton(
                        icon: Icon(isSelected ? item.selectedIcon : item.icon),
                        tooltip: item.label,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withAlpha(180),
                        onPressed: () => context.go(item.route),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: isDesktop
                ? Text(
                    'Planora AI v${AppConstants.appVersion}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final selectedIndex = _getBottomIndex(currentPath);

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (idx) {
        switch (idx) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/budget');
            break;
          case 2:
            context.go('/timeline');
            break;
          case 3:
            context.go('/copilot');
            break;
          case 4:
            Scaffold.of(context).openDrawer();
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.pie_chart_outline),
          selectedIcon: Icon(Icons.pie_chart),
          label: 'Budget',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note),
          label: 'Timeline',
        ),
        NavigationDestination(
          icon: Icon(Icons.smart_toy_outlined),
          selectedIcon: Icon(Icons.smart_toy),
          label: 'Copilot',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu),
          label: 'More',
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
                ),
              ],
            ),
          ),
          ..._navItems.map((item) {
            return ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              selected: currentPath == item.route,
              onTap: () {
                Navigator.of(context).pop();
                context.go(item.route);
              },
            );
          }),
        ],
      ),
    );
  }

  static IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'wedding':
        return Icons.favorite;
      case 'birthday':
        return Icons.cake;
      case 'communityevent':
        return Icons.groups;
      default:
        return Icons.celebration;
    }
  }

  int _getSelectedIndex(String path) {
    for (int i = 0; i < _navItems.length; i++) {
      if (path == _navItems[i].route) return i;
    }
    if (path.startsWith('/wizard')) return 9;
    return 0;
  }

  int _getBottomIndex(String path) {
    if (path == '/') return 0;
    if (path == '/budget') return 1;
    if (path == '/timeline') return 2;
    if (path == '/copilot') return 3;
    return 4;
  }

  void _showAiTransparencyDialog(BuildContext context, bool isRealAi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isRealAi ? Icons.bolt : Icons.tune,
              color: isRealAi ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(isRealAi ? 'AI-Powered Mode' : 'Smart Demo Mode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRealAi
                  ? 'Planora AI is routing planning prompts through a verified server-side proxy. No private API keys are ever stored or exposed in client-side Web code.'
                  : 'Planora AI is running in transparent Smart Demo Mode. It uses deterministic category heuristics, milestone scheduling countdowns, and curated event ontologies entirely in your local browser.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Zero external telemetry or tracking is performed. You can switch to server-proxied AI at any time in Settings.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/settings');
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

const List<_NavItem> _navItems = [
  _NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    route: '/',
  ),
  _NavItem(
    label: 'Event Details',
    icon: Icons.info_outline,
    selectedIcon: Icons.info,
    route: '/details',
  ),
  _NavItem(
    label: 'Budget Optimizer',
    icon: Icons.pie_chart_outline,
    selectedIcon: Icons.pie_chart,
    route: '/budget',
  ),
  _NavItem(
    label: 'Timeline & Tasks',
    icon: Icons.event_note_outlined,
    selectedIcon: Icons.event_note,
    route: '/timeline',
  ),
  _NavItem(
    label: 'Vendor Organizer',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront,
    route: '/vendors',
  ),
  _NavItem(
    label: 'Personalized Ideas',
    icon: Icons.lightbulb_outline,
    selectedIcon: Icons.lightbulb,
    route: '/ideas',
  ),
  _NavItem(
    label: 'AI Copilot',
    icon: Icons.smart_toy_outlined,
    selectedIcon: Icons.smart_toy,
    route: '/copilot',
  ),
  _NavItem(
    label: 'Change Impact',
    icon: Icons.compare_arrows,
    selectedIcon: Icons.compare_arrows,
    route: '/impact',
  ),
  _NavItem(
    label: 'Day-of Run Sheet',
    icon: Icons.schedule_outlined,
    selectedIcon: Icons.schedule,
    route: '/run-sheet',
  ),
  _NavItem(
    label: 'New Plan Wizard',
    icon: Icons.add_circle_outline,
    selectedIcon: Icons.add_circle,
    route: '/wizard',
  ),
  _NavItem(
    label: 'Settings & Data',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    route: '/settings',
  ),
  _NavItem(
    label: 'About / Landing',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    route: '/landing',
  ),
];
