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

    test('validateBudget rejects non-numeric, negative, and out of bounds', () {
      expect(FormValidators.validateBudget(null), isNotNull);
      expect(FormValidators.validateBudget('free'), isNotNull);
      expect(FormValidators.validateBudget('20'), isNotNull); // < min budget 100
      expect(FormValidators.validateBudget('-500'), isNotNull); // Negative rejected
      expect(FormValidators.validateBudget('-\$1,000'), isNotNull); // Negative with symbol
      expect(FormValidators.validateBudget('NaN'), isNotNull);
      expect(FormValidators.validateBudget('Infinity'), isNotNull);
      expect(FormValidators.validateBudget('100.50.20'), isNotNull); // Multiple decimals
      expect(FormValidators.validateBudget('200000000'), isNotNull); // Exceeds max budget 100M
      expect(FormValidators.validateBudget('50000'), isNull);
      expect(FormValidators.validateBudget('\$25,000'), isNull);
      expect(FormValidators.validateBudget('€10,000.50'), isNull);
    });

    test('validateNumericAmount rejects negatives, invalid formats, and respects minAmount', () {
      expect(FormValidators.validateNumericAmount(null), isNotNull);
      expect(FormValidators.validateNumericAmount(''), isNotNull);
      expect(FormValidators.validateNumericAmount('-25'), isNotNull);
      expect(FormValidators.validateNumericAmount('-\$50.00'), isNotNull);
      expect(FormValidators.validateNumericAmount('invalid'), isNotNull);
      expect(FormValidators.validateNumericAmount('5.00', minAmount: 10), isNotNull);
      expect(FormValidators.validateNumericAmount('25.50'), isNull);
      expect(FormValidators.validateNumericAmount('\$1,250.00'), isNull);
      expect(FormValidators.validateNumericAmount('0', minAmount: 0), isNull);
    });

    test('validateVenueName validates empty, max length, and allowed characters', () {
      expect(FormValidators.validateVenueName(null), isNotNull);
      expect(FormValidators.validateVenueName('   '), isNotNull);
      expect(FormValidators.validateVenueName('A' * 121), isNotNull); // > 120 chars
      expect(FormValidators.validateVenueName('The Grand Ballroom'), isNull);
    });

    test('validateNotes respects max length constraints', () {
      expect(FormValidators.validateNotes(null), isNull); // Optional
      expect(FormValidators.validateNotes(''), isNull);
      expect(FormValidators.validateNotes('A' * 1001), isNotNull); // > 1000 chars
      expect(FormValidators.validateNotes('Some normal notes.'), isNull);
    });

    test('validateEventDate rejects past dates and accepts future dates', () {
      final past = DateTime.now().subtract(const Duration(days: 2));
      final future = DateTime.now().add(const Duration(days: 10));

      expect(FormValidators.validateEventDate(past), isNotNull);
      expect(FormValidators.validateEventDate(future), isNull);
    });
  });
}
