import 'package:flutter_test/flutter_test.dart';
import 'package:planora_ai/core/validation/validators.dart';

void main() {
  group('FormValidators Tests', () {
    test('validateEventName rejects empty and out-of-bound strings', () {
      expect(FormValidators.validateEventName(null), isNotNull);
      expect(FormValidators.validateEventName('  '), isNotNull);
      expect(FormValidators.validateEventName('Ab'), isNotNull); // < 3 chars
      expect(FormValidators.validateEventName('Valid Event Name'), isNull);
    });

    test('validateGuestCount rejects non-numbers and values out of bounds', () {
      expect(FormValidators.validateGuestCount(null), isNotNull);
      expect(FormValidators.validateGuestCount('abc'), isNotNull);
      expect(FormValidators.validateGuestCount('0'), isNotNull);
      expect(FormValidators.validateGuestCount('-5'), isNotNull);
      expect(FormValidators.validateGuestCount('1000000'), isNotNull);
      expect(FormValidators.validateGuestCount('120'), isNull);
    });

    test('validateBudget rejects non-numeric and out of bounds', () {
      expect(FormValidators.validateBudget(null), isNotNull);
      expect(FormValidators.validateBudget('free'), isNotNull);
      expect(FormValidators.validateBudget('20'), isNotNull); // < min budget 100
      expect(FormValidators.validateBudget('50000'), isNull);
      expect(FormValidators.validateBudget('\$25,000'), isNull);
    });

    test('validateEventDate rejects past dates', () {
      final past = DateTime.now().subtract(const Duration(days: 2));
      final future = DateTime.now().add(const Duration(days: 10));

      expect(FormValidators.validateEventDate(past), isNotNull);
      expect(FormValidators.validateEventDate(future), isNull);
    });
  });
}
