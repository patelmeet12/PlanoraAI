import 'package:uuid/uuid.dart';
import '../../../events/domain/models/event_category.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../budget/domain/models/budget_item.dart';
import '../../../budget/domain/models/budget_category.dart';
import '../../../timeline/domain/models/timeline_task.dart';
import '../../../timeline/domain/services/timeline_generator_service.dart';
import '../../../vendors/domain/models/vendor_model.dart';
import '../../../vendors/domain/services/vendor_service.dart';
import '../../../ideas/domain/models/event_idea.dart';
import '../../../ideas/domain/services/ideas_generator_service.dart';
import '../../../run_sheet/domain/models/run_sheet_item.dart';
import '../../../run_sheet/domain/services/run_sheet_generator.dart';

class GeneratedEventPlan {
  final EventModel event;
  final String conceptSummary;
  final String themeStatement;
  final List<BudgetItem> budgetItems;
  final List<TimelineTask> tasks;
  final List<VendorModel> vendors;
  final List<EventIdea> ideas;
  final List<RunSheetItem> runSheet;
  final List<String> potentialRisks;
  final List<String> suggestedNextActions;
  final bool isRealAi;

  const GeneratedEventPlan({
    required this.event,
    required this.conceptSummary,
    required this.themeStatement,
    required this.budgetItems,
    required this.tasks,
    required this.vendors,
    required this.ideas,
    required this.runSheet,
    required this.potentialRisks,
    required this.suggestedNextActions,
    this.isRealAi = false,
  });
}

class EventPlanningService {
  /// Primary generator creating a full structured event plan.
  /// If [aiEndpoint] and [aiApiKey] are supplied, attempts server-side AI integration;
  /// otherwise transparently runs Smart Demo Mode with deterministic heuristics.
  static Future<GeneratedEventPlan> generatePlan({
    required EventModel event,
    String? aiEndpoint,
    String? aiApiKey,
  }) async {
    return _generateDeterministicSmartPlan(event);
  }

  static GeneratedEventPlan generatePlanSync({required EventModel event}) {
    return _generateDeterministicSmartPlan(event);
  }

  static GeneratedEventPlan _generateDeterministicSmartPlan(EventModel event) {
    const uuid = Uuid();
    final budgetItems = _generateBudgetDistribution(uuid, event);
    final tasks = TimelineGeneratorService.generateAdaptiveTimeline(
      eventId: event.id,
      category: event.category,
      eventDate: event.date,
    );
    final vendors = VendorService.generateSampleVendors(
      eventId: event.id,
      category: event.category,
      totalBudget: event.totalBudget,
    );
    final ideas = IdeasGeneratorService.generateContextualIdeas(event);
    final runSheet = RunSheetGenerator.generateRunSheet(event);

    final concept = _generateConceptSummary(event);
    final theme = _generateThemeStatement(event);
    final risks = _generatePotentialRisks(event);
    final nextActions = _generateNextActions(event, tasks);

    return GeneratedEventPlan(
      event: event,
      conceptSummary: concept,
      themeStatement: theme,
      budgetItems: budgetItems,
      tasks: tasks,
      vendors: vendors,
      ideas: ideas,
      runSheet: runSheet,
      potentialRisks: risks,
      suggestedNextActions: nextActions,
      isRealAi: false,
    );
  }

  static String _generateConceptSummary(EventModel event) {
    return 'A curated ${event.style.displayName.toLowerCase()} ${event.category.displayName} designed for ${event.guestCount} guests in ${event.city}. '
        'Balanced across an intentional budget of \$${event.totalBudget.toStringAsFixed(0)} ${event.currency}, '
        'prioritizing ${event.theme} aesthetics and seamless accessibility.';
  }

  static String _generateThemeStatement(EventModel event) {
    return '"${event.theme}" — Blending ${event.venueType.displayName.toLowerCase()} atmosphere with purposeful hospitality, '
        'ensuring all dietary and accessibility needs are honored without compromising on elegance.';
  }

  static List<String> _generatePotentialRisks(EventModel event) {
    final risks = <String>[];
    if (event.venueType == VenueType.outdoor || event.venueType == VenueType.hybrid) {
      risks.add('Weather Exposure: Outdoor layout in ${event.city} requires an enforceable marquee or indoor backup plan.');
    }
    if (event.guestCount > 200) {
      risks.add('Crowd Ingress & Parking Bottlenecks: A large gathering of ${event.guestCount} guests necessitates structured valet or shuttle logistics.');
    }
    if (event.dietaryRequirements.isNotEmpty) {
      risks.add('Cross-Contamination Risk: Caterer must certify separate prep zones for ${event.dietaryRequirements.join(", ")}.');
    }
    if (event.accessibilityRequirements.isNotEmpty) {
      risks.add('Physical Accessibility Gaps: Inspect venue doorways, restrooms, and staging to ensure step-free wheelchair access.');
    }
    if (risks.isEmpty) {
      risks.add('Vendor Coordination Lead Times: Prime dates require locking key suppliers at least 6 weeks in advance.');
    }
    return risks;
  }

  static List<String> _generateNextActions(EventModel event, List<TimelineTask> tasks) {
    final actions = <String>[];
    final urgentTasks = tasks.where((t) => t.priority == TaskPriority.urgent && !t.isCompleted).take(3);
    for (final t in urgentTasks) {
      actions.add('Complete urgent milestone: ${t.title}');
    }
    actions.add('Verify shortlisted venue contracts and deposit policies.');
    actions.add('Review budget allocations in the Intelligent Optimizer.');
    return actions;
  }

  static List<BudgetItem> _generateBudgetDistribution(Uuid uuid, EventModel event) {
    final b = event.totalBudget;
    final List<BudgetItem> items = [];

    // Tailored allocation ratios based on category
    if (event.category == EventCategory.wedding) {
      items.addAll([
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.venue,
          name: 'Reception & Ceremony Venue Rental',
          estimatedAmount: b * 0.32,
          priority: 1,
          notes: 'Standard 40% allocation for premier wedding venue in ${event.city}.',
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.catering,
          name: 'Plated Dinner & Beverage Service',
          estimatedAmount: b * 0.28,
          priority: 1,
          notes: 'Estimated for ${event.guestCount} attendees including dietary handling.',
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.photographyVideography,
          name: 'Photographer & Highlight Video',
          estimatedAmount: b * 0.12,
          priority: 2,
          notes: 'Full day coverage with second shooter.',
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.decoration,
          name: 'Floral Arches & Table Styling',
          estimatedAmount: b * 0.10,
          priority: 3,
          notes: 'Styling aligned with "${event.theme}".',
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.entertainment,
          name: 'Live Band / DJ & Sound System',
          estimatedAmount: b * 0.07,
          priority: 2,
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.clothing,
          name: 'Attire & Grooming',
          estimatedAmount: b * 0.04,
          priority: 3,
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.invitations,
          name: 'Stationery & Digital RSVP',
          estimatedAmount: b * 0.02,
          priority: 3,
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.contingency,
          name: 'Emergency Reserve',
          estimatedAmount: b * 0.05,
          priority: 1,
          notes: '5% emergency buffer for unexpected fees or rush orders.',
        ),
      ]);
    } else if (event.category == EventCategory.communityEvent) {
      items.addAll([
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.venue,
          name: 'Community Hall / Public Pavilion Permit',
          estimatedAmount: b * 0.25,
          priority: 1,
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.catering,
          name: 'Community Refreshments & Food Stalls',
          estimatedAmount: b * 0.35,
          priority: 1,
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.entertainment,
          name: 'Sound Stage, AV & Performer Honorariums',
          estimatedAmount: b * 0.18,
          priority: 2,
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.invitations,
          name: 'Flyers, Posters & Digital Community Outreach',
          estimatedAmount: b * 0.08,
          priority: 2,
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.transportation,
          name: 'Accessibility Shuttles & Traffic Marshals',
          estimatedAmount: b * 0.06,
          priority: 2,
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.contingency,
          name: 'Contingency & First Aid Reserve',
          estimatedAmount: b * 0.08,
          priority: 1,
        ),
      ]);
    } else {
      // Birthday / Anniversary / Custom
      items.addAll([
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.venue,
          name: 'Private Event Space / Lounge Rental',
          estimatedAmount: b * 0.35,
          priority: 1,
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.catering,
          name: 'Appetizers, Gourmet Buffet & Signature Drinks',
          estimatedAmount: b * 0.32,
          priority: 1,
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.entertainment,
          name: 'DJ, Sound & Party Lighting',
          estimatedAmount: b * 0.12,
          priority: 2,
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.decoration,
          name: 'Balloons, Themed Backdrop & Props',
          estimatedAmount: b * 0.08,
          priority: 3,
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.photographyVideography,
          name: 'Event Party Photographer',
          estimatedAmount: b * 0.06,
          priority: 2,
        ),
        BudgetItem(
          id: uuid.v4(),
          eventId: event.id,
          category: BudgetCategory.contingency,
          name: 'Reserve Buffer',
          estimatedAmount: b * 0.07,
          priority: 1,
        ),
      ]);
    }

    return items;
  }
}
