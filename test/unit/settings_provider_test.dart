import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planora_ai/features/events/presentation/providers/event_providers.dart';
import 'package:planora_ai/features/settings/presentation/providers/settings_provider.dart';
import 'package:planora_ai/features/assistant/domain/models/chat_message.dart';

void main() {
  group('SettingsProvider & ChatMessage Tests', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('ThemeModeNotifier defaults to system, persists dark and light modes, and clears', () async {
      final notifier = container.read(themeModeProvider.notifier);
      expect(container.read(themeModeProvider), ThemeMode.system);

      await notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      await notifier.setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);

      await notifier.setThemeMode(ThemeMode.system);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('AiSettingsNotifier toggles AI mode and updates configuration', () {
      final notifier = container.read(aiSettingsProvider.notifier);
      expect(container.read(aiSettingsProvider).isRealAiEnabled, false);

      notifier.updateSettings(
        isRealAiEnabled: true,
        serverEndpoint: 'https://api.planora.ai/v1',
        apiKey: 'test-secret-key',
      );

      final updated = container.read(aiSettingsProvider);
      expect(updated.isRealAiEnabled, true);
      expect(updated.serverEndpoint, 'https://api.planora.ai/v1');
      expect(updated.apiKey, 'test-secret-key');
    });

    test('ChangeProposal and ChatMessage copyWith, equality, and fallback handling', () {
      final proposal1 = ChangeProposal(
        actionType: ProposedActionType.budgetCut,
        description: 'Reallocate 15% from floral to audio',
        newBudget: 18000,
        newGuestCount: 95,
        newDate: DateTime(2026, 9, 15),
      );

      final proposal2 = ChangeProposal(
        actionType: ProposedActionType.budgetCut,
        description: 'Reallocate 15% from floral to audio',
        newBudget: 18000,
        newGuestCount: 95,
        newDate: DateTime(2026, 9, 15),
      );

      expect(proposal1, equals(proposal2));
      expect(proposal1.hashCode, equals(proposal2.hashCode));

      final msg1 = ChatMessage(
        id: 'msg_1',
        sender: ChatSender.assistant,
        text: 'Proposal ready for review',
        timestamp: DateTime(2026, 7, 1, 10, 0),
        proposal: proposal1,
        isApplied: false,
      );

      final msgCopy = msg1.copyWith(isApplied: true);
      expect(msgCopy.isApplied, true);
      expect(msg1 == msgCopy, false);

      final fallbackMsg = ChatMessage.fromJson({});
      expect(fallbackMsg.id, isEmpty);
      expect(fallbackMsg.sender, ChatSender.system);
      expect(fallbackMsg.text, isEmpty);
      expect(fallbackMsg.proposal, isNull);
    });
  });
}
