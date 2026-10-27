import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planora_ai/core/constants/app_constants.dart';
import 'package:planora_ai/features/events/data/repositories/event_repository.dart';
import 'package:planora_ai/features/events/domain/models/event_category.dart';
import 'package:planora_ai/features/events/domain/models/event_model.dart';
import 'package:planora_ai/features/budget/domain/models/budget_category.dart';
import 'package:planora_ai/features/budget/domain/models/budget_item.dart';
import 'package:planora_ai/features/timeline/domain/models/timeline_task.dart';

void main() {
  group('LocalEventRepository Tests', () {
    late SharedPreferences prefs;
    late LocalEventRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = LocalEventRepository(prefs);
    });

    test('Returns empty list when storage is empty', () async {
      final events = await repository.getAllEvents();
      expect(events, isEmpty);
      final active = await repository.getActiveEvent();
      expect(active, isNull);
    });

    test('Saves and loads event aggregate accurately', () async {
      final event = EventModel(
        id: 'e_test_1',
        name: 'Milestone Celebration',
        category: EventCategory.birthday,
        date: DateTime(2026, 9, 1),
        city: 'New York',
        guestCount: 80,
        totalBudget: 15000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final budgetItem = const BudgetItem(
        id: 'b1',
        eventId: 'e_test_1',
        category: BudgetCategory.venue,
        name: 'Private Room',
        estimatedAmount: 4000,
      );

      final task = TimelineTask(
        id: 't1',
        eventId: 'e_test_1',
        title: 'Sign Agreement',
        description: '',
        dueDate: DateTime(2026, 8, 15),
      );

      final aggregate = EventAggregate(
        event: event,
        budgetItems: [budgetItem],
        tasks: [task],
      );

      await repository.saveEvent(aggregate);

      final loaded = await repository.getAllEvents();
      expect(loaded.length, 1);
      expect(loaded.first.event.name, 'Milestone Celebration');
      expect(loaded.first.budgetItems.length, 1);
      expect(loaded.first.budgetItems.first.name, 'Private Room');
      expect(loaded.first.tasks.length, 1);

      final active = await repository.getActiveEvent();
      expect(active?.event.id, 'e_test_1');
    });

    test('Gracefully recovers when stored JSON is malformed or corrupted', () async {
      await prefs.setString(AppConstants.storageKeyEvents, 'MALFORMED_JSON_STRING{{{');

      final events = await repository.getAllEvents();
      expect(events, isEmpty); // Recovered safely without throwing exception!
    });

    test('Deletes event and falls back to remaining event as active', () async {
      final event1 = EventModel(
        id: 'e1',
        name: 'Event 1',
        category: EventCategory.wedding,
        date: DateTime.now(),
        city: 'City A',
        guestCount: 50,
        totalBudget: 5000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final event2 = EventModel(
        id: 'e2',
        name: 'Event 2',
        category: EventCategory.birthday,
        date: DateTime.now(),
        city: 'City B',
        guestCount: 30,
        totalBudget: 3000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.saveEvent(EventAggregate(event: event1));
      await repository.saveEvent(EventAggregate(event: event2));
      await repository.setActiveEventId('e1');

      await repository.deleteEvent('e1');

      final remaining = await repository.getAllEvents();
      expect(remaining.length, 1);
      expect(remaining.first.event.id, 'e2');

      final active = await repository.getActiveEvent();
      expect(active?.event.id, 'e2');
    });

    test('Exports and imports valid JSON data payloads correctly', () async {
      final event = EventModel(
        id: 'e_export',
        name: 'Export Test',
        category: EventCategory.communityEvent,
        date: DateTime.now(),
        city: 'Austin',
        guestCount: 150,
        totalBudget: 7500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.saveEvent(EventAggregate(event: event));

      final jsonExport = await repository.exportDataJson();
      expect(jsonExport.contains('Export Test'), true);

      // Wipe and import
      await repository.clearAllData();
      expect(await repository.getAllEvents(), isEmpty);

      final imported = await repository.importDataJson(jsonExport);
      expect(imported, true);

      final restored = await repository.getAllEvents();
      expect(restored.length, 1);
      expect(restored.first.event.name, 'Export Test');
    });

    test('importDataJson safely rejects non-map arrays, objects, and malformed strings', () async {
      expect(await repository.importDataJson(''), false);
      expect(await repository.importDataJson('not json'), false);
      expect(await repository.importDataJson('{"key": "value"}'), false); // Not an array
      expect(await repository.importDataJson('[123, 456]'), false); // Array of numbers, not maps
      expect(await repository.importDataJson('["str1", "str2"]'), false); // Array of strings
    });
  });
}
