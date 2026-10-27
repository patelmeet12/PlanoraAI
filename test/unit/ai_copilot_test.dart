import 'package:flutter_test/flutter_test.dart';
import 'package:planora_ai/features/assistant/domain/models/chat_message.dart';
import 'package:planora_ai/features/assistant/domain/services/ai_copilot_service.dart';
import 'package:planora_ai/features/budget/domain/models/budget_category.dart';
import 'package:planora_ai/features/budget/domain/models/budget_item.dart';
import 'package:planora_ai/features/events/domain/models/event_category.dart';
import 'package:planora_ai/features/events/domain/models/event_model.dart';
import 'package:planora_ai/features/timeline/domain/models/timeline_task.dart';

void main() {
  group('AiCopilotService Tests', () {
    final event = EventModel(
      id: 'e_copilot',
      name: 'Autumn Botanical Wedding',
      category: EventCategory.wedding,
      date: DateTime.now().add(const Duration(days: 30)),
      city: 'Portland',
      guestCount: 100,
      totalBudget: 20000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final budgetItems = [
      const BudgetItem(
        id: 'b1',
        eventId: 'e_copilot',
        category: BudgetCategory.venue,
        name: 'Garden Pavilion',
        estimatedAmount: 8000,
        confirmedAmount: 8000,
        isConfirmed: true,
      ),
      const BudgetItem(
        id: 'b2',
        eventId: 'e_copilot',
        category: BudgetCategory.decoration,
        name: 'Floral Installations',
        estimatedAmount: 3000,
        isConfirmed: false,
      ),
    ];

    final tasks = [
      TimelineTask(
        id: 't1',
        eventId: 'e_copilot',
        title: 'Review Floral Proposals',
        description: 'Compare floral designer options',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        category: 'Vendors',
      ),
    ];

    test('Budget reduction prompt generates budgetCut proposal and respects bounds', () {
      final msg = AiCopilotService.processUserPrompt(
        prompt: 'Please reduce my budget by 20%',
        event: event,
        budgetItems: budgetItems,
        tasks: tasks,
        conversationHistory: [],
      );

      expect(msg.sender, ChatSender.assistant);
      expect(msg.proposal, isNotNull);
      expect(msg.proposal?.actionType, ProposedActionType.budgetCut);
      expect(msg.proposal?.newBudget, 16000.0); // 20000 - 20%
      expect(msg.text.contains('16,000') || msg.text.contains('\$16,000'), true);
    });

    test('Guest increase prompt generates guestIncrease proposal with catering delta', () {
      final msg = AiCopilotService.processUserPrompt(
        prompt: 'Can we add 25 guests?',
        event: event,
        budgetItems: budgetItems,
        tasks: tasks,
        conversationHistory: [],
      );

      expect(msg.sender, ChatSender.assistant);
      expect(msg.proposal, isNotNull);
      expect(msg.proposal?.actionType, ProposedActionType.guestIncrease);
      expect(msg.proposal?.newGuestCount, 125); // 100 + 25
      expect(msg.text.contains('125'), true);
      expect(msg.text.contains('Catering'), true);
    });

    test('Eco-friendly prompt suggests zero-waste and sustainable practices', () {
      final msg = AiCopilotService.processUserPrompt(
        prompt: 'How can we make this event more eco-friendly and green?',
        event: event,
        budgetItems: budgetItems,
        tasks: tasks,
        conversationHistory: [],
      );

      expect(msg.sender, ChatSender.assistant);
      expect(msg.proposal?.actionType, ProposedActionType.ecoFriendlyUpgrade);
      expect(msg.text.contains('eco-friendly') || msg.text.contains('sustainable'), true);
      expect(msg.text.contains('Portland'), true); // Incorporates event city
    });

    test('Weather inquiry triggers contingency plan with clear actionable advice', () {
      final msg = AiCopilotService.processUserPrompt(
        prompt: 'What if it rains on the wedding day?',
        event: event,
        budgetItems: budgetItems,
        tasks: tasks,
        conversationHistory: [],
      );

      expect(msg.sender, ChatSender.assistant);
      expect(msg.proposal?.actionType, ProposedActionType.contingencyPlan);
      expect(msg.text.contains('Weather Contingency'), true);
      expect(msg.text.contains('48-Hour Trigger'), true);
    });

    test('Urgent sprint is triggered when event is within 7 days', () {
      final urgentEvent = event.copyWith(
        date: DateTime.now().add(const Duration(days: 4)),
      );

      final msg = AiCopilotService.processUserPrompt(
        prompt: 'What should I do? We only have 4 days left!',
        event: urgentEvent,
        budgetItems: budgetItems,
        tasks: tasks,
        conversationHistory: [],
      );

      expect(msg.sender, ChatSender.assistant);
      expect(msg.proposal?.actionType, ProposedActionType.prioritizeSprint);
      expect(msg.text.contains('4 days'), true);
    });

    test('Next action prompt returns top actionable milestone', () {
      final msg = AiCopilotService.processUserPrompt(
        prompt: 'What is my next action for today?',
        event: event,
        budgetItems: budgetItems,
        tasks: tasks,
        conversationHistory: [],
      );

      expect(msg.sender, ChatSender.assistant);
      expect(msg.text.isNotEmpty, true);
    });

    test('Generic prompt falls back with rich event context and active metrics', () {
      final msg = AiCopilotService.processUserPrompt(
        prompt: 'Tell me about photography styles',
        event: event,
        budgetItems: budgetItems,
        tasks: tasks,
        conversationHistory: [],
      );

      expect(msg.sender, ChatSender.assistant);
      expect(msg.proposal, isNull);
      expect(msg.text.contains('Autumn Botanical Wedding'), true);
      expect(msg.text.contains('\$20,000'), true);
    });
  });
}
