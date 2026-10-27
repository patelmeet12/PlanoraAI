import 'package:uuid/uuid.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../budget/domain/models/budget_item.dart';
import '../../../timeline/domain/models/timeline_task.dart';
import '../../../timeline/domain/models/timeline_task.dart' as tt;
import '../../../../core/utils/date_formatter.dart';
import '../models/chat_message.dart';

class AiCopilotService {
  /// Generate a context-aware response using active event data
  static ChatMessage processUserPrompt({
    required String prompt,
    required EventModel event,
    required List<BudgetItem> budgetItems,
    required List<TimelineTask> tasks,
    required List<ChatMessage> conversationHistory,
    bool isRealAi = false,
  }) {
    const uuid = Uuid();
    final lower = prompt.toLowerCase().trim();
    final daysRemaining = DateFormatter.daysRemaining(event.date);

    // 1. Budget reduction request: e.g. "Reduce my budget by 15%", "Cut budget"
    if (lower.contains('reduce') && lower.contains('budget') ||
        lower.contains('cut') && lower.contains('budget') ||
        lower.contains('lower') && lower.contains('budget')) {
      double percent = 0.15;
      final match = RegExp(r'(\d+)%').firstMatch(lower);
      if (match != null) {
        percent = (int.tryParse(match.group(1)!) ?? 15) / 100.0;
      }

      final cutAmount = event.totalBudget * percent;
      final newBudget = (event.totalBudget - cutAmount).clamp(100.0, 100000000.0);

      return ChatMessage(
        id: uuid.v4(),
        sender: ChatSender.assistant,
        text: 'Reducing your budget by ${(percent * 100).round()}% lowers the total from '
            '\$${event.totalBudget.toStringAsFixed(0)} to \$${newBudget.toStringAsFixed(0)} '
            '(savings of \$${cutAmount.toStringAsFixed(0)}).\n\n'
            'I recommend applying this reduction primarily to flexible categories like floral decor, stationery, and favors '
            'while locking in your core venue and catering baseline.',
        timestamp: DateTime.now(),
        proposal: ChangeProposal(
          actionType: ProposedActionType.budgetCut,
          description: 'Reduce total budget by ${(percent * 100).round()}% to \$${newBudget.toStringAsFixed(0)}',
          newBudget: newBudget,
        ),
      );
    }

    // 2. Add / change guests: e.g. "Add 20 guests", "Increase guests"
    if (lower.contains('guest') && (lower.contains('add') || lower.contains('increase') || lower.contains('more'))) {
      int additional = 20;
      final match = RegExp(r'(\d+)').firstMatch(lower);
      if (match != null) {
        additional = int.tryParse(match.group(1)!) ?? 20;
      }
      final newCount = event.guestCount + additional;

      return ChatMessage(
        id: uuid.v4(),
        sender: ChatSender.assistant,
        text: 'Increasing guest headcount from ${event.guestCount} to $newCount (+$additional attendees).\n\n'
            'Key Impacts to note:\n'
            '• Catering & beverage estimates will increase by approximately ~\$${(additional * 45).toStringAsFixed(0)}.\n'
            '• You will need $additional extra place settings, chairs, and favor tokens.\n'
            '• Please verify your venue maximum permitted capacity in ${event.city}.\n\n'
            'Would you like to review and apply this headcount update?',
        timestamp: DateTime.now(),
        proposal: ChangeProposal(
          actionType: ProposedActionType.guestIncrease,
          description: 'Update guest count from ${event.guestCount} to $newCount (+$additional)',
          newGuestCount: newCount,
        ),
      );
    }

    // 3. Make eco-friendly / sustainable
    if (lower.contains('eco') || lower.contains('sustainab') || lower.contains('green')) {
      return ChatMessage(
        id: uuid.v4(),
        sender: ChatSender.assistant,
        text: 'I have formulated an eco-friendly transformation plan for "${event.name}":\n\n'
            '1. Table Decor: Replace cut florals with potted living plants that double as guest favors.\n'
            '2. Digital RSVPs: Eliminate printed paper suites in favor of digital confirmations.\n'
            '3. Zero Food Waste: Coordinate with local food rescue organizations in ${event.city} for safe surplus donation.\n'
            '4. Reusable Dining Ware: Mandate real glassware or compostable palm leaf tableware.\n\n'
            'I can mark relevant sustainable ideas in your Ideas library and add a green checklist task.',
        timestamp: DateTime.now(),
        proposal: ChangeProposal(
          actionType: ProposedActionType.ecoFriendlyUpgrade,
          description: 'Incorporate sustainable practices into task timeline & ideas',
        ),
      );
    }

    // 4. Short runway / 5 days left / what to prioritize
    if (lower.contains('day') && (lower.contains('left') || lower.contains('priorit') || lower.contains('urgent')) ||
        daysRemaining <= 7 && lower.contains('what should')) {
      final urgentTasks = tasks.where((t) => !t.isCompleted).take(3).toList();
      final urgentList = urgentTasks.isNotEmpty
          ? urgentTasks.map((t) => '• ${t.title} (Due: ${DateFormatter.formatShortDate(t.dueDate)})').join('\n')
          : '• Conduct master day-of run sheet walkthrough\n• Confirm final vendor arrival call times\n• Pack emergency coordination kit';

      return ChatMessage(
        id: uuid.v4(),
        sender: ChatSender.assistant,
        text: 'With only $daysRemaining days until "${event.name}", here is your high-impact sprint:\n\n'
            'Top 3 Priorities for immediate execution:\n$urgentList\n\n'
            'Focus rule: Do not take on new custom DIY projects right now. Lock down logistics, confirm supplier contacts, and rehearse the run sheet.',
        timestamp: DateTime.now(),
        proposal: ChangeProposal(
          actionType: ProposedActionType.prioritizeSprint,
          description: 'Focus on top urgent milestones',
        ),
      );
    }

    // 5. Weather / Rainy backup plan
    if (lower.contains('weather') || lower.contains('rain') || lower.contains('storm') || lower.contains('outdoor')) {
      return ChatMessage(
        id: uuid.v4(),
        sender: ChatSender.assistant,
        text: 'Here is your Weather Contingency Action Plan for your ${event.venueType.displayName} setup:\n\n'
            '• 48-Hour Trigger: Monitor local meteorological forecasts 48 hours prior. If rain probability exceeds 40%, activate the backup marquee.\n'
            '• Sound & Electrical: Keep all outdoor power drops elevated on weather-tight risers with GFCI breakers.\n'
            '• Guest Comfort: Order bulk clear umbrellas and prepare non-slip entrance mats at the foyer.\n'
            '• Photo Relocation: Designate an indoor or covered architectural portico for formal portraits.',
        timestamp: DateTime.now(),
        proposal: ChangeProposal(
          actionType: ProposedActionType.contingencyPlan,
          description: 'Establish weather contingency checklist',
        ),
      );
    }

    // 6. What should I do today?
    if (lower.contains('today') || lower.contains('next action') || lower.contains('what to do')) {
      final now = DateTime.now();
      final todayTasks = tasks.where((t) => !t.isCompleted && (t.isOverdue(now) || t.priority == tt.TaskPriority.urgent)).toList();

      String message;
      if (todayTasks.isNotEmpty) {
        final task = todayTasks.first;
        message = 'Your top action for today is:\n\n'
            '👉 **${task.title}**\n'
            '${task.description}\n'
            'Category: ${task.category} | Priority: ${task.priority.displayName}\n\n'
            'Completing this unblocks the rest of your planning milestones!';
      } else {
        message = 'You are in great shape today! All urgent milestones are up to date.\n\n'
            'Recommended next steps:\n'
            '• Review your vendor quotes in the Vendor Organizer\n'
            '• Browse the Ideas Generator for unique touches\n'
            '• Check your Event-Day Run Sheet timeline';
      }

      return ChatMessage(
        id: uuid.v4(),
        sender: ChatSender.assistant,
        text: message,
        timestamp: DateTime.now(),
      );
    }

    // 7. Generic query fallback responding intelligently with event context
    return ChatMessage(
      id: uuid.v4(),
      sender: ChatSender.assistant,
      text: 'I am analyzing "${event.name}" (${event.category.displayName} on ${DateFormatter.formatMediumDate(event.date)} with ${event.guestCount} guests).\n\n'
          'Regarding "$prompt":\n'
          'Your active budget is \$${event.totalBudget.toStringAsFixed(0)} ${event.currency} across ${budgetItems.length} categories. '
          'You currently have ${tasks.where((t) => t.isCompleted).length} of ${tasks.length} tasks completed.\n\n'
          'You can ask me to adjust your budget, simulate guest count shifts, review vendor comparisons, or optimize your timeline anytime!',
      timestamp: DateTime.now(),
    );
  }
}
