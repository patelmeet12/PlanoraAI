import 'package:flutter_test/flutter_test.dart';
import 'package:planora_ai/features/events/domain/models/event_category.dart';
import 'package:planora_ai/features/events/domain/models/event_model.dart';
import 'package:planora_ai/features/run_sheet/domain/models/run_sheet_item.dart';
import 'package:planora_ai/features/run_sheet/domain/services/run_sheet_generator.dart';

void main() {
  group('RunSheetGenerator Tests', () {
    final weddingEvent = EventModel(
      id: 'e_wed',
      name: 'Coastal Wedding',
      category: EventCategory.wedding,
      date: DateTime.now().add(const Duration(days: 60)),
      city: 'Monterey',
      guestCount: 90,
      totalBudget: 25000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final birthdayEvent = EventModel(
      id: 'e_bday',
      name: '40th Birthday Soirée',
      category: EventCategory.birthday,
      date: DateTime.now().add(const Duration(days: 14)),
      city: 'Austin',
      guestCount: 45,
      totalBudget: 8000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('generateRunSheet produces complete wedding day schedule with ordered segments', () {
      final items = RunSheetGenerator.generateRunSheet(weddingEvent);

      expect(items.length, greaterThanOrEqualTo(7));
      expect(items.first.title.toLowerCase().contains('venue') || items.first.title.toLowerCase().contains('load-in'), true);
      expect(items.any((i) => i.title.toLowerCase().contains('ceremony') || i.title.toLowerCase().contains('nuptials')), true);
      expect(items.last.category.toLowerCase().contains('teardown'), true);
    });

    test('generateRunSheet produces tailored party schedule for birthday', () {
      final items = RunSheetGenerator.generateRunSheet(birthdayEvent);

      expect(items.isNotEmpty, true);
      expect(items.any((i) => i.title.toLowerCase().contains('celebration') || i.title.toLowerCase().contains('speeches')), true);
    });

    test('detectAnomalies flags overlapping events in the same location', () {
      final conflictingItems = [
        const RunSheetItem(
          id: 'item_1',
          eventId: 'e1',
          startTime: '10:00',
          endTime: '11:30',
          title: 'Florist Installation',
          description: '',
          category: 'Setup',
          location: 'Grand Ballroom',
        ),
        const RunSheetItem(
          id: 'item_2',
          eventId: 'e1',
          startTime: '11:00', // Overlaps between 11:00 and 11:30
          endTime: '12:00',
          title: 'DJ Sound Check',
          description: '',
          category: 'Vendor',
          location: 'Grand Ballroom', // Same location
        ),
      ];

      final anomalies = RunSheetGenerator.detectAnomalies(conflictingItems);

      expect(anomalies.isNotEmpty, true);
      expect(anomalies.first.title.contains('Location Conflict'), true);
      expect(anomalies.first.title.contains('Grand Ballroom'), true);
      expect(anomalies.first.description.contains('overlap'), true);
    });

    test('detectAnomalies reports no conflicts when times or locations are distinct', () {
      final cleanItems = [
        const RunSheetItem(
          id: 'item_1',
          eventId: 'e1',
          startTime: '09:00',
          endTime: '10:00',
          title: 'Load-In',
          description: '',
          category: 'Setup',
          location: 'Patio',
        ),
        const RunSheetItem(
          id: 'item_2',
          eventId: 'e1',
          startTime: '10:15',
          endTime: '11:30',
          title: 'Guest Arrival',
          description: '',
          category: 'Program',
          location: 'Patio',
        ),
      ];

      final anomalies = RunSheetGenerator.detectAnomalies(cleanItems);
      expect(anomalies, isEmpty);
    });
  });
}
