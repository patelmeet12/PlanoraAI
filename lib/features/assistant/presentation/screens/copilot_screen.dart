import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/services/ai_copilot_service.dart';

class CopilotScreen extends ConsumerStatefulWidget {
  const CopilotScreen({super.key});

  @override
  ConsumerState<CopilotScreen> createState() => _CopilotScreenState();
}

class _CopilotScreenState extends ConsumerState<CopilotScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isProcessing = false;

  final List<String> _quickPrompts = [
    'Reduce my budget by 15%',
    'Add 20 guests',
    'Make this event more eco-friendly',
    'I have only 5 days left. What should I prioritize?',
    'Create a rainy-weather backup plan',
    'What should I do today?',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isProcessing) return;

    final active = ref.read(activeEventProvider).value;
    if (active == null) return;

    const uuid = Uuid();
    final userMsg = ChatMessage(
      id: uuid.v4(),
      sender: ChatSender.user,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    _inputController.clear();
    await ref.read(activeEventProvider.notifier).addChatMessage(userMsg);

    setState(() => _isProcessing = true);
    _scrollToBottom();

    // Process with AiCopilotService
    final aiSettings = ref.read(aiSettingsProvider);
    final responseMsg = AiCopilotService.processUserPrompt(
      prompt: text.trim(),
      event: active.event,
      budgetItems: active.budgetItems,
      tasks: active.tasks,
      conversationHistory: active.chatMessages,
      isRealAi: aiSettings.isRealAiEnabled,
    );

    await Future.delayed(const Duration(milliseconds: 300));
    await ref.read(activeEventProvider.notifier).addChatMessage(responseMsg);

    if (mounted) {
      setState(() => _isProcessing = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _applyProposal(ChatMessage message) async {
    final proposal = message.proposal;
    if (proposal == null) return;

    final active = ref.read(activeEventProvider).value;
    if (active == null) return;

    final confirm = await ConfirmDialog.show(
      context,
      title: 'Apply Assistant Recommendation?',
      content: proposal.description,
      confirmLabel: 'Apply Change',
    );

    if (confirm == true) {
      if (proposal.actionType == ProposedActionType.budgetCut && proposal.newBudget != null) {
        final updated = active.event.copyWith(totalBudget: proposal.newBudget!);
        await ref.read(activeEventProvider.notifier).updateEventProfile(updated);
      } else if (proposal.actionType == ProposedActionType.guestIncrease && proposal.newGuestCount != null) {
        final updated = active.event.copyWith(guestCount: proposal.newGuestCount!);
        await ref.read(activeEventProvider.notifier).updateEventProfile(updated);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('✓ Applied proposal changes to your active event!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeEventAsync = ref.watch(activeEventProvider);
    final aiSettings = ref.watch(aiSettingsProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return activeEventAsync.when(
      data: (aggregate) {
        if (aggregate == null) {
          return const EmptyStateView(
            icon: Icons.smart_toy_outlined,
            title: 'No Event Active',
            message: 'Create an event to start pair-planning with the AI Copilot.',
          );
        }

        final messages = aggregate.chatMessages;

        return Column(
          children: [
            // Top Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.smart_toy, size: 18, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Planora Copilot — ${aggregate.event.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          aiSettings.isRealAiEnabled
                              ? 'Connected to server-side AI proxy'
                              : 'Running deterministic heuristic planning engine',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: aiSettings.isRealAiEnabled ? 'AI-Powered' : 'Smart Demo Mode',
                    type: aiSettings.isRealAiEnabled ? BadgeType.success : BadgeType.info,
                    compact: true,
                  ),
                ],
              ),
            ),

            // Chat Messages Scroll Area
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyChatPlaceholder(context, aggregate.event.name)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: width > 800 ? 48 : 16,
                        vertical: 20,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = messages[i];
                        return _buildMessageBubble(context, msg);
                      },
                    ),
            ),

            // Quick Prompt Pills
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final prompt = _quickPrompts[i];
                  return ActionChip(
                    label: Text(prompt, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _sendMessage(prompt),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Chat Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.colorScheme.outline)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: InputDecoration(
                          hintText: 'Ask Copilot to change budget, scale guests, or suggest today\'s actions...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: () => _sendMessage(_inputController.text),
                      icon: const Icon(Icons.send, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading copilot: $e')),
    );
  }

  Widget _buildEmptyChatPlaceholder(BuildContext context, String eventName) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(80),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, size: 36, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text('Planning Assistant Ready', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                'I have indexed your active event profile for "$eventName". Ask questions naturally or tap any of the suggestion pills below.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg) {
    final isUser = msg.sender == ChatSender.user;
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width > 700 ? 560 : 320,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          border: isUser ? null : Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isUser ? Colors.white : theme.colorScheme.onSurface,
                height: 1.45,
                fontSize: 14,
              ),
            ),

            // Propose change action CTA
            if (msg.proposal != null && !isUser) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.primary.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        msg.proposal!.description,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _applyProposal(msg),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 30),
                      ),
                      child: const Text('Review & Apply', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
