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
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final budget = double.tryParse(cleaned);
    if (budget == null) {
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

  static String? validateNumericAmount(String? value, {bool allowZero = false}) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (amount == null) {
      return 'Please enter a valid number';
    }
    if (allowZero ? amount < 0 : amount <= 0) {
      return 'Amount must be greater than ${allowZero ? -1 : 0}';
    }
    return null;
  }
}
