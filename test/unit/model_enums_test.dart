import 'package:flutter_test/flutter_test.dart';
import 'package:planora_ai/features/events/domain/models/event_category.dart';
import 'package:planora_ai/features/events/domain/models/event_model.dart';
import 'package:planora_ai/features/budget/domain/models/budget_category.dart';
import 'package:planora_ai/features/budget/domain/models/budget_item.dart';
import 'package:planora_ai/features/budget/domain/models/budget_adjustment.dart';
import 'package:planora_ai/features/timeline/domain/models/timeline_task.dart';
import 'package:planora_ai/features/vendors/domain/models/vendor_category.dart';
import 'package:planora_ai/features/vendors/domain/models/vendor_model.dart';
import 'package:planora_ai/features/ideas/domain/models/event_idea.dart';
import 'package:planora_ai/features/run_sheet/domain/models/run_sheet_item.dart';
import 'package:planora_ai/features/events/data/repositories/event_repository.dart';

void main() {
  group('Domain Enums and Models Value Equality & Deserialization Tests', () {
    test('BudgetAdjustmentProposal serialization, copyWith, equality, and potentialSavings', () {
      final proposal1 = const BudgetAdjustmentProposal(
        id: 'adj_1',
        budgetItemId: 'b1',
        category: BudgetCategory.decoration,
        title: 'Downscale floral arches',
        description: 'Opt for reusable greenery accents',
        currentAmount: 2500,
        proposedAmount: 1500,
        rationale: 'Reduces decor expense by 40%',
        status: AdjustmentStatus.pending,
      );

      final proposal2 = proposal1.copyWith();
      expect(proposal1, equals(proposal2));
      expect(proposal1.hashCode, equals(proposal2.hashCode));
      expect(proposal1.potentialSavings, 1000.0);

      final json = proposal1.toJson();
      final fromJson = BudgetAdjustmentProposal.fromJson(json);
      expect(fromJson.id, 'adj_1');
      expect(fromJson.currentAmount, 2500.0);
      expect(fromJson.proposedAmount, 1500.0);
      expect(fromJson.potentialSavings, 1000.0);
      expect(fromJson.status, AdjustmentStatus.pending);

      final modified = proposal1.copyWith(
        status: AdjustmentStatus.applied,
        proposedAmount: 1200,
      );
      expect(proposal1 == modified, false);
      expect(modified.potentialSavings, 1300.0);
      expect(modified.status, AdjustmentStatus.applied);

      // Deserialization with fallback values
      final fallback = BudgetAdjustmentProposal.fromJson({});
      expect(fallback.id, isEmpty);
      expect(fallback.title, 'Budget Optimization');
      expect(fallback.category, BudgetCategory.custom);
      expect(fallback.status, AdjustmentStatus.pending);
    });

    test('BudgetCategory enum properties, display names, and parsing', () {
      expect(BudgetCategory.venue.isEssential, true);
      expect(BudgetCategory.catering.isEssential, true);
      expect(BudgetCategory.contingency.isEssential, true);
      expect(BudgetCategory.decoration.isEssential, false);
      expect(BudgetCategory.photographyVideography.isEssential, false);
      expect(BudgetCategory.entertainment.isEssential, false);
      expect(BudgetCategory.clothing.isEssential, false);
      expect(BudgetCategory.invitations.isEssential, false);
      expect(BudgetCategory.giftsFavors.isEssential, false);
      expect(BudgetCategory.custom.isEssential, false);

      for (final cat in BudgetCategory.values) {
        expect(cat.displayName, isNotEmpty);
        expect(BudgetCategory.fromString(cat.name), equals(cat));
      }
      expect(BudgetCategory.fromString('unknown_category'), equals(BudgetCategory.custom));

      for (final s in BudgetThresholdState.values) {
        expect(s.label, isNotEmpty);
      }
    });

    test('VendorCategory, BookingStatus, and PaymentStatus enums', () {
      for (final v in VendorCategory.values) {
        expect(v.displayName, isNotEmpty);
        expect(VendorCategory.fromString(v.name), equals(v));
      }
      expect(VendorCategory.fromString('non_existent'), equals(VendorCategory.custom));

      for (final b in BookingStatus.values) {
        expect(b.displayName, isNotEmpty);
        expect(BookingStatus.fromString(b.name), equals(b));
      }
      expect(BookingStatus.fromString('invalid'), equals(BookingStatus.inquiry));

      for (final p in PaymentStatus.values) {
        expect(p.displayName, isNotEmpty);
        expect(PaymentStatus.fromString(p.name), equals(p));
      }
      expect(PaymentStatus.fromString('unrecognized'), equals(PaymentStatus.unpaid));
    });

    test('EventCategory, VenueType, EventStyle, and PlanningComplexity enums', () {
      for (final e in EventCategory.values) {
        expect(e.displayName, isNotEmpty);
        expect(EventCategory.fromString(e.name), equals(e));
      }
      expect(EventCategory.fromString('unknown'), equals(EventCategory.custom));

      for (final v in VenueType.values) {
        expect(v.displayName, isNotEmpty);
      }
      for (final s in EventStyle.values) {
        expect(s.displayName, isNotEmpty);
      }
      for (final p in PlanningComplexity.values) {
        expect(p.displayName, isNotEmpty);
      }
    });

    test('TaskPriority and IdeaComplexity enums', () {
      for (final t in TaskPriority.values) {
        expect(t.displayName, isNotEmpty);
        expect(TaskPriority.fromString(t.name), equals(t));
      }
      expect(TaskPriority.fromString('non_standard'), equals(TaskPriority.medium));

      for (final i in IdeaComplexity.values) {
        expect(i.displayName, isNotEmpty);
        expect(IdeaComplexity.fromString(i.name), equals(i));
      }
      expect(IdeaComplexity.fromString('unknown_complexity'), equals(IdeaComplexity.medium));
    });

    test('BudgetItem value equality and copyWith', () {
      final b1 = const BudgetItem(
        id: 'b_1',
        eventId: 'e_1',
        category: BudgetCategory.catering,
        name: 'Buffet',
        estimatedAmount: 3000,
        confirmedAmount: 2800,
        isConfirmed: true,
      );
      final b2 = b1.copyWith();
      expect(b1, equals(b2));
      expect(b1.hashCode, equals(b2.hashCode));

      final b3 = b1.copyWith(name: 'Plated Dinner');
      expect(b1 == b3, false);
    });

    test('TimelineTask value equality, overdue, and blocking', () {
      final now = DateTime(2026, 6, 1);
      final t1 = TimelineTask(
        id: 't_1',
        eventId: 'e_1',
        title: 'Sign Venue Contract',
        description: 'Review terms',
        dueDate: DateTime(2026, 5, 20),
        dependencies: ['dep_0'],
      );

      expect(t1.isOverdue(now), true);
      expect(t1.copyWith(isCompleted: true).isOverdue(now), false);

      final depCompleted = TimelineTask(
        id: 'dep_0',
        eventId: 'e_1',
        title: 'Select Venue',
        description: '',
        dueDate: DateTime(2026, 5, 15),
        isCompleted: true,
      );
      expect(t1.isBlocked([depCompleted]), false);

      final depIncomplete = depCompleted.copyWith(isCompleted: false);
      expect(t1.isBlocked([depIncomplete]), true);
      expect(t1.isBlocked([]), false); // Missing dep doesn't crash
    });

    test('VendorModel value equality and copyWith', () {
      final v1 = const VendorModel(
        id: 'v_1',
        eventId: 'e_1',
        name: 'Grand Ballroom',
        category: VendorCategory.venue,
        estimatedPrice: 5000,
        quotedPrice: 4800,
        bookingStatus: BookingStatus.booked,
        paymentStatus: PaymentStatus.depositPaid,
      );
      final v2 = v1.copyWith();
      expect(v1, equals(v2));
      expect(v1.hashCode, equals(v2.hashCode));

      final v3 = v1.copyWith(quotedPrice: 4900);
      expect(v1 == v3, false);
    });

    test('RunSheetItem and EventIdea value equality and copyWith', () {
      final r1 = const RunSheetItem(
        id: 'r_1',
        eventId: 'e_1',
        startTime: '08:00',
        endTime: '09:00',
        title: 'Vendor Load-In',
        description: 'Floral and AV setup',
        category: 'Setup',
      );
      final r2 = r1.copyWith();
      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));

      final idea1 = const EventIdea(
        id: 'i_1',
        eventId: 'e_1',
        title: 'Acoustic Trio',
        category: 'Entertainment',
        description: 'Live string music during cocktails',
        estimatedCostRange: '\$600 - \$900',
        minCost: 600,
        maxCost: 900,
        guestSuitability: 'All Ages',
        complexity: IdeaComplexity.low,
        benefits: ['Intimate vibe'],
        limitations: ['Requires shade'],
        matchReason: 'Fits outdoor theme',
      );
      final idea2 = idea1.copyWith();
      expect(idea1, equals(idea2));
      expect(idea1.hashCode, equals(idea2.hashCode));
    });

    test('EventAggregate value equality, JSON serialization, and schema validation', () {
      final event = EventModel(
        id: 'e_agg',
        name: 'Annual Charity Ball',
        category: EventCategory.communityEvent,
        date: DateTime(2026, 11, 20),
        city: 'Austin',
        guestCount: 200,
        totalBudget: 40000,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final aggregate = EventAggregate(
        event: event,
        budgetItems: [
          const BudgetItem(
            id: 'b_1',
            eventId: 'e_agg',
            category: BudgetCategory.venue,
            name: 'Civic Center',
            estimatedAmount: 12000,
          ),
        ],
        tasks: [
          TimelineTask(
            id: 't_1',
            eventId: 'e_agg',
            title: 'Book Audio/Visual Crew',
            description: '',
            dueDate: DateTime(2026, 9, 1),
          ),
        ],
      );

      final copy = aggregate.copyWith();
      expect(aggregate, equals(copy));
      expect(aggregate.hashCode, equals(copy.hashCode));

      final json = aggregate.toJson();
      expect(json['schemaVersion'], 1);
      final restored = EventAggregate.fromJson(json);
      expect(restored.event.id, 'e_agg');
      expect(restored.budgetItems.length, 1);
      expect(restored.tasks.length, 1);
    });
  });
}
