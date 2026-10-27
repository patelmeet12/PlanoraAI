import 'package:flutter_test/flutter_test.dart';
import 'package:planora_ai/features/budget/domain/models/budget_category.dart';
import 'package:planora_ai/features/budget/domain/models/budget_item.dart';
import 'package:planora_ai/features/budget/domain/services/budget_optimizer_service.dart';

void main() {
  group('BudgetOptimizerService Tests', () {
    test('Calculates budget totals, remaining balance, and cost per guest accurately', () {
      final items = [
        const BudgetItem(
          id: '1',
          eventId: 'e1',
          category: BudgetCategory.venue,
          name: 'Venue Rental',
          estimatedAmount: 5000,
          confirmedAmount: 5000,
          isConfirmed: true,
        ),
        const BudgetItem(
          id: '2',
          eventId: 'e1',
          category: BudgetCategory.catering,
          name: 'Catering Service',
          estimatedAmount: 3000,
          isConfirmed: false,
        ),
      ];

      final summary = BudgetOptimizerService.calculateSummary(
        totalBudget: 10000,
        guestCount: 50,
        items: items,
      );

      expect(summary.totalBudget, 10000.0);
      expect(summary.confirmedExpenses, 5000.0);
      expect(summary.estimatedExpenses, 3000.0);
      expect(summary.totalPlannedExpenses, 8000.0);
      expect(summary.remainingBalance, 2000.0);
      expect(summary.costPerGuest, 160.0); // 8000 / 50
      expect(summary.utilizationPercentage, 80.0); // 8000 / 10000 * 100
      expect(summary.thresholdState, BudgetThresholdState.withinBudget);
    });

    test('Correctly classifies Approaching Limit state when between 85% and 100%', () {
      final items = [
        const BudgetItem(
          id: '1',
          eventId: 'e1',
          category: BudgetCategory.venue,
          name: 'Venue',
          estimatedAmount: 9000,
          isConfirmed: false,
        ),
      ];

      final summary = BudgetOptimizerService.calculateSummary(
        totalBudget: 10000,
        guestCount: 50,
        items: items,
      );

      expect(summary.utilizationPercentage, 90.0);
      expect(summary.thresholdState, BudgetThresholdState.approachingLimit);
    });

    test('Correctly classifies Over Budget state when utilization > 100%', () {
      final items = [
        const BudgetItem(
          id: '1',
          eventId: 'e1',
          category: BudgetCategory.venue,
          name: 'Venue',
          estimatedAmount: 11500,
          isConfirmed: false,
        ),
      ];

      final summary = BudgetOptimizerService.calculateSummary(
        totalBudget: 10000,
        guestCount: 50,
        items: items,
      );

      expect(summary.remainingBalance, -1500.0);
      expect(summary.thresholdState, BudgetThresholdState.overBudget);
    });

    test('Optimization recommendations NEVER cut confirmed expenses', () {
      final items = [
        const BudgetItem(
          id: 'item_confirmed',
          eventId: 'e1',
          category: BudgetCategory.decoration,
          name: 'Signed Floral Package',
          estimatedAmount: 2000,
          confirmedAmount: 2000,
          isConfirmed: true,
          priority: 3,
        ),
        const BudgetItem(
          id: 'item_unconfirmed',
          eventId: 'e1',
          category: BudgetCategory.giftsFavors,
          name: 'Custom Gift Bags',
          estimatedAmount: 1500,
          isConfirmed: false,
          priority: 3,
        ),
      ];

      final proposals = BudgetOptimizerService.generateAdjustments(
        totalBudget: 2500,
        items: items,
        overageAmount: 1000,
      );

      expect(proposals.isNotEmpty, true);
      // Ensure only unconfirmed item was targeted
      for (final p in proposals) {
        expect(p.budgetItemId, isNot('item_confirmed'));
        expect(p.budgetItemId, 'item_unconfirmed');
      }
    });

    test('Zero budget and zero guests safely compute without NaN or Infinity', () {
      final summary = BudgetOptimizerService.calculateSummary(
        totalBudget: 0,
        guestCount: 0,
        items: [
          const BudgetItem(
            id: 'item_1',
            eventId: 'e1',
            category: BudgetCategory.venue,
            name: 'Hall',
            estimatedAmount: 500,
            isConfirmed: false,
          ),
        ],
      );

      expect(summary.costPerGuest, 0.0);
      expect(summary.costPerGuest.isNaN, false);
      expect(summary.costPerGuest.isInfinite, false);
      expect(summary.utilizationPercentage, 0.0);
      expect(summary.remainingBalance, -500.0);
      expect(summary.thresholdState, BudgetThresholdState.overBudget);
    });

    test('generateAdjustments formats descriptions using dynamic currency', () {
      final items = [
        const BudgetItem(
          id: 'item_unconfirmed',
          eventId: 'e1',
          category: BudgetCategory.giftsFavors,
          name: 'Party Favors',
          estimatedAmount: 2000,
          isConfirmed: false,
          priority: 3,
        ),
      ];

      final proposalsEur = BudgetOptimizerService.generateAdjustments(
        totalBudget: 1500,
        items: items,
        overageAmount: 500,
        currency: 'EUR',
      );

      expect(proposalsEur.isNotEmpty, true);
      expect(proposalsEur.first.description.contains('€') || proposalsEur.first.description.contains('EUR'), true);
    });
  });
}
