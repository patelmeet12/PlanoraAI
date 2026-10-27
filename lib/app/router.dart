import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/assistant/presentation/screens/copilot_screen.dart';
import '../features/budget/presentation/screens/budget_planner_screen.dart';
import '../features/events/presentation/screens/dashboard_screen.dart';
import '../features/events/presentation/screens/event_details_screen.dart';
import '../features/events/presentation/screens/landing_screen.dart';
import '../features/ideas/presentation/screens/ideas_screen.dart';
import '../features/impact/presentation/screens/change_impact_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import '../features/run_sheet/presentation/screens/run_sheet_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/timeline/presentation/screens/timeline_screen.dart';
import '../features/vendors/presentation/screens/vendors_screen.dart';
import '../shared/widgets/app_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppScaffold(
          currentPath: state.matchedLocation,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/landing',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LandingScreen(),
          ),
        ),
        GoRoute(
          path: '/wizard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: OnboardingWizardScreen(),
          ),
        ),
        GoRoute(
          path: '/details',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: EventDetailsScreen(),
          ),
        ),
        GoRoute(
          path: '/budget',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BudgetPlannerScreen(),
          ),
        ),
        GoRoute(
          path: '/timeline',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TimelineScreen(),
          ),
        ),
        GoRoute(
          path: '/vendors',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: VendorsScreen(),
          ),
        ),
        GoRoute(
          path: '/ideas',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: IdeasScreen(),
          ),
        ),
        GoRoute(
          path: '/copilot',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CopilotScreen(),
          ),
        ),
        GoRoute(
          path: '/impact',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChangeImpactScreen(),
          ),
        ),
        GoRoute(
          path: '/run-sheet',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RunSheetScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
  ],
);
