import 'package:flutter_test/flutter_test.dart';
import 'package:planora_ai/core/utils/currency_formatter.dart';
import 'package:planora_ai/core/utils/date_formatter.dart';

void main() {
  group('Formatters Unit Tests', () {
    test('CurrencyFormatter formats amounts across currencies and compact scales', () {
      expect(CurrencyFormatter.format(500, currency: 'USD'), '\$500');
      expect(CurrencyFormatter.format(1500, currency: 'EUR'), '€1,500');
      expect(CurrencyFormatter.format(25000, currency: 'GBP'), '£25,000');
      expect(CurrencyFormatter.format(50000, currency: 'INR'), '₹50,000');

      // Compact scale >= 1000 and >= 1000000
      expect(CurrencyFormatter.format(2500, currency: 'USD', compact: true), '\$2.5k');
      expect(CurrencyFormatter.format(1200000, currency: 'USD', compact: true), '\$1.2M');
    });

    test('CurrencyFormatter formatWithDecimals preserves cents and commas', () {
      expect(CurrencyFormatter.formatWithDecimals(1250.75, currency: 'USD'), '\$1,250.75');
      expect(CurrencyFormatter.formatWithDecimals(99.00, currency: 'EUR'), '€99.00');
    });

    test('DateFormatter formats standard date representations', () {
      final date = DateTime(2026, 6, 15, 14, 30);

      expect(DateFormatter.formatFullDate(date), contains('June 15, 2026'));
      expect(DateFormatter.formatMediumDate(date), 'Jun 15, 2026');
      expect(DateFormatter.formatShortDate(date), 'Jun 15');
      expect(DateFormatter.formatTime(date), '02:30 PM');
    });

    test('DateFormatter formatRelativeDays computes Today, Tomorrow, Yesterday, and Overdue', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      expect(DateFormatter.formatRelativeDays(today), 'Today');
      expect(DateFormatter.formatRelativeDays(today.add(const Duration(days: 1))), 'Tomorrow');
      expect(DateFormatter.formatRelativeDays(today.subtract(const Duration(days: 1))), 'Yesterday');
      expect(DateFormatter.formatRelativeDays(today.add(const Duration(days: 5))), 'In 5 days');
      expect(DateFormatter.formatRelativeDays(today.subtract(const Duration(days: 3))), '3 days overdue');

      expect(DateFormatter.daysRemaining(today.add(const Duration(days: 10))), 10);
      expect(DateFormatter.daysRemaining(today.subtract(const Duration(days: 4))), -4);
    });
  });
}
