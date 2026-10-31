import 'budget_category.dart';

class BudgetItem {
  final String id;
  final String eventId;
  final BudgetCategory category;
  final String customCategoryName;
  final String name;
  final double estimatedAmount;
  final double confirmedAmount;
  final bool isConfirmed;
  final String? notes;
  final int priority; // 1 = High, 2 = Medium, 3 = Flexible

  const BudgetItem({
    required this.id,
    required this.eventId,
    required this.category,
    this.customCategoryName = '',
    required this.name,
    required this.estimatedAmount,
    this.confirmedAmount = 0.0,
    this.isConfirmed = false,
    this.notes,
    this.priority = 2,
  });

  double get effectiveAmount => isConfirmed ? confirmedAmount : estimatedAmount;

  BudgetItem copyWith({
    String? id,
    String? eventId,
    BudgetCategory? category,
    String? customCategoryName,
    String? name,
    double? estimatedAmount,
    double? confirmedAmount,
    bool? isConfirmed,
    String? notes,
    int? priority,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      category: category ?? this.category,
      customCategoryName: customCategoryName ?? this.customCategoryName,
      name: name ?? this.name,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      confirmedAmount: confirmedAmount ?? this.confirmedAmount,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'category': category.name,
      'customCategoryName': customCategoryName,
      'name': name,
      'estimatedAmount': estimatedAmount,
      'confirmedAmount': confirmedAmount,
      'isConfirmed': isConfirmed,
      'notes': notes,
      'priority': priority,
    };
  }

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    return BudgetItem(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      category: BudgetCategory.fromString(json['category'] as String? ?? 'custom'),
      customCategoryName: json['customCategoryName'] as String? ?? '',
      name: json['name'] as String? ?? 'Expense Item',
      estimatedAmount: (json['estimatedAmount'] as num?)?.toDouble() ?? 0.0,
      confirmedAmount: (json['confirmedAmount'] as num?)?.toDouble() ?? 0.0,
      isConfirmed: json['isConfirmed'] as bool? ?? false,
      notes: json['notes'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 2,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          eventId == other.eventId &&
          category == other.category &&
          customCategoryName == other.customCategoryName &&
          name == other.name &&
          estimatedAmount == other.estimatedAmount &&
          confirmedAmount == other.confirmedAmount &&
          isConfirmed == other.isConfirmed &&
          notes == other.notes &&
          priority == other.priority;

  @override
  int get hashCode => Object.hash(
        id,
        eventId,
        category,
        customCategoryName,
        name,
        estimatedAmount,
        confirmedAmount,
        isConfirmed,
        notes,
        priority,
      );
}
