import 'budget_category.dart';

enum AdjustmentStatus {
  pending,
  applied,
  rejected,
}

class BudgetAdjustmentProposal {
  final String id;
  final String budgetItemId;
  final BudgetCategory category;
  final String title;
  final String description;
  final double currentAmount;
  final double proposedAmount;
  final String rationale;
  final AdjustmentStatus status;

  const BudgetAdjustmentProposal({
    required this.id,
    required this.budgetItemId,
    required this.category,
    required this.title,
    required this.description,
    required this.currentAmount,
    required this.proposedAmount,
    required this.rationale,
    this.status = AdjustmentStatus.pending,
  });

  double get potentialSavings => currentAmount - proposedAmount;

  BudgetAdjustmentProposal copyWith({
    String? id,
    String? budgetItemId,
    BudgetCategory? category,
    String? title,
    String? description,
    double? currentAmount,
    double? proposedAmount,
    String? rationale,
    AdjustmentStatus? status,
  }) {
    return BudgetAdjustmentProposal(
      id: id ?? this.id,
      budgetItemId: budgetItemId ?? this.budgetItemId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      currentAmount: currentAmount ?? this.currentAmount,
      proposedAmount: proposedAmount ?? this.proposedAmount,
      rationale: rationale ?? this.rationale,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'budgetItemId': budgetItemId,
      'category': category.name,
      'title': title,
      'description': description,
      'currentAmount': currentAmount,
      'proposedAmount': proposedAmount,
      'rationale': rationale,
      'status': status.name,
    };
  }

  factory BudgetAdjustmentProposal.fromJson(Map<String, dynamic> json) {
    return BudgetAdjustmentProposal(
      id: json['id'] as String? ?? '',
      budgetItemId: json['budgetItemId'] as String? ?? '',
      category: BudgetCategory.fromString(json['category'] as String? ?? 'custom'),
      title: json['title'] as String? ?? 'Budget Optimization',
      description: json['description'] as String? ?? '',
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      proposedAmount: (json['proposedAmount'] as num?)?.toDouble() ?? 0.0,
      rationale: json['rationale'] as String? ?? '',
      status: AdjustmentStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String?),
        orElse: () => AdjustmentStatus.pending,
      ),
    );
  }
}
