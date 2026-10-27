import 'package:flutter_test/flutter_test.dart';
import 'package:planora_ai/features/events/domain/models/event_category.dart';
import 'package:planora_ai/features/events/domain/models/event_model.dart';
import 'package:planora_ai/features/budget/domain/models/budget_category.dart';
import 'package:planora_ai/features/budget/domain/models/budget_item.dart';
import 'package:planora_ai/features/timeline/domain/models/timeline_task.dart';
import 'package:planora_ai/features/vendors/domain/models/vendor_category.dart';
import 'package:planora_ai/features/vendors/domain/models/vendor_model.dart';
import 'package:planora_ai/features/impact/domain/services/change_impact_analyzer.dart';

void main() {
  group('ChangeImpactAnalyzer Tests', () {
    final origEvent = EventModel(
      id: 'e1',
      name: 'Summer Gala',
      category: EventCategory.wedding,
      date: DateTime(2026, 8, 1),
      city: 'Chicago',
      guestCount: 100,
      totalBudget: 20000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final budgetItems = [
      const BudgetItem(
        id: 'b_cat',
        eventId: 'e1',
        category: BudgetCategory.catering,
        name: 'Plated Dinner',
        estimatedAmount: 5000, // $50/guest
        isConfirmed: false,
      ),
      const BudgetItem(
        id: 'b_venue',
        eventId: 'e1',
        category: BudgetCategory.venue,
        name: 'Ballroom',
        estimatedAmount: 8000,
        confirmedAmount: 8000,
        isConfirmed: true,
      ),
    ];

    final vendors = [
      const VendorModel(
        id: 'v_caterer',
        eventId: 'e1',
        name: 'Elite Catering',
        category: VendorCategory.caterer,
      ),
    ];

    final tasks = [
      TimelineTask(
        id: 't_inv',
        eventId: 'e1',
        title: 'Send Guest Invitations',
        description: '',
        dueDate: DateTime(2026, 7, 1),
        category: 'Invitations',
      ),
    ];

    test('Identifies guest increase delta, recalculates catering, and flags impacted vendors', () {
      final proposedEvent = origEvent.copyWith(guestCount: 125); // +25 guests

      final result = ChangeImpactAnalyzer.analyze(
        originalEvent: origEvent,
        proposedEvent: proposedEvent,
        currentBudgetItems: budgetItems,
        currentTasks: tasks,
        currentVendors: vendors,
      );

      expect(result.guestCountDelta, 25);
      expect(result.hasHighImpact, true);
      // Catering rate was 5000/100 = $50/head. +25 guests = +$1250 catering delta
      expect(result.estimatedCateringImpact, 1250.0);
      expect(result.affectedCategories.contains('Catering & Dining'), true);
      expect(result.affectedVendors.any((v) => v.contains('Elite Catering')), true);
      expect(result.warnings.isNotEmpty, true);
    });

    test('Identifies budget reduction and flags warnings for budget overages', () {
      final proposedEvent = origEvent.copyWith(totalBudget: 11000); // reduced from 20000 to 11000

      final result = ChangeImpactAnalyzer.analyze(
        originalEvent: origEvent,
        proposedEvent: proposedEvent,
        currentBudgetItems: budgetItems,
        currentTasks: tasks,
        currentVendors: vendors,
      );

      expect(result.budgetDelta, -9000.0);
      expect(result.warnings.any((w) => w.contains('budget reduced')), true);
    });

    test('Identifies date shift earlier and flags deadline pressure', () {
      final proposedEvent = origEvent.copyWith(
        date: DateTime(2026, 7, 15), // 17 days earlier
      );

      final result = ChangeImpactAnalyzer.analyze(
        originalEvent: origEvent,
        proposedEvent: proposedEvent,
        currentBudgetItems: budgetItems,
        currentTasks: tasks,
        currentVendors: vendors,
      );

      expect(result.daysShiftDelta, -17);
      expect(result.warnings.any((w) => w.contains('earlier')), true);
    });
  });
}
