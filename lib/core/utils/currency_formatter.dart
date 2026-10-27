import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static String format(double amount, {String currency = 'USD', bool compact = false}) {
    final symbol = AppConstants.currencySymbols[currency] ?? currency;

    if (compact && amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (compact && amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
    }

    final formatter = NumberFormat('#,##0', 'en_US');
    return '$symbol${formatter.format(amount.round())}';
  }

  static String formatWithDecimals(double amount, {String currency = 'USD'}) {
    final symbol = AppConstants.currencySymbols[currency] ?? currency;
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$symbol${formatter.format(amount)}';
  }
}
