import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/event_model.dart';
import '../../domain/models/event_category.dart';
import '../../../budget/domain/models/budget_item.dart';
import '../../../timeline/domain/models/timeline_task.dart';
import '../../../vendors/domain/models/vendor_model.dart';
import '../../../ideas/domain/models/event_idea.dart';
import '../../../run_sheet/domain/models/run_sheet_item.dart';
import '../../../assistant/domain/models/chat_message.dart';

class EventAggregate {
  final EventModel event;
  final List<BudgetItem> budgetItems;
  final List<TimelineTask> tasks;
  final List<VendorModel> vendors;
  final List<EventIdea> ideas;
  final List<RunSheetItem> runSheet;
  final List<ChatMessage> chatMessages;

  const EventAggregate({
    required this.event,
    this.budgetItems = const [],
    this.tasks = const [],
    this.vendors = const [],
    this.ideas = const [],
    this.runSheet = const [],
    this.chatMessages = const [],
  });

  EventAggregate copyWith({
    EventModel? event,
    List<BudgetItem>? budgetItems,
    List<TimelineTask>? tasks,
    List<VendorModel>? vendors,
    List<EventIdea>? ideas,
    List<RunSheetItem>? runSheet,
    List<ChatMessage>? chatMessages,
  }) {
    return EventAggregate(
      event: event ?? this.event,
      budgetItems: budgetItems ?? this.budgetItems,
      tasks: tasks ?? this.tasks,
      vendors: vendors ?? this.vendors,
      ideas: ideas ?? this.ideas,
      runSheet: runSheet ?? this.runSheet,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': 1,
      'event': event.toJson(),
      'budgetItems': budgetItems.map((b) => b.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'vendors': vendors.map((v) => v.toJson()).toList(),
      'ideas': ideas.map((i) => i.toJson()).toList(),
      'runSheet': runSheet.map((r) => r.toJson()).toList(),
      'chatMessages': chatMessages.map((c) => c.toJson()).toList(),
    };
  }

  factory EventAggregate.fromJson(Map<String, dynamic> json) {
    return EventAggregate(
      event: json['event'] != null
          ? EventModel.fromJson(json['event'] as Map<String, dynamic>)
          : EventModel(
              id: 'fallback',
              name: 'Untitled Event',
              category: EventCategory.custom,
              date: DateTime.now().add(const Duration(days: 30)),
              city: 'Unknown',
              guestCount: 50,
              totalBudget: 5000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      budgetItems: (json['budgetItems'] as List<dynamic>?)
              ?.map((e) => BudgetItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) => TimelineTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      vendors: (json['vendors'] as List<dynamic>?)
              ?.map((e) => VendorModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      ideas: (json['ideas'] as List<dynamic>?)
              ?.map((e) => EventIdea.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      runSheet: (json['runSheet'] as List<dynamic>?)
              ?.map((e) => RunSheetItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      chatMessages: (json['chatMessages'] as List<dynamic>?)
              ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

abstract class EventRepository {
  Future<List<EventAggregate>> getAllEvents();
  Future<EventAggregate?> getActiveEvent();
  Future<void> setActiveEventId(String eventId);
  Future<void> saveEvent(EventAggregate aggregate);
  Future<void> deleteEvent(String eventId);
  Future<void> clearAllData();
  Future<String> exportDataJson();
  Future<bool> importDataJson(String jsonString);
}

class LocalEventRepository implements EventRepository {
  final SharedPreferences prefs;

  LocalEventRepository(this.prefs);

  @override
  Future<List<EventAggregate>> getAllEvents() async {
    final rawJson = prefs.getString(AppConstants.storageKeyEvents);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        final List<EventAggregate> list = [];
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            try {
              list.add(EventAggregate.fromJson(item));
            } catch (_) {
              // Gracefully skip corrupted single item
            }
          }
        }
        return list;
      }
    } catch (_) {
      // Malformed json fallback
      return [];
    }
    return [];
  }

  @override
  Future<EventAggregate?> getActiveEvent() async {
    final events = await getAllEvents();
    if (events.isEmpty) return null;

    final activeId = prefs.getString(AppConstants.storageKeyActiveEventId);
    if (activeId != null) {
      final found = events.cast<EventAggregate?>().firstWhere(
            (e) => e?.event.id == activeId,
            orElse: () => null,
          );
      if (found != null) return found;
    }

    return events.first;
  }

  @override
  Future<void> setActiveEventId(String eventId) async {
    await prefs.setString(AppConstants.storageKeyActiveEventId, eventId);
  }

  @override
  Future<void> saveEvent(EventAggregate aggregate) async {
    final events = await getAllEvents();
    final index = events.indexWhere((e) => e.event.id == aggregate.event.id);

    if (index >= 0) {
      events[index] = aggregate;
    } else {
      events.add(aggregate);
    }

    final rawJson = jsonEncode(events.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.storageKeyEvents, rawJson);
    await setActiveEventId(aggregate.event.id);
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    final events = await getAllEvents();
    events.removeWhere((e) => e.event.id == eventId);

    final rawJson = jsonEncode(events.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.storageKeyEvents, rawJson);

    final activeId = prefs.getString(AppConstants.storageKeyActiveEventId);
    if (activeId == eventId) {
      if (events.isNotEmpty) {
        await setActiveEventId(events.first.event.id);
      } else {
        await prefs.remove(AppConstants.storageKeyActiveEventId);
      }
    }
  }

  @override
  Future<void> clearAllData() async {
    await prefs.remove(AppConstants.storageKeyEvents);
    await prefs.remove(AppConstants.storageKeyActiveEventId);
  }

  @override
  Future<String> exportDataJson() async {
    final raw = prefs.getString(AppConstants.storageKeyEvents);
    return raw ?? '[]';
  }

  @override
  Future<bool> importDataJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        // Validate each item
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            EventAggregate.fromJson(item);
          }
        }
        await prefs.setString(AppConstants.storageKeyEvents, jsonString);
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }
}
