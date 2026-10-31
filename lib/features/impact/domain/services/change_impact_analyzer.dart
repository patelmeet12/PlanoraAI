import '../../../events/domain/models/event_model.dart';
import '../../../budget/domain/models/budget_item.dart';
import '../../../budget/domain/models/budget_category.dart';
import '../../../budget/domain/services/budget_optimizer_service.dart';
import '../../../timeline/domain/models/timeline_task.dart';
import '../../../vendors/domain/models/vendor_model.dart';
import '../../../vendors/domain/models/vendor_category.dart';
import '../../../../core/utils/currency_formatter.dart';

class ChangeImpactResult {
  final EventModel originalEvent;
  final EventModel proposedEvent;
  final int guestCountDelta;
  final double budgetDelta;
  final int daysShiftDelta;

  final double originalCostPerGuest;
  final double proposedCostPerGuest;
  final double estimatedCateringImpact;
  final double confirmedDeficit;
  final BudgetThresholdState originalBudgetState;
  final BudgetThresholdState proposedBudgetState;

  final List<String> affectedCategories;
  final List<String> affectedVendors;
  final List<String> impactedTasks;
  final List<String> warnings;
  final List<String> recommendations;

  const ChangeImpactResult({
    required this.originalEvent,
    required this.proposedEvent,
    required this.guestCountDelta,
    required this.budgetDelta,
    required this.daysShiftDelta,
    required this.originalCostPerGuest,
    required this.proposedCostPerGuest,
    required this.estimatedCateringImpact,
    this.confirmedDeficit = 0.0,
    required this.originalBudgetState,
    required this.proposedBudgetState,
    required this.affectedCategories,
    required this.affectedVendors,
    required this.impactedTasks,
    required this.warnings,
    required this.recommendations,
  });

  bool get hasHighImpact =>
      guestCountDelta.abs() >= 15 ||
      budgetDelta.abs() >= 500 ||
      daysShiftDelta.abs() >= 7 ||
      confirmedDeficit > 0 ||
      warnings.isNotEmpty;
}

class ChangeImpactAnalyzer {
  /// Evaluates full before-and-after delta impact across budget, tasks, and vendors
  static ChangeImpactResult analyze({
    required EventModel originalEvent,
    required EventModel proposedEvent,
    required List<BudgetItem> currentBudgetItems,
    required List<TimelineTask> currentTasks,
    required List<VendorModel> currentVendors,
  }) {
    final int guestDelta = proposedEvent.guestCount - originalEvent.guestCount;
    final double budgetDelta = proposedEvent.totalBudget - originalEvent.totalBudget;
    final int daysShiftDelta = proposedEvent.date.difference(originalEvent.date).inDays;

    final origSummary = BudgetOptimizerService.calculateSummary(
      totalBudget: originalEvent.totalBudget,
      guestCount: originalEvent.guestCount,
      items: currentBudgetItems,
    );

    // Calculate estimated catering impact per guest:
    // Find current catering item or compute typical per-guest cost
    final cateringItem = currentBudgetItems.cast<BudgetItem?>().firstWhere(
          (i) => i?.category == BudgetCategory.catering,
          orElse: () => null,
        );

    final double perGuestCateringRate = cateringItem != null && originalEvent.guestCount > 0
        ? (cateringItem.effectiveAmount / originalEvent.guestCount)
        : 45.0; // Benchmark $45/head

    final double cateringDeltaCost = guestDelta * perGuestCateringRate;

    // Simulated new budget summary assuming unconfirmed catering adjusts
    final simulatedItems = currentBudgetItems.map((item) {
      if (item.category == BudgetCategory.catering && !item.isConfirmed) {
        return item.copyWith(
          estimatedAmount: (item.estimatedAmount + cateringDeltaCost).clamp(0.0, double.infinity),
        );
      }
      return item;
    }).toList();

    final proposedSummary = BudgetOptimizerService.calculateSummary(
      totalBudget: proposedEvent.totalBudget,
      guestCount: proposedEvent.guestCount,
      items: simulatedItems,
    );

    final List<String> affectedCategories = [];
    final List<String> affectedVendors = [];
    final List<String> impactedTasks = [];
    final List<String> warnings = [];
    final List<String> recommendations = [];
    final cur = proposedEvent.currency;

    // Event Category / Type Changes
    if (originalEvent.category != proposedEvent.category) {
      warnings.add(
        'Event type changed from ${originalEvent.category.displayName} to ${proposedEvent.category.displayName}. Core themes, milestones, and vendor expectations will shift.',
      );
      recommendations.add(
        'Conduct a theme and milestone realignment review to adapt tasks and decor to the new ${proposedEvent.category.displayName} format.',
      );
      affectedCategories.add('Theme & Milestone Strategy');
    }

    // Guest Count Changes
    if (guestDelta != 0) {
      affectedCategories.add('Catering & Dining');
      affectedCategories.add('Invitations & Stationery');
      affectedCategories.add('Favors & Gifts');

      final cateringFmt = CurrencyFormatter.format(cateringDeltaCost.abs(), currency: cur);

      if (guestDelta > 0) {
        warnings.add(
          'Guest count increased by +$guestDelta. Estimated catering cost will increase by ~$cateringFmt.',
        );
        recommendations.add(
          'Verify that your selected venue has adequate fire-safety capacity for ${proposedEvent.guestCount} attendees.',
        );
        recommendations.add(
          'Order additional place settings, seating rentals, and update invitation print order.',
        );
      } else {
        recommendations.add(
          'Guest count decreased by ${guestDelta.abs()}. You can save approximately ~$cateringFmt on catering.',
        );
      }

      // Find catering and venue vendors
      for (final v in currentVendors) {
        if (v.category == VendorCategory.caterer || v.category == VendorCategory.venue) {
          affectedVendors.add('${v.name} (${v.category.displayName})');
        }
      }

      for (final t in currentTasks) {
        if (t.category.toLowerCase().contains('cater') ||
            t.category.toLowerCase().contains('invit') ||
            t.title.toLowerCase().contains('guest')) {
          impactedTasks.add(t.title);
        }
      }
    }

    // Budget Changes
    if (budgetDelta != 0) {
      final deltaFmt = CurrencyFormatter.format(budgetDelta.abs(), currency: cur);
      if (budgetDelta < 0) {
        warnings.add(
          'Total budget reduced by $deltaFmt. Current planned expenses may exceed new ceiling.',
        );
        recommendations.add(
          'Review the Intelligent Budget Optimizer to accept automated cuts in flexible categories.',
        );
      } else {
        recommendations.add(
          'Total budget increased by +$deltaFmt. You can increase contingency reserve or upgrade creative vendors.',
        );
      }
    }

    // Confirmed Contracts Deficit Check
    final double confirmedTotal = currentBudgetItems
        .where((i) => i.isConfirmed)
        .fold(0.0, (sum, i) => sum + i.confirmedAmount);

    double confirmedDeficit = 0.0;
    if (proposedEvent.totalBudget < confirmedTotal) {
      confirmedDeficit = confirmedTotal - proposedEvent.totalBudget;
      final deficitFmt = CurrencyFormatter.format(confirmedDeficit, currency: cur);
      final confirmedFmt = CurrencyFormatter.format(confirmedTotal, currency: cur);
      final budgetFmt = CurrencyFormatter.format(proposedEvent.totalBudget, currency: cur);
      warnings.add(
        'Critical: Proposed budget ($budgetFmt) is less than already confirmed vendor contracts ($confirmedFmt) by $deficitFmt.',
      );
      recommendations.add(
        'Renegotiate or release existing confirmed vendor agreements before lowering the budget ceiling.',
      );
    }

    // Date Shift Changes
    if (daysShiftDelta != 0) {
      if (daysShiftDelta < 0) {
        warnings.add(
          'Event moved earlier by ${daysShiftDelta.abs()} days! Task deadlines will tighten significantly.',
        );
        recommendations.add(
          'Check vendor availability immediately for the new earlier date.',
        );
      } else {
        recommendations.add(
          'Event postponed by $daysShiftDelta days. This provides more runway for planning and supplier negotiations.',
        );
      }

      for (final v in currentVendors) {
        affectedVendors.add('${v.name} (Requires date re-confirmation)');
      }
      impactedTasks.add('All upcoming milestone due dates will be shifted by $daysShiftDelta days');
    }

    // Budget threshold warning
    if (proposedSummary.thresholdState == BudgetThresholdState.overBudget) {
      final overageFmt = CurrencyFormatter.format(
        proposedSummary.totalPlannedExpenses - proposedEvent.totalBudget,
        currency: cur,
      );
      warnings.add(
        'Warning: Proposed adjustments will put this event OVER BUDGET by $overageFmt.',
      );
    }

    return ChangeImpactResult(
      originalEvent: originalEvent,
      proposedEvent: proposedEvent,
      guestCountDelta: guestDelta,
      budgetDelta: budgetDelta,
      daysShiftDelta: daysShiftDelta,
      originalCostPerGuest: origSummary.costPerGuest,
      proposedCostPerGuest: proposedSummary.costPerGuest,
      estimatedCateringImpact: cateringDeltaCost,
      confirmedDeficit: confirmedDeficit,
      originalBudgetState: origSummary.thresholdState,
      proposedBudgetState: proposedSummary.thresholdState,
      affectedCategories: affectedCategories,
      affectedVendors: affectedVendors.toSet().toList(),
      impactedTasks: impactedTasks.toSet().toList(),
      warnings: warnings,
      recommendations: recommendations,
    );
  }
}
