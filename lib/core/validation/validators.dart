import '../constants/app_constants.dart';

class FormValidators {
  static String? validateEventName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Event name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < AppConstants.minEventNameLength) {
      return 'Event name must be at least ${AppConstants.minEventNameLength} characters';
    }
    if (trimmed.length > AppConstants.maxEventNameLength) {
      return 'Event name cannot exceed ${AppConstants.maxEventNameLength} characters';
    }
    return null;
  }

  static String? validateGuestCount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Guest count is required';
    }
    final count = int.tryParse(value.trim());
    if (count == null) {
      return 'Please enter a valid whole number';
    }
    if (count < AppConstants.minGuestCount) {
      return 'Guest count must be at least ${AppConstants.minGuestCount}';
    }
    if (count > AppConstants.maxGuestCount) {
      return 'Guest count cannot exceed ${AppConstants.maxGuestCount}';
    }
    return null;
  }

  static String? validateBudget(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Budget is required';
    }
    final trimmed = value.trim();
    if (trimmed.startsWith('-') || trimmed.contains('-')) {
      return 'Budget cannot be negative';
    }
    final cleaned = trimmed.replaceAll(RegExp(r'[^0-9.]'), '');
    final budget = double.tryParse(cleaned);
    if (budget == null || budget.isNaN || budget.isInfinite) {
      return 'Please enter a valid numeric budget';
    }
    if (budget < AppConstants.minBudget) {
      return 'Budget must be at least ${AppConstants.minBudget}';
    }
    if (budget > AppConstants.maxBudget) {
      return 'Budget exceeds maximum allowable limit';
    }
    return null;
  }

  static String? validateEventDate(DateTime? date) {
    if (date == null) {
      return 'Please select an event date';
    }
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    if (date.isBefore(todayStart)) {
      return 'Event date cannot be in the past';
    }
    return null;
  }

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateNumericAmount(String? value, {bool allowZero = false, double? minAmount}) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final trimmed = value.trim();
    if (trimmed.startsWith('-') || trimmed.contains('-')) {
      return 'Amount cannot be negative';
    }
    final cleaned = trimmed.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(cleaned);
    if (amount == null || amount.isNaN || amount.isInfinite) {
      return 'Please enter a valid number';
    }
    if (minAmount != null && amount < minAmount) {
      return 'Amount must be at least $minAmount';
    }
    final effectiveAllowZero = allowZero || (minAmount != null && minAmount <= 0);
    if (effectiveAllowZero ? amount < 0 : amount <= 0) {
      return 'Amount must be greater than ${effectiveAllowZero ? -1 : 0}';
    }
    return null;
  }

  static String? validateVenueName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Venue name is required';
    }
    if (value.trim().length > 120) {
      return 'Venue name cannot exceed 120 characters';
    }
    return null;
  }

  static String? validateNotes(String? value) {
    if (value != null && value.length > 1000) {
      return 'Notes cannot exceed 1000 characters';
    }
    return null;
  }
}
