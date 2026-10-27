class AppConstants {
  static const String appName = 'Planora AI';
  static const String appTagline = 'Intelligent Event Planning Copilot';
  static const String appVersion = '1.0.0';

  // Persistence keys
  static const String storageKeyEvents = 'planora_events_v1';
  static const String storageKeyActiveEventId = 'planora_active_event_id_v1';
  static const String storageKeyThemeMode = 'planora_theme_mode_v1';
  static const String storageKeyAiSettings = 'planora_ai_settings_v1';

  // Validation limits
  static const int minGuestCount = 1;
  static const int maxGuestCount = 50000;
  static const double minBudget = 100.0;
  static const double maxBudget = 100000000.0;
  static const int minEventNameLength = 3;
  static const int maxEventNameLength = 100;
  static const int maxNotesLength = 2000;

  // Supported currencies
  static const List<String> supportedCurrencies = [
    'USD',
    'INR',
    'EUR',
    'GBP',
    'CAD',
    'AUD',
  ];

  static const Map<String, String> currencySymbols = {
    'USD': r'$',
    'INR': '₹',
    'EUR': '€',
    'GBP': '£',
    'CAD': r'CA$',
    'AUD': r'A$',
  };
}
