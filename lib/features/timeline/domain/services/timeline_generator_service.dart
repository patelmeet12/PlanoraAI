import 'package:uuid/uuid.dart';
import '../../../events/domain/models/event_category.dart';
import '../models/timeline_task.dart';

class TimelineGeneratorService {
  /// Generate adaptive milestones based on event date and remaining time
  static List<TimelineTask> generateAdaptiveTimeline({
    required String eventId,
    required EventCategory category,
    required DateTime eventDate,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final int daysRemaining = target.difference(today).inDays;

    final List<TimelineTask> tasks = [];
    const uuid = Uuid();

    if (daysRemaining <= 7) {
      // Urgent compressed timeline (1 to 7 days remaining)
      tasks.addAll(_generateUrgentTimeline(uuid, eventId, category, target, daysRemaining));
    } else if (daysRemaining <= 30) {
      // 1-month fast-track timeline
      tasks.addAll(_generateFastTrackTimeline(uuid, eventId, category, target, daysRemaining));
    } else if (daysRemaining <= 90) {
      // 3-month medium timeline
      tasks.addAll(_generateStandardTimeline(uuid, eventId, category, target, daysRemaining));
    } else {
      // 6+ months comprehensive timeline
      tasks.addAll(_generateComprehensiveTimeline(uuid, eventId, category, target, daysRemaining));
    }

    return tasks;
  }

  static List<TimelineTask> _generateUrgentTimeline(
    Uuid uuid,
    String eventId,
    EventCategory category,
    DateTime eventDate,
    int daysRemaining,
  ) {
    // Highly urgent, sequential tasks
    final task1Id = uuid.v4();
    final task2Id = uuid.v4();
    final task3Id = uuid.v4();
    final task4Id = uuid.v4();
    final task5Id = uuid.v4();

    return [
      TimelineTask(
        id: task1Id,
        eventId: eventId,
        title: 'Lock Venue Access & Layout Confirmation',
        description: 'Verify emergency contact, arrival window, setup hours, and power outlets with venue host.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining - 1).clamp(1, 6))),
        priority: TaskPriority.urgent,
        category: 'Venue',
      ),
      TimelineTask(
        id: task2Id,
        eventId: eventId,
        title: 'Finalize Guest Headcount & Dietary Roster',
        description: 'Lock in final attendee count and send dietary/allergy checklist to caterer immediately.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining - 2).clamp(1, 5))),
        priority: TaskPriority.urgent,
        category: 'Catering',
        dependencies: [task1Id],
      ),
      TimelineTask(
        id: task3Id,
        eventId: eventId,
        title: 'Coordinate Critical Vendors & Day-of Contact List',
        description: 'Establish WhatsApp/call group for photographer, sound engineer, and decor team.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining - 3).clamp(1, 4))),
        priority: TaskPriority.urgent,
        category: 'Vendors',
      ),
      TimelineTask(
        id: task4Id,
        eventId: eventId,
        title: 'Assemble Emergency Event Kit & Signage',
        description: 'Prepare directional signs, first aid kit, extra chargers, tape, and printed schedules.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining - 4).clamp(1, 2))),
        priority: TaskPriority.high,
        category: 'Logistics',
        dependencies: [task3Id],
      ),
      TimelineTask(
        id: task5Id,
        eventId: eventId,
        title: 'Conduct Final Walkthrough & Rehearsal',
        description: 'Test AV sound system, microphone levels, lighting cues, and entrance timing.',
        dueDate: eventDate.subtract(const Duration(days: 1)),
        priority: TaskPriority.urgent,
        category: 'Day-of Prep',
        dependencies: [task1Id, task2Id],
      ),
    ];
  }

  static List<TimelineTask> _generateFastTrackTimeline(
    Uuid uuid,
    String eventId,
    EventCategory category,
    DateTime eventDate,
    int daysRemaining,
  ) {
    final vId = uuid.v4();
    final cId = uuid.v4();
    final invId = uuid.v4();
    final decId = uuid.v4();
    final runId = uuid.v4();

    return [
      TimelineTask(
        id: vId,
        eventId: eventId,
        title: 'Confirm Venue Contract & Deposit',
        description: 'Sign agreement, secure floor plans, and pay initial reservation deposit.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.8).round())),
        priority: TaskPriority.urgent,
        category: 'Venue',
      ),
      TimelineTask(
        id: invId,
        eventId: eventId,
        title: 'Issue Urgent Digital Invitations & RSVP Deadline',
        description: 'Send direct digital invites with RSVP deadline set to 10 days before the event.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.7).round())),
        priority: TaskPriority.high,
        category: 'Invitations',
        dependencies: [vId],
      ),
      TimelineTask(
        id: cId,
        eventId: eventId,
        title: 'Select Catering Menu & Bar Offerings',
        description: 'Finalize menu options, dietary accommodations (vegan/gluten-free), and service style.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.5).round())),
        priority: TaskPriority.high,
        category: 'Catering',
      ),
      TimelineTask(
        id: decId,
        eventId: eventId,
        title: 'Procure Focal Decor & Entertainment Booking',
        description: 'Secure stage backdrop, lighting rentals, and sound equipment or performer.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.3).round())),
        priority: TaskPriority.medium,
        category: 'Decoration',
        dependencies: [vId],
      ),
      TimelineTask(
        id: runId,
        eventId: eventId,
        title: 'Draft Event-Day Run Sheet & Vendor Briefs',
        description: 'Establish minute-by-minute schedule and distribute load-in guidelines to suppliers.',
        dueDate: eventDate.subtract(const Duration(days: 3)),
        priority: TaskPriority.urgent,
        category: 'Coordination',
        dependencies: [cId, decId],
      ),
    ];
  }

  static List<TimelineTask> _generateStandardTimeline(
    Uuid uuid,
    String eventId,
    EventCategory category,
    DateTime eventDate,
    int daysRemaining,
  ) {
    final t1 = uuid.v4();
    final t2 = uuid.v4();
    final t3 = uuid.v4();
    final t4 = uuid.v4();
    final t5 = uuid.v4();
    final t6 = uuid.v4();

    return [
      TimelineTask(
        id: t1,
        eventId: eventId,
        title: 'Define Event Vision & Budget Allocation',
        description: 'Align key stakeholders on mood board, guest limit, and initial budget reserves.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.9).round())),
        priority: TaskPriority.high,
        category: 'Planning',
      ),
      TimelineTask(
        id: t2,
        eventId: eventId,
        title: 'Scout and Contract Primary Venue',
        description: 'Tour shortlist venues, confirm capacity, accessibility compliance, and secure booking.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.75).round())),
        priority: TaskPriority.urgent,
        category: 'Venue',
        dependencies: [t1],
      ),
      TimelineTask(
        id: t3,
        eventId: eventId,
        title: 'Book Core Creative Vendors (Photo, Video, Music)',
        description: 'Review portfolios, check availability, request quotes, and finalize contracts.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.55).round())),
        priority: TaskPriority.high,
        category: 'Vendors',
      ),
      TimelineTask(
        id: t4,
        eventId: eventId,
        title: 'Distribute Invitations & Track RSVPs',
        description: 'Distribute invitations, monitor response rates, and capture special dietary requests.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.4).round())),
        priority: TaskPriority.medium,
        category: 'Invitations',
        dependencies: [t2],
      ),
      TimelineTask(
        id: t5,
        eventId: eventId,
        title: 'Finalize Catering Tasting & Floor Seating Plan',
        description: 'Conduct food tasting session, establish seating charts, and finalize bar menu.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.2).round())),
        priority: TaskPriority.high,
        category: 'Catering',
        dependencies: [t4],
      ),
      TimelineTask(
        id: t6,
        eventId: eventId,
        title: 'Final Master Run Sheet & Vendor Call Time Confirmation',
        description: 'Publish complete run sheet, confirm delivery load-in times, and brief master of ceremonies.',
        dueDate: eventDate.subtract(const Duration(days: 4)),
        priority: TaskPriority.urgent,
        category: 'Coordination',
        dependencies: [t2, t3, t5],
      ),
    ];
  }

  static List<TimelineTask> _generateComprehensiveTimeline(
    Uuid uuid,
    String eventId,
    EventCategory category,
    DateTime eventDate,
    int daysRemaining,
  ) {
    // 6+ months comprehensive phased roadmap
    final m1 = uuid.v4();
    final m2 = uuid.v4();
    final m3 = uuid.v4();
    final m4 = uuid.v4();
    final m5 = uuid.v4();
    final m6 = uuid.v4();
    final m7 = uuid.v4();

    return [
      TimelineTask(
        id: m1,
        eventId: eventId,
        title: 'Establish Event Committee & Target Budget',
        description: 'Set objectives, confirm total budget ceiling, and choose preferred season/date.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.9).round())),
        priority: TaskPriority.high,
        category: 'Concept',
      ),
      TimelineTask(
        id: m2,
        eventId: eventId,
        title: 'Secure Premier Venue & Date Confirmation',
        description: 'Conduct comprehensive site visits, verify accessibility, sign booking contract.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.75).round())),
        priority: TaskPriority.urgent,
        category: 'Venue',
        dependencies: [m1],
      ),
      TimelineTask(
        id: m3,
        eventId: eventId,
        title: 'Engage Priority Vendors (Photography, Catering, Styling)',
        description: 'Lock in sought-after suppliers whose schedules book months in advance.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.6).round())),
        priority: TaskPriority.high,
        category: 'Vendors',
      ),
      TimelineTask(
        id: m4,
        eventId: eventId,
        title: 'Dispatch "Save the Date" Notices & Launch Event Website',
        description: 'Allow traveling guests to reserve travel arrangements and accommodations.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.5).round())),
        priority: TaskPriority.medium,
        category: 'Communications',
        dependencies: [m2],
      ),
      TimelineTask(
        id: m5,
        eventId: eventId,
        title: 'Formal Invitations & Menu Tasting',
        description: 'Send formal RSVP packages and lock in multi-course tasting selections.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.25).round())),
        priority: TaskPriority.high,
        category: 'Catering',
        dependencies: [m3, m4],
      ),
      TimelineTask(
        id: m6,
        eventId: eventId,
        title: 'Logistics, Transportation & Rental Finalization',
        description: 'Confirm shuttle schedules, generator backups, lighting rigs, and floral installations.',
        dueDate: eventDate.subtract(Duration(days: (daysRemaining * 0.1).round())),
        priority: TaskPriority.high,
        category: 'Logistics',
        dependencies: [m2],
      ),
      TimelineTask(
        id: m7,
        eventId: eventId,
        title: 'Rehearsal, Final Vendor Packets & Day-of Run Sheet',
        description: 'Distribute detailed vendor packet, conduct dry run, and ensure readiness.',
        dueDate: eventDate.subtract(const Duration(days: 3)),
        priority: TaskPriority.urgent,
        category: 'Day-of Prep',
        dependencies: [m5, m6],
      ),
    ];
  }

  /// Detect circular dependencies using depth-first search
  static bool hasCircularDependency({
    required String taskId,
    required List<String> candidateDependencies,
    required List<TimelineTask> allTasks,
  }) {
    // If a task depends on itself directly
    if (candidateDependencies.contains(taskId)) return true;

    final visited = <String>{};
    final inStack = <String>{taskId};

    bool dfs(String currentId) {
      inStack.add(currentId);
      visited.add(currentId);

      // Find tasks that currentId depends on
      List<String> deps;
      if (currentId == taskId) {
        deps = candidateDependencies;
      } else {
        final task = allTasks.cast<TimelineTask?>().firstWhere(
              (t) => t?.id == currentId,
              orElse: () => null,
            );
        deps = task?.dependencies ?? [];
      }

      for (final dep in deps) {
        if (!visited.contains(dep)) {
          if (dfs(dep)) return true;
        } else if (inStack.contains(dep)) {
          return true; // Cycle detected!
        }
      }

      inStack.remove(currentId);
      return false;
    }

    for (final candidate in candidateDependencies) {
      if (dfs(candidate)) return true;
    }

    return false;
  }
}
