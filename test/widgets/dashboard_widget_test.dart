import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planora_ai/features/events/data/repositories/event_repository.dart';
import 'package:planora_ai/features/events/domain/models/event_category.dart';
import 'package:planora_ai/features/events/domain/models/event_model.dart';
import 'package:planora_ai/features/events/presentation/providers/event_providers.dart';
import 'package:planora_ai/features/events/presentation/screens/dashboard_screen.dart';
import 'package:planora_ai/features/budget/domain/models/budget_category.dart';
import 'package:planora_ai/features/budget/domain/models/budget_item.dart';
import 'package:planora_ai/features/timeline/domain/models/timeline_task.dart';

void main() {
  testWidgets('DashboardScreen renders countdown, budget health, and next action', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testEvent = EventModel(
      id: 'e_widget_test',
      name: 'Spring Gala Showcase',
      category: EventCategory.wedding,
      date: DateTime.now().add(const Duration(days: 30)),
      city: 'Chicago, IL',
      guestCount: 100,
      totalBudget: 20000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final task = TimelineTask(
      id: 'task_1',
      eventId: 'e_widget_test',
      title: 'Confirm Venue Contract',
      description: 'Sign contract and pay initial deposit',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      priority: TaskPriority.urgent,
    );

    final budgetItem = const BudgetItem(
      id: 'b_1',
      eventId: 'e_widget_test',
      category: BudgetCategory.venue,
      name: 'Grand Ballroom',
      estimatedAmount: 8000,
    );

    final aggregate = EventAggregate(
      event: testEvent,
      tasks: [task],
      budgetItems: [budgetItem],
    );

    final repo = LocalEventRepository(prefs);
    await repo.saveEvent(aggregate);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DashboardScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify event title rendered
    expect(find.text('Spring Gala Showcase'), findsOneWidget);
    // Verify countdown days text
    expect(find.text('Days Left'), findsOneWidget);
    // Verify Next Recommended Action rendered
    expect(find.text('NEXT RECOMMENDED ACTION'), findsOneWidget);
    expect(find.text('Confirm Venue Contract'), findsWidgets);
    // Verify Budget Health card
    expect(find.text('Budget Health'), findsOneWidget);
    expect(find.text('Planning Readiness'), findsOneWidget);

    // Tap "Mark Done" on the next best action
    final markDoneButton = find.text('Mark Done');
    expect(markDoneButton, findsOneWidget);
    await tester.ensureVisible(markDoneButton);
    await tester.tap(markDoneButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify task completion feedback snackbar
    expect(find.text('✓ Marked "Confirm Venue Contract" as completed!'), findsOneWidget);
  });
}
