import 'package:uuid/uuid.dart';
import '../models/budget_item.dart';
import '../models/budget_category.dart';
import '../models/budget_adjustment.dart';

class BudgetSummary {
  final double totalBudget;
  final double estimatedExpenses;
  final double confirmedExpenses;
  final double totalPlannedExpenses;
  final double remainingBalance;
  final double costPerGuest;
  final double utilizationPercentage;
  final BudgetThresholdState thresholdState;
  final Map<BudgetCategory, double> categoryBreakdown;
  final Map<BudgetCategory, double> categoryPercentages;

  const BudgetSummary({
    required this.totalBudget,
    required this.estimatedExpenses,
    required this.confirmedExpenses,
    required this.totalPlannedExpenses,
    required this.remainingBalance,
    required this.costPerGuest,
    required this.utilizationPercentage,
    required this.thresholdState,
    required this.categoryBreakdown,
    required this.categoryPercentages,
  });
}

class BudgetOptimizerService {
  static const double approachingThreshold = 85.0; // 85% utilization
  static const double overBudgetThreshold = 100.0; // 100% utilization

  /// Calculate comprehensive budget health and allocations
  static BudgetSummary calculateSummary({
    required double totalBudget,
    required int guestCount,
    required List<BudgetItem> items,
  }) {
    double confirmedTotal = 0.0;
    double estimatedTotal = 0.0;
    final Map<BudgetCategory, double> breakdown = {};

    for (final category in BudgetCategory.values) {
      breakdown[category] = 0.0;
    }

    for (final item in items) {
      if (item.isConfirmed) {
        confirmedTotal += item.confirmedAmount;
      } else {
        estimatedTotal += item.estimatedAmount;
      }
      final effective = item.effectiveAmount;
      breakdown[item.category] = (breakdown[item.category] ?? 0.0) + effective;
    }

    final double totalPlanned = confirmedTotal + estimatedTotal;
    final double remaining = totalBudget - totalPlanned;
    final double perGuest = guestCount > 0 ? (totalPlanned / guestCount) : 0.0;
    final double utilization = totalBudget > 0 ? (totalPlanned / totalBudget) * 100.0 : 0.0;

    BudgetThresholdState state;
    if (utilization > overBudgetThreshold) {
      state = BudgetThresholdState.overBudget;
    } else if (utilization >= approachingThreshold) {
      state = BudgetThresholdState.approachingLimit;
    } else {
      state = BudgetThresholdState.withinBudget;
    }

    final Map<BudgetCategory, double> percentages = {};
    for (final entry in breakdown.entries) {
      percentages[entry.key] = totalPlanned > 0 ? (entry.value / totalPlanned) * 100.0 : 0.0;
    }

    return BudgetSummary(
      totalBudget: totalBudget,
      estimatedExpenses: estimatedTotal,
      confirmedExpenses: confirmedTotal,
      totalPlannedExpenses: totalPlanned,
      remainingBalance: remaining,
      costPerGuest: perGuest,
      utilizationPercentage: utilization,
      thresholdState: state,
      categoryBreakdown: breakdown,
      categoryPercentages: percentages,
    );
  }

  /// Generate intelligent adjustments when approaching or exceeding budget.
  /// Confirmed items are LOCKED and never proposed for reduction.
  static List<BudgetAdjustmentProposal> generateAdjustments({
    required double totalBudget,
    required List<BudgetItem> items,
    required double overageAmount,
  }) {
    if (overageAmount <= 0) return [];

    final List<BudgetAdjustmentProposal> proposals = [];
    const uuid = Uuid();

    // Prioritize cuts in flexible categories (gifts, decoration, clothing) before essentials
    // Priority 3 = Flexible, Priority 2 = Medium, Priority 1 = Essential
    final unconfirmedItems = items
        .where((item) => !item.isConfirmed && item.estimatedAmount > 50)
        .toList();

    // Sort: highest priority number first (most flexible), then largest cost
    unconfirmedItems.sort((a, b) {
      final pComp = b.priority.compareTo(a.priority);
      if (pComp != 0) return pComp;
      return b.estimatedAmount.compareTo(a.estimatedAmount);
    });

    double remainingToSave = overageAmount;

    for (final item in unconfirmedItems) {
      if (remainingToSave <= 0) break;

      double reductionRate;
      String rationale;

      if (item.category == BudgetCategory.giftsFavors) {
        reductionRate = 0.40; // 40% cut on favors
        rationale = 'Guest favors can be scaled down to thoughtful digital keepsakes or bulk handcrafted tokens.';
      } else if (item.category == BudgetCategory.decoration) {
        reductionRate = 0.25; // 25% cut on decor
        rationale = 'Focus floral arrangements on the focal stage/altar and use ambient candlelight or greenery for secondary areas.';
      } else if (item.category == BudgetCategory.invitations) {
        reductionRate = 0.35;
        rationale = 'Switch paper invitations and reply cards to an elegant digital RSVP portal.';
      } else if (item.category == BudgetCategory.entertainment) {
        reductionRate = 0.20;
        rationale = 'Opt for a curated acoustic set or DJ package with custom playlist instead of a full multi-piece band.';
      } else if (item.category == BudgetCategory.catering) {
        reductionRate = 0.15;
        rationale = 'Select a stylized buffet or family-style dinner over plated multi-course banquet service.';
      } else {
        reductionRate = 0.15;
        rationale = 'Negotiate package deliverables or select standard tier inclusions for this category.';
      }

      final double savings = (item.estimatedAmount * reductionRate).clamp(0, remainingToSave);
      if (savings > 20) {
        final double proposed = item.estimatedAmount - savings;
        proposals.add(BudgetAdjustmentProposal(
          id: uuid.v4(),
          budgetItemId: item.id,
          category: item.category,
          title: 'Optimize ${item.name}',
          description: 'Reduce estimate from \$${item.estimatedAmount.toStringAsFixed(0)} to \$${proposed.toStringAsFixed(0)} (save \$${savings.toStringAsFixed(0)})',
          currentAmount: item.estimatedAmount,
          proposedAmount: proposed,
          rationale: rationale,
        ));
        remainingToSave -= savings;
      }
    }

    return proposals;
  }
}
