import 'package:flutter_test/flutter_test.dart';
import 'package:planora_ai/features/assistant/domain/models/chat_message.dart';
import 'package:planora_ai/features/budget/domain/models/budget_adjustment.dart';
import 'package:planora_ai/features/budget/domain/models/budget_category.dart';
import 'package:planora_ai/features/events/data/repositories/sample_events.dart';
import 'package:planora_ai/features/events/domain/models/event_category.dart';
import 'package:planora_ai/features/ideas/domain/models/event_idea.dart';
import 'package:planora_ai/features/run_sheet/domain/models/run_sheet_item.dart';

void main() {
  group('Models Serialization & SampleEvents Tests', () {
    test('SampleEvents.getInitialSamples returns 3 preconfigured aggregates', () {
      final samples = SampleEvents.getInitialSamples();

      expect(samples.length, 3);

      final wedding = samples.firstWhere((s) => s.event.category == EventCategory.wedding);
      expect(wedding.event.name, contains('Botanical Wedding'));
      expect(wedding.budgetItems.isNotEmpty, true);
      expect(wedding.tasks.isNotEmpty, true);
      expect(wedding.runSheet.isNotEmpty, true);

      final birthday = samples.firstWhere((s) => s.event.category == EventCategory.birthday);
      expect(birthday.event.name, contains('Rooftop Sunset'));

      final community = samples.firstWhere((s) => s.event.category == EventCategory.communityEvent);
      expect(community.event.name, contains('Community Harvest'));
    });

    test('EventIdea serialization and copyWith work seamlessly', () {
      const idea = EventIdea(
        id: 'idea_1',
        eventId: 'e_1',
        title: 'Zero-Waste Seed Paper Placecards',
        category: 'Decor',
        description: 'Plantable place cards seeded with wild lavender',
        estimatedCostRange: '\$100 - \$200',
        minCost: 100.0,
        maxCost: 200.0,
        guestSuitability: 'All guests',
        complexity: IdeaComplexity.low,
        benefits: ['Sustainable', 'Guest keepsake'],
        limitations: ['Requires early printing'],
        matchReason: 'Matches botanical sustainable theme',
        isEcoFriendly: true,
        isBookmarked: true,
      );

      final json = idea.toJson();
      final revived = EventIdea.fromJson(json);

      expect(revived.id, idea.id);
      expect(revived.title, idea.title);
      expect(revived.category, 'Decor');
      expect(revived.isBookmarked, true);
      expect(revived.isEcoFriendly, true);
      expect(revived.minCost, 100.0);
      expect(revived.maxCost, 200.0);
      expect(revived.benefits, contains('Sustainable'));

      final updated = idea.copyWith(isBookmarked: false, isAddedToTasks: true);
      expect(updated.isBookmarked, false);
      expect(updated.isAddedToTasks, true);
    });

    test('ChatMessage and ChangeProposal serialization and copyWith', () {
      final proposal = ChangeProposal(
        actionType: ProposedActionType.budgetCut,
        description: 'Cut 10% budget',
        newBudget: 18000.0,
      );

      final message = ChatMessage(
        id: 'm1',
        sender: ChatSender.assistant,
        text: 'Proposal generated',
        timestamp: DateTime(2026, 10, 27, 12, 0),
        proposal: proposal,
        isApplied: false,
      );

      final json = message.toJson();
      final revived = ChatMessage.fromJson(json);

      expect(revived.id, 'm1');
      expect(revived.sender, ChatSender.assistant);
      expect(revived.text, 'Proposal generated');
      expect(revived.proposal?.actionType, ProposedActionType.budgetCut);
      expect(revived.proposal?.newBudget, 18000.0);

      final updated = message.copyWith(isApplied: true);
      expect(updated.isApplied, true);
    });

    test('RunSheetItem serialization and copyWith preserve timeline data', () {
      const item = RunSheetItem(
        id: 'rs1',
        eventId: 'e1',
        startTime: '10:00',
        endTime: '11:00',
        title: 'Welcome Desk Setup',
        description: 'Prepare badges and banners',
        category: 'Setup',
        location: 'Lobby',
        leadPerson: 'Alex',
        prerequisites: ['rs0'],
        isCompleted: true,
      );

      final json = item.toJson();
      final revived = RunSheetItem.fromJson(json);

      expect(revived.id, item.id);
      expect(revived.title, item.title);
      expect(revived.startTime, '10:00');
      expect(revived.endTime, '11:00');
      expect(revived.location, 'Lobby');
      expect(revived.leadPerson, 'Alex');
      expect(revived.isCompleted, true);
      expect(revived.prerequisites, contains('rs0'));

      final modified = item.copyWith(isCompleted: false, leadPerson: 'Jordan');
      expect(modified.isCompleted, false);
      expect(modified.leadPerson, 'Jordan');
    });

    test('BudgetAdjustmentProposal model preserves adjustment recommendations', () {
      const proposal = BudgetAdjustmentProposal(
        id: 'adj_1',
        budgetItemId: 'b_item_1',
        category: BudgetCategory.decoration,
        title: 'Floral package reduction',
        description: 'Save \$500 by focusing on ceremony florals',
        currentAmount: 2500,
        proposedAmount: 2000,
        rationale: 'Focus floral budget on the focal altar and photography backdrops',
      );

      expect(proposal.id, 'adj_1');
      expect(proposal.budgetItemId, 'b_item_1');
      expect(proposal.category, BudgetCategory.decoration);
      expect(proposal.currentAmount, 2500.0);
      expect(proposal.proposedAmount, 2000.0);
      expect(proposal.rationale, contains('focal altar'));
    });
  });
}
