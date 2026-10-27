enum IdeaComplexity {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case IdeaComplexity.low:
        return 'Low Complexity';
      case IdeaComplexity.medium:
        return 'Moderate Complexity';
      case IdeaComplexity.high:
        return 'High Production';
    }
  }

  static IdeaComplexity fromString(String val) {
    return IdeaComplexity.values.firstWhere(
      (c) => c.name.toLowerCase() == val.toLowerCase(),
      orElse: () => IdeaComplexity.medium,
    );
  }
}

class EventIdea {
  final String id;
  final String eventId;
  final String title;
  final String category; // Decor, Food, Entertainment, Logistics, Contingency, Accessibility
  final String description;
  final String estimatedCostRange;
  final double minCost;
  final double maxCost;
  final String guestSuitability;
  final IdeaComplexity complexity;
  final List<String> benefits;
  final List<String> limitations;
  final String matchReason;
  final bool isEcoFriendly;
  final bool isBookmarked;
  final bool isAddedToTasks;

  const EventIdea({
    required this.id,
    required this.eventId,
    required this.title,
    required this.category,
    required this.description,
    required this.estimatedCostRange,
    required this.minCost,
    required this.maxCost,
    required this.guestSuitability,
    required this.complexity,
    required this.benefits,
    required this.limitations,
    required this.matchReason,
    this.isEcoFriendly = false,
    this.isBookmarked = false,
    this.isAddedToTasks = false,
  });

  EventIdea copyWith({
    String? id,
    String? eventId,
    String? title,
    String? category,
    String? description,
    String? estimatedCostRange,
    double? minCost,
    double? maxCost,
    String? guestSuitability,
    IdeaComplexity? complexity,
    List<String>? benefits,
    List<String>? limitations,
    String? matchReason,
    bool? isEcoFriendly,
    bool? isBookmarked,
    bool? isAddedToTasks,
  }) {
    return EventIdea(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      estimatedCostRange: estimatedCostRange ?? this.estimatedCostRange,
      minCost: minCost ?? this.minCost,
      maxCost: maxCost ?? this.maxCost,
      guestSuitability: guestSuitability ?? this.guestSuitability,
      complexity: complexity ?? this.complexity,
      benefits: benefits ?? this.benefits,
      limitations: limitations ?? this.limitations,
      matchReason: matchReason ?? this.matchReason,
      isEcoFriendly: isEcoFriendly ?? this.isEcoFriendly,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isAddedToTasks: isAddedToTasks ?? this.isAddedToTasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'category': category,
      'description': description,
      'estimatedCostRange': estimatedCostRange,
      'minCost': minCost,
      'maxCost': maxCost,
      'guestSuitability': guestSuitability,
      'complexity': complexity.name,
      'benefits': benefits,
      'limitations': limitations,
      'matchReason': matchReason,
      'isEcoFriendly': isEcoFriendly,
      'isBookmarked': isBookmarked,
      'isAddedToTasks': isAddedToTasks,
    };
  }

  factory EventIdea.fromJson(Map<String, dynamic> json) {
    return EventIdea(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      title: json['title'] as String? ?? 'Idea Concept',
      category: json['category'] as String? ?? 'General',
      description: json['description'] as String? ?? '',
      estimatedCostRange: json['estimatedCostRange'] as String? ?? '\$100 - \$300',
      minCost: (json['minCost'] as num?)?.toDouble() ?? 100.0,
      maxCost: (json['maxCost'] as num?)?.toDouble() ?? 300.0,
      guestSuitability: json['guestSuitability'] as String? ?? 'All Attendees',
      complexity: IdeaComplexity.fromString(json['complexity'] as String? ?? 'medium'),
      benefits: (json['benefits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      limitations: (json['limitations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      matchReason: json['matchReason'] as String? ?? '',
      isEcoFriendly: json['isEcoFriendly'] as bool? ?? false,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      isAddedToTasks: json['isAddedToTasks'] as bool? ?? false,
    );
  }
}
