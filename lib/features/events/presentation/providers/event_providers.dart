import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/models/event_model.dart';
import '../../../budget/domain/models/budget_item.dart';
import '../../../timeline/domain/models/timeline_task.dart';
import '../../../vendors/domain/models/vendor_model.dart';
import '../../../ideas/domain/models/event_idea.dart';
import '../../../assistant/domain/models/chat_message.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main()');
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalEventRepository(prefs);
});

final allEventsProvider = FutureProvider<List<EventAggregate>>((ref) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.ensureSeeded();
});

class ActiveEventNotifier extends AsyncNotifier<EventAggregate?> {
  @override
  Future<EventAggregate?> build() async {
    final repo = ref.watch(eventRepositoryProvider);
    var active = await repo.getActiveEvent();
    if (active == null) {
      final seeded = await repo.ensureSeeded();
      active = seeded.isNotEmpty ? seeded.first : null;
    }
    return active;
  }

  Future<void> switchEvent(String eventId) async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.setActiveEventId(eventId);
    ref.invalidateSelf();
  }

  Future<void> updateEventProfile(EventModel updatedEvent) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      event: updatedEvent.copyWith(updatedAt: DateTime.now()),
    );
    state = AsyncData(updated);

    final repo = ref.read(eventRepositoryProvider);
    await repo.saveEvent(updated);
    ref.invalidate(allEventsProvider);
  }

  Future<void> createNewEventPlan(EventAggregate newAggregate) async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.saveEvent(newAggregate);
    await repo.setActiveEventId(newAggregate.event.id);
    state = AsyncData(newAggregate);
    ref.invalidate(allEventsProvider);
  }

  Future<void> deleteCurrentEvent() async {
    final current = state.value;
    if (current == null) return;

    final repo = ref.read(eventRepositoryProvider);
    await repo.deleteEvent(current.event.id);
    ref.invalidate(allEventsProvider);
    ref.invalidateSelf();
  }

  // Budget mutations
  Future<void> updateBudgetItem(BudgetItem item) async {
    final current = state.value;
    if (current == null) return;

    final items = List<BudgetItem>.from(current.budgetItems);
    final idx = items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      items[idx] = item;
    } else {
      items.add(item);
    }

    final updated = current.copyWith(budgetItems: items);
    state = AsyncData(updated);
    await ref.read(eventRepositoryProvider).saveEvent(updated);
  }

  Future<void> deleteBudgetItem(String itemId) async {
    final current = state.value;
    if (current == null) return;

    final items = current.budgetItems.where((i) => i.id != itemId).toList();
    final updated = current.copyWith(budgetItems: items);
    state = AsyncData(updated);
    await ref.read(eventRepositoryProvider).saveEvent(updated);
  }

  // Task mutations
  Future<void> toggleTaskCompleted(String taskId) async {
    final current = state.value;
    if (current == null) return;

    final tasks = current.tasks.map((t) {
      if (t.id == taskId) {
        final next = !t.isCompleted;
        return t.copyWith(
          isCompleted: next,
          completedAt: next ? DateTime.now() : null,
          clearCompletedAt: !next,
        );
      }
      return t;
    }).toList();

    final updated = current.copyWith(tasks: tasks);
    state = AsyncData(updated);
    await ref.read(eventRepositoryProvider).saveEvent(updated);
  }

  Future<void> saveTask(TimelineTask task) async {
    final current = state.value;
    if (current == null) return;

    final tasks = List<TimelineTask>.from(current.tasks);
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      tasks[idx] = task;
    } else {
      tasks.add(task);
    }

    final updated = current.copyWith(tasks: tasks);
    state = AsyncData(updated);
    await ref.read(eventRepositoryProvider).saveEvent(updated);
  }

  Future<void> deleteTask(String taskId) async {
    final current = state.value;
    if (current == null) return;

    final tasks = current.tasks.where((t) => t.id != taskId).toList();
    final updated = current.copyWith(tasks: tasks);
    state = AsyncData(updated);
    await ref.read(eventRepositoryProvider).saveEvent(updated);
  }

  // Vendor mutations
  Future<void> saveVendor(VendorModel vendor) async {
    final current = state.value;
    if (current == null) return;

    final vendors = List<VendorModel>.from(current.vendors);
    final idx = vendors.indexWhere((v) => v.id == vendor.id);
    if (idx >= 0) {
      vendors[idx] = vendor;
    } else {
      vendors.add(vendor);
    }

    final updated = current.copyWith(vendors: vendors);
    state = AsyncData(updated);
    await ref.read(eventRepositoryProvider).saveEvent(updated);
  }

  Future<void> deleteVendor(String vendorId) async {
    final current = state.value;
    if (current == null) return;

    final vendors = current.vendors.where((v) => v.id != vendorId).toList();
    final updated = current.copyWith(vendors: vendors);
    state = AsyncData(updated);
    await ref.read(eventRepositoryProvider).saveEvent(updated);
  }

  // Ideas mutations
  Future<void> toggleBookmarkIdea(String ideaId) async {
    final current = state.value;
    if (current == null) return;

    final ideas = current.ideas.map((i) {
      if (i.id == ideaId) {
        return i.copyWith(isBookmarked: !i.isBookmarked);
      }
      return i;
    }).toList();

    final updated = current.copyWith(ideas: ideas);
    state = AsyncData(updated);
    await ref.read(eventRepositoryProvider).saveEvent(updated);
  }

  Future<void> addIdeaToTasks(EventIdea idea) async {
    final current = state.value;
    if (current == null) return;

    final newTask = TimelineTask(
      id: 'task_${idea.id}',
      eventId: current.event.id,
      title: 'Implement: ${idea.title}',
      description: '${idea.description}\nWhy: ${idea.matchReason}',
      dueDate: current.event.date.subtract(const Duration(days: 14)),
      category: idea.category,
      priority: TaskPriority.medium,
    );

    final ideas = current.ideas.map((i) {
      if (i.id == idea.id) {
        return i.copyWith(isAddedToTasks: true);
      }
      return i;
    }).toList();

    final tasks = List<TimelineTask>.from(current.tasks)..add(newTask);
    final updated = current.copyWith(ideas: ideas, tasks: tasks);
    state = AsyncData(updated);
    await ref.read(eventRepositoryProvider).saveEvent(updated);
  }

  // Run Sheet mutations
  Future<void> toggleRunSheetItem(String itemId) async {
    final current = state.value;
    if (current == null) return;

    final runSheet = current.runSheet.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    final updated = current.copyWith(runSheet: runSheet);
    state = AsyncData(updated);
    await ref.read(eventRepositoryProvider).saveEvent(updated);
  }

  // Chat copilot messages
  Future<void> addChatMessage(ChatMessage message) async {
    final current = state.value;
    if (current == null) return;

    final messages = List<ChatMessage>.from(current.chatMessages)..add(message);
    final updated = current.copyWith(chatMessages: messages);
    state = AsyncData(updated);
    await ref.read(eventRepositoryProvider).saveEvent(updated);
  }

  // Reset to initial sample data
  Future<void> resetToSampleData() async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.clearAllData();
    final samples = await repo.ensureSeeded();
    if (samples.isNotEmpty) {
      await repo.setActiveEventId(samples.first.event.id);
    }
    ref.invalidate(allEventsProvider);
    ref.invalidateSelf();
  }
}

final activeEventProvider = AsyncNotifierProvider<ActiveEventNotifier, EventAggregate?>(
  ActiveEventNotifier.new,
);
