import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../events/presentation/providers/event_providers.dart';

class AiSettings {
  final bool isRealAiEnabled;
  final String serverEndpoint;
  final String apiKey;

  const AiSettings({
    this.isRealAiEnabled = false,
    this.serverEndpoint = '',
    this.apiKey = '',
  });

  AiSettings copyWith({
    bool? isRealAiEnabled,
    String? serverEndpoint,
    String? apiKey,
  }) {
    return AiSettings(
      isRealAiEnabled: isRealAiEnabled ?? this.isRealAiEnabled,
      serverEndpoint: serverEndpoint ?? this.serverEndpoint,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(AppConstants.storageKeyThemeMode);
    if (saved == 'dark') return ThemeMode.dark;
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    if (mode == ThemeMode.dark) {
      await prefs.setString(AppConstants.storageKeyThemeMode, 'dark');
    } else if (mode == ThemeMode.light) {
      await prefs.setString(AppConstants.storageKeyThemeMode, 'light');
    } else {
      await prefs.remove(AppConstants.storageKeyThemeMode);
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class AiSettingsNotifier extends Notifier<AiSettings> {
  @override
  AiSettings build() {
    return const AiSettings(isRealAiEnabled: false);
  }

  void updateSettings({
    required bool isRealAiEnabled,
    String? serverEndpoint,
    String? apiKey,
  }) {
    state = state.copyWith(
      isRealAiEnabled: isRealAiEnabled,
      serverEndpoint: serverEndpoint,
      apiKey: apiKey,
    );
  }
}

final aiSettingsProvider = NotifierProvider<AiSettingsNotifier, AiSettings>(
  AiSettingsNotifier.new,
);
