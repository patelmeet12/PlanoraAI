import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planora_ai/features/events/presentation/providers/event_providers.dart';
import 'package:planora_ai/shared/widgets/accessible_card.dart';
import 'package:planora_ai/shared/widgets/app_scaffold.dart';
import 'package:planora_ai/shared/widgets/confirm_dialog.dart';
import 'package:planora_ai/shared/widgets/empty_state_view.dart';
import 'package:planora_ai/shared/widgets/status_badge.dart';

void main() {
  group('Accessibility & Shared Widgets Tests', () {
    testWidgets('StatusBadge exposes correct semantic label and renders icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              label: 'Within Budget',
              type: BadgeType.success,
              icon: Icons.check_circle,
            ),
          ),
        ),
      );

      expect(find.text('Within Budget'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Verify semantics
      final handle = tester.ensureSemantics();
      expect(tester.getSemantics(find.byType(StatusBadge)), matchesSemantics(
        label: 'Within Budget status badge',
      ));
      handle.dispose();
    });

    testWidgets('AccessibleCard wraps content and provides elevated semantic grouping', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleCard(
              semanticLabel: 'Milestone Summary Section',
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);

      final handle = tester.ensureSemantics();
      expect(tester.getSemantics(find.byType(AccessibleCard)).label, contains('Milestone Summary Section'));
      handle.dispose();
    });

    testWidgets('ConfirmDialog responds to confirm and cancel actions', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ConfirmDialog.show(
                    context,
                    title: 'Delete Milestone?',
                    content: 'This will permanently remove the item.',
                    confirmLabel: 'Confirm Delete',
                    isDestructive: true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Milestone?'), findsOneWidget);
      expect(find.text('This will permanently remove the item.'), findsOneWidget);

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, false);

      // Open dialog again and confirm
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm Delete'));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('EmptyStateView renders title, description, and triggers CTA action', (WidgetTester tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.event_busy,
              title: 'No Tasks Found',
              message: 'You have not added any timeline milestones yet.',
              actionLabel: 'Add First Task',
              onAction: () {
                actionTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No Tasks Found'), findsOneWidget);
      expect(find.text('You have not added any timeline milestones yet.'), findsOneWidget);
      expect(find.text('Add First Task'), findsOneWidget);

      await tester.tap(find.text('Add First Task'));
      await tester.pump();

      expect(actionTriggered, true);
    });

    testWidgets('AppScaffold renders accessible navigation rail on desktop and provides semantics', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: AppScaffold(
              currentPath: '/',
              child: Text('Dashboard Body Content'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dashboard Body Content'), findsOneWidget);
      expect(find.text('Planora AI'), findsOneWidget);

      // Verify semantics on navigation rail items
      final handle = tester.ensureSemantics();
      expect(find.byTooltip('Toggle Theme'), findsOneWidget);
      expect(find.text('New Plan'), findsOneWidget);
      handle.dispose();
    });
  });
}
