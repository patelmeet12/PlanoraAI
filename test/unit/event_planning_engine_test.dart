import 'package:flutter_test/flutter_test.dart';
import 'package:planora_ai/features/assistant/domain/services/event_planning_engine.dart';
import 'package:planora_ai/features/events/domain/models/event_category.dart';
import 'package:planora_ai/features/events/domain/models/event_model.dart';

void main() {
  group('EventPlanningService Tests', () {
    final weddingEvent = EventModel(
      id: 'e_wed',
      name: 'Pacific Coast Wedding',
      category: EventCategory.wedding,
      date: DateTime.now().add(const Duration(days: 120)),
      city: 'Seattle',
      guestCount: 120,
      totalBudget: 35000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('generatePlanSync produces full tailored plan with budget, tasks, vendors, and run sheet', () {
      final plan = EventPlanningService.generatePlanSync(event: weddingEvent);

      expect(plan.event.id, weddingEvent.id);
      expect(plan.conceptSummary.isNotEmpty, true);
      expect(plan.themeStatement.isNotEmpty, true);
      expect(plan.budgetItems.isNotEmpty, true);
      expect(plan.tasks.isNotEmpty, true);
      expect(plan.vendors.isNotEmpty, true);
      expect(plan.ideas.isNotEmpty, true);
      expect(plan.runSheet.isNotEmpty, true);
      expect(plan.potentialRisks.isNotEmpty, true);
      expect(plan.suggestedNextActions.isNotEmpty, true);
      expect(plan.isRealAi, false); // Transparent Smart Demo Mode
    });

    test('generatePlan async returns deterministic plan in default demo mode', () async {
      final plan = await EventPlanningService.generatePlan(event: weddingEvent);

      expect(plan.budgetItems.length, greaterThanOrEqualTo(5));
      expect(plan.tasks.length, greaterThanOrEqualTo(4));
    });

    test('validateStructuredAiResponse validates schema and rejects malformed payloads', () {
      // Valid payload
      final valid = {
        'conceptSummary': 'An elegant seaside celebration with coastal botanicals.',
        'themeStatement': 'Coastal Elegance & Sustainable Local Sourcing',
        'potentialRisks': ['High wind speeds on open bluff', 'Limited parking capacity'],
        'suggestedNextActions': ['Book chartered shuttles', 'Confirm backup tent anchor points'],
      };
      expect(EventPlanningService.validateStructuredAiResponse(valid), true);

      // Non-map payload
      expect(EventPlanningService.validateStructuredAiResponse('not a map'), false);
      expect(EventPlanningService.validateStructuredAiResponse([1, 2, 3]), false);
      expect(EventPlanningService.validateStructuredAiResponse(null), false);

      // Missing or empty conceptSummary
      expect(EventPlanningService.validateStructuredAiResponse({
        'conceptSummary': '',
        'themeStatement': 'Theme',
        'potentialRisks': [],
        'suggestedNextActions': [],
      }), false);

      // Non-list potentialRisks
      expect(EventPlanningService.validateStructuredAiResponse({
        'conceptSummary': 'Valid summary',
        'themeStatement': 'Valid theme',
        'potentialRisks': 'Not a list',
        'suggestedNextActions': [],
      }), false);
    });

    test('parseStructuredAiPlan parses valid structured AI json and falls back safely on invalid', () {
      final validJson = {
        'conceptSummary': 'AI generated bespoke concept summary.',
        'themeStatement': 'AI curated thematic direction.',
        'potentialRisks': ['Risk A', 'Risk B'],
        'suggestedNextActions': ['Action 1', 'Action 2'],
      };

      final plan = EventPlanningService.parseStructuredAiPlan(
        json: validJson,
        event: weddingEvent,
      );

      expect(plan.conceptSummary, 'AI generated bespoke concept summary.');
      expect(plan.themeStatement, 'AI curated thematic direction.');
      expect(plan.potentialRisks, contains('Risk A'));
      expect(plan.suggestedNextActions, contains('Action 1'));

      // Malformed fallback
      final fallbackPlan = EventPlanningService.parseStructuredAiPlan(
        json: {'invalid': 123},
        event: weddingEvent,
      );
      expect(fallbackPlan.conceptSummary.isNotEmpty, true);
    });
  });
}
