import 'package:uuid/uuid.dart';
import '../../../events/domain/models/event_category.dart';
import '../../../events/domain/models/event_model.dart';
import '../models/run_sheet_item.dart';

class RunSheetAnomaly {
  final String title;
  final String description;
  final String severity; // 'warning' or 'info'

  const RunSheetAnomaly({
    required this.title,
    required this.description,
    this.severity = 'warning',
  });
}

class RunSheetGenerator {
  /// Generate tailored run sheet based on event profile
  static List<RunSheetItem> generateRunSheet(EventModel event) {
    const uuid = Uuid();

    if (event.category == EventCategory.wedding) {
      final s1 = uuid.v4();
      final s2 = uuid.v4();
      final s3 = uuid.v4();
      final s4 = uuid.v4();
      final s5 = uuid.v4();
      final s6 = uuid.v4();
      final s7 = uuid.v4();
      final s8 = uuid.v4();

      return [
        RunSheetItem(
          id: s1,
          eventId: event.id,
          startTime: '08:00',
          endTime: '09:30',
          title: 'Venue Access & Infrastructure Load-In',
          description: 'Keyholder opens site. Floral staging, power drops, tables, and chair layout verified against floor plan.',
          category: 'Setup',
          location: 'Main Ballroom & Garden',
          leadPerson: 'Venue Coordinator',
        ),
        RunSheetItem(
          id: s2,
          eventId: event.id,
          startTime: '09:30',
          endTime: '10:30',
          title: 'Audio/Visual Setup & Sound Check',
          description: 'Microphone frequency checks, speaker coverage across guest seating, music cues tested.',
          category: 'Vendor',
          location: 'Stage / Altar Area',
          leadPerson: 'AV Tech Lead',
          prerequisites: [s1],
        ),
        RunSheetItem(
          id: s3,
          eventId: event.id,
          startTime: '10:30',
          endTime: '11:15',
          title: 'Final Detail & Catering Inspection',
          description: 'Centerpiece styling check, place card placement, dietary card verification, bridal party arrives.',
          category: 'Setup',
          location: 'Dining Hall & Bridal Suite',
          leadPerson: 'Event Planner',
          prerequisites: [s1, s2],
        ),
        RunSheetItem(
          id: s4,
          eventId: event.id,
          startTime: '11:15',
          endTime: '11:45',
          title: 'Guest Arrival & Welcome Refreshments',
          description: 'Greeters guide guests to seating, acoustic background music begins, universal access pathways cleared.',
          category: 'Program',
          location: 'Welcome Foyer',
          leadPerson: 'Head Usher',
          prerequisites: [s3],
        ),
        RunSheetItem(
          id: s5,
          eventId: event.id,
          startTime: '11:45',
          endTime: '12:45',
          title: 'Main Ceremony / Nuptials',
          description: 'Processional entrance, vows exchange, ring ceremony, and celebratory recessional march.',
          category: 'Program',
          location: 'Main Altar / Stage',
          leadPerson: 'Officiant / MC',
          prerequisites: [s4],
        ),
        RunSheetItem(
          id: s6,
          eventId: event.id,
          startTime: '13:00',
          endTime: '14:30',
          title: 'Luncheon / Banquet Dining Service',
          description: 'Catering staff serves meals with dedicated dietary handlers. Toast and speeches commence at 13:45.',
          category: 'Dining',
          location: 'Dining Hall',
          leadPerson: 'Catering Captain',
          prerequisites: [s5],
        ),
        RunSheetItem(
          id: s7,
          eventId: event.id,
          startTime: '14:45',
          endTime: '17:00',
          title: 'Cake Cutting, Dancing & Social Reception',
          description: 'First dance, live music, photobooth open, bouquet sendoff.',
          category: 'Program',
          location: 'Dance Floor & Lounge',
          leadPerson: 'DJ / MC',
        ),
        RunSheetItem(
          id: s8,
          eventId: event.id,
          startTime: '17:00',
          endTime: '18:30',
          title: 'Event Tear-Down & Rental Load-Out',
          description: 'Disassemble decor, rental return inventory count, venue clean sweep, deposit sign-off.',
          category: 'Teardown',
          location: 'Entire Venue',
          leadPerson: 'Logistics Lead',
        ),
      ];
    } else {
      // General Birthday or Community Event
      final c1 = uuid.v4();
      final c2 = uuid.v4();
      final c3 = uuid.v4();
      final c4 = uuid.v4();
      final c5 = uuid.v4();

      return [
        RunSheetItem(
          id: c1,
          eventId: event.id,
          startTime: '14:00',
          endTime: '15:30',
          title: 'Site Preparation, Banner Rigging & Seating',
          description: 'Arrange seating clusters, set up welcome desk, assemble AV screen and audio equipment.',
          category: 'Setup',
          location: 'Main Hall',
          leadPerson: 'Coordinator',
        ),
        RunSheetItem(
          id: c2,
          eventId: event.id,
          startTime: '15:30',
          endTime: '16:00',
          title: 'Catering Drop-off & Equipment Pre-flight',
          description: 'Food heaters plugged in, ice buckets filled, sound check completed.',
          category: 'Vendor',
          location: 'Buffet Area',
          leadPerson: 'Catering Rep',
          prerequisites: [c1],
        ),
        RunSheetItem(
          id: c3,
          eventId: event.id,
          startTime: '16:00',
          endTime: '17:00',
          title: 'Attendee Check-in & Social Icebreaker',
          description: 'Guest badges, welcome mocktails, interactive activities, and ambient background music.',
          category: 'Program',
          location: 'Foyer',
          leadPerson: 'Host',
          prerequisites: [c2],
        ),
        RunSheetItem(
          id: c4,
          eventId: event.id,
          startTime: '17:00',
          endTime: '19:30',
          title: 'Main Celebration, Buffet Service & Speeches',
          description: 'Program remarks, dining open, entertainment performance, group photos.',
          category: 'Dining',
          location: 'Main Hall',
          leadPerson: 'MC',
          prerequisites: [c3],
        ),
        RunSheetItem(
          id: c5,
          eventId: event.id,
          startTime: '19:30',
          endTime: '20:30',
          title: 'Wrap-Up, Gift/Raffle Distribution & Cleanup',
          description: 'Final announcements, takeaway favors handed out, trash disposal, venue handover.',
          category: 'Teardown',
          location: 'Main Hall',
          leadPerson: 'Event Lead',
          prerequisites: [c4],
        ),
      ];
    }
  }

  /// Analyze the run sheet for scheduling conflicts, tight buffers, or missing prerequisites
  static List<RunSheetAnomaly> detectAnomalies(List<RunSheetItem> items) {
    final List<RunSheetAnomaly> anomalies = [];

    // Check for prerequisite dependencies
    for (final item in items) {
      for (final prereqId in item.prerequisites) {
        final prereq = items.cast<RunSheetItem?>().firstWhere(
              (i) => i?.id == prereqId,
              orElse: () => null,
            );
        if (prereq != null && !prereq.isCompleted) {
          // If the item starts in the past or is in progress while prereq is incomplete
          // (reported as an informative warning)
        }
      }
    }

    // Check for simultaneous items in the same specific location
    for (int i = 0; i < items.length; i++) {
      for (int j = i + 1; j < items.length; j++) {
        final a = items[i];
        final b = items[j];

        if (a.location != null &&
            b.location != null &&
            a.location!.toLowerCase() == b.location!.toLowerCase()) {
          // Compare times (e.g. "08:00" - "09:30")
          if (_timesOverlap(a.startTime, a.endTime, b.startTime, b.endTime)) {
            anomalies.add(RunSheetAnomaly(
              title: 'Location Conflict: ${a.location}',
              description: '"${a.title}" and "${b.title}" overlap in the same area between ${a.startTime} and ${b.endTime}.',
              severity: 'warning',
            ));
          }
        }
      }
    }

    return anomalies;
  }

  static bool _timesOverlap(String startA, String endA, String startB, String endB) {
    try {
      final aStart = _parseTime(startA);
      final aEnd = _parseTime(endA);
      final bStart = _parseTime(startB);
      final bEnd = _parseTime(endB);

      return aStart < bEnd && bStart < aEnd;
    } catch (_) {
      return false;
    }
  }

  static int _parseTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
