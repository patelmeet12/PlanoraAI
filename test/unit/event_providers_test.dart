import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planora_ai/features/events/domain/models/event_category.dart';
import 'package:planora_ai/features/events/domain/models/event_model.dart';
import 'package:planora_ai/features/events/data/repositories/event_repository.dart';
import 'package:planora_ai/features/events/presentation/providers/event_providers.dart';
import 'package:planora_ai/features/budget/domain/models/budget_category.dart';
import 'package:planora_ai/features/budget/domain/models/budget_item.dart';
import 'package:planora_ai/features/timeline/domain/models/timeline_task.dart';
import 'package:planora_ai/features/vendors/domain/models/vendor_category.dart';
import 'package:planora_ai/features/vendors/domain/models/vendor_model.dart';
import 'package:planora_ai/features/assistant/domain/models/chat_message.dart';

void main() {
  group('ActiveEventNotifier & EventProviders State Tests', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initializes by seeding default sample events and sets active event', () async {
      final initial = await container.read(activeEventProvider.future);
      expect(initial, isNotNull);
      expect(initial!.event.name, isNotEmpty);
      expect(initial.budgetItems, isNotEmpty);
      expect(initial.tasks, isNotEmpty);

      final allEvents = await container.read(allEventsProvider.future);
      expect(allEvents.length, greaterThanOrEqualTo(2));
    });

    test('updateEventProfile updates profile and timestamp', () async {
      final notifier = container.read(activeEventProvider.notifier);
      final initial = await container.read(activeEventProvider.future);
      expect(initial, isNotNull);

      final updatedProfile = initial!.event.copyWith(
        name: 'Updated Gala Extravaganza',
        totalBudget: 45000,
      );

      await notifier.updateEventProfile(updatedProfile);

      final current = container.read(activeEventProvider).value;
      expect(current?.event.name, 'Updated Gala Extravaganza');
      expect(current?.event.totalBudget, 45000.0);
    });

    test('Budget item mutations: insert, update, and delete', () async {
      final notifier = container.read(activeEventProvider.notifier);
      final initial = await container.read(activeEventProvider.future);
      expect(initial, isNotNull);

      // Insert new budget item
      final newItem = const BudgetItem(
        id: 'new_item_1',
        eventId: 'test_event',
        category: BudgetCategory.contingency,
        name: 'Emergency Reserve',
        estimatedAmount: 2000,
      );
      await notifier.updateBudgetItem(newItem);

      var state = container.read(activeEventProvider).value;
      expect(state?.budgetItems.any((b) => b.id == 'new_item_1'), true);

      // Update existing item
      final confirmedItem = newItem.copyWith(
        confirmedAmount: 1800,
        isConfirmed: true,
      );
      await notifier.updateBudgetItem(confirmedItem);

      state = container.read(activeEventProvider).value;
      final retrieved = state?.budgetItems.firstWhere((b) => b.id == 'new_item_1');
      expect(retrieved?.isConfirmed, true);
      expect(retrieved?.confirmedAmount, 1800.0);

      // Delete item
      await notifier.deleteBudgetItem('new_item_1');
      state = container.read(activeEventProvider).value;
      expect(state?.budgetItems.any((b) => b.id == 'new_item_1'), false);
    });

    test('Task mutations: insert, update, toggle completion, and delete', () async {
      final notifier = container.read(activeEventProvider.notifier);
      final initial = await container.read(activeEventProvider.future);
      expect(initial, isNotNull);

      // Insert new task
      final newTask = TimelineTask(
        id: 'task_new_99',
        eventId: initial!.event.id,
        title: 'Sign Lighting Rental Contract',
        description: 'Verify power requirements',
        dueDate: DateTime.now().add(const Duration(days: 10)),
        priority: TaskPriority.high,
      );
      await notifier.saveTask(newTask);

      var state = container.read(activeEventProvider).value;
      expect(state?.tasks.any((t) => t.id == 'task_new_99'), true);

      // Toggle completed
      await notifier.toggleTaskCompleted('task_new_99');
      state = container.read(activeEventProvider).value;
      var task = state?.tasks.firstWhere((t) => t.id == 'task_new_99');
      expect(task?.isCompleted, true);
      expect(task?.completedAt, isNotNull);

      // Toggle back to incomplete
      await notifier.toggleTaskCompleted('task_new_99');
      state = container.read(activeEventProvider).value;
      task = state?.tasks.firstWhere((t) => t.id == 'task_new_99');
      expect(task?.isCompleted, false);
      expect(task?.completedAt, isNull);

      // Delete task
      await notifier.deleteTask('task_new_99');
      state = container.read(activeEventProvider).value;
      expect(state?.tasks.any((t) => t.id == 'task_new_99'), false);
    });

    test('Vendor mutations: insert, update, and delete', () async {
      final notifier = container.read(activeEventProvider.notifier);
      final initial = await container.read(activeEventProvider.future);
      expect(initial, isNotNull);

      // Insert vendor
      final newVendor = const VendorModel(
        id: 'vendor_new_1',
        eventId: 'test_event',
        name: 'Artisan Patisserie',
        category: VendorCategory.caterer,
        quotedPrice: 1200,
        bookingStatus: BookingStatus.quoted,
      );
      await notifier.saveVendor(newVendor);

      var state = container.read(activeEventProvider).value;
      expect(state?.vendors.any((v) => v.id == 'vendor_new_1'), true);

      // Update vendor
      final bookedVendor = newVendor.copyWith(bookingStatus: BookingStatus.booked);
      await notifier.saveVendor(bookedVendor);

      state = container.read(activeEventProvider).value;
      final saved = state?.vendors.firstWhere((v) => v.id == 'vendor_new_1');
      expect(saved?.bookingStatus, BookingStatus.booked);

      // Delete vendor
      await notifier.deleteVendor('vendor_new_1');
      state = container.read(activeEventProvider).value;
      expect(state?.vendors.any((v) => v.id == 'vendor_new_1'), false);
    });

    test('Idea bookmarking and adding to timeline tasks', () async {
      final notifier = container.read(activeEventProvider.notifier);
      final initial = await container.read(activeEventProvider.future);
      expect(initial, isNotNull);
      expect(initial!.ideas, isNotEmpty);

      final idea = initial.ideas.first;
      final initialBookmarkStatus = idea.isBookmarked;

      // Toggle bookmark
      await notifier.toggleBookmarkIdea(idea.id);
      var state = container.read(activeEventProvider).value;
      var updatedIdea = state?.ideas.firstWhere((i) => i.id == idea.id);
      expect(updatedIdea?.isBookmarked, !initialBookmarkStatus);

      // Add idea to tasks
      await notifier.addIdeaToTasks(idea);
      state = container.read(activeEventProvider).value;
      updatedIdea = state?.ideas.firstWhere((i) => i.id == idea.id);
      expect(updatedIdea?.isAddedToTasks, true);
      expect(state?.tasks.any((t) => t.id == 'task_${idea.id}'), true);
    });

    test('Run sheet item completion toggle and chat message appended', () async {
      final notifier = container.read(activeEventProvider.notifier);
      final initial = await container.read(activeEventProvider.future);
      expect(initial, isNotNull);
      expect(initial!.runSheet, isNotEmpty);

      final runItem = initial.runSheet.first;
      await notifier.toggleRunSheetItem(runItem.id);

      var state = container.read(activeEventProvider).value;
      var updatedRunItem = state?.runSheet.firstWhere((r) => r.id == runItem.id);
      expect(updatedRunItem?.isCompleted, !runItem.isCompleted);

      // Add chat message
      final chat = ChatMessage(
        id: 'msg_test',
        sender: ChatSender.assistant,
        text: 'Reviewing budget projections now.',
        timestamp: DateTime.now(),
      );
      await notifier.addChatMessage(chat);

      state = container.read(activeEventProvider).value;
      expect(state?.chatMessages.any((m) => m.id == 'msg_test'), true);
    });

    test('switchEvent, createNewEventPlan, deleteCurrentEvent, and resetToSampleData', () async {
      final notifier = container.read(activeEventProvider.notifier);
      await container.read(activeEventProvider.future);

      final allEvents = await container.read(allEventsProvider.future);
      expect(allEvents.length, greaterThanOrEqualTo(2));

      // Switch event
      final secondEventId = allEvents[1].event.id;
      await notifier.switchEvent(secondEventId);
      final switched = await container.read(activeEventProvider.future);
      expect(switched?.event.id, secondEventId);

      // Create new event plan
      final newAggregate = EventAggregate(
        event: EventModel(
          id: 'custom_event_99',
          name: 'Silver Jubilee',
          category: EventCategory.anniversary,
          date: DateTime.now().add(const Duration(days: 45)),
          city: 'Seattle',
          guestCount: 60,
          totalBudget: 12000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await notifier.createNewEventPlan(newAggregate);
      var current = container.read(activeEventProvider).value;
      expect(current?.event.id, 'custom_event_99');

      // Delete current event
      await notifier.deleteCurrentEvent();
      final afterDelete = await container.read(activeEventProvider.future);
      expect(afterDelete?.event.id != 'custom_event_99', true);

      // Reset to sample data
      await notifier.resetToSampleData();
      final resetActive = await container.read(activeEventProvider.future);
      expect(resetActive, isNotNull);
      final resetEvents = await container.read(allEventsProvider.future);
      expect(resetEvents.length, greaterThanOrEqualTo(2));
    });
  });
}
