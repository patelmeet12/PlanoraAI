import 'event_category.dart';

class EventModel {
  final String id;
  final String name;
  final EventCategory category;
  final DateTime date;
  final String city;
  final int guestCount;
  final double totalBudget;
  final String currency;
  final String theme;
  final VenueType venueType;
  final EventStyle style;
  final List<String> dietaryRequirements;
  final List<String> accessibilityRequirements;
  final PlanningComplexity planningComplexity;
  final String? existingBookings;
  final String? specialRequirements;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventModel({
    required this.id,
    required this.name,
    required this.category,
    required this.date,
    required this.city,
    required this.guestCount,
    required this.totalBudget,
    this.currency = 'USD',
    this.theme = 'Modern Elegant',
    this.venueType = VenueType.indoor,
    this.style = EventStyle.modern,
    this.dietaryRequirements = const [],
    this.accessibilityRequirements = const [],
    this.planningComplexity = PlanningComplexity.balanced,
    this.existingBookings,
    this.specialRequirements,
    required this.createdAt,
    required this.updatedAt,
  });

  EventModel copyWith({
    String? id,
    String? name,
    EventCategory? category,
    DateTime? date,
    String? city,
    int? guestCount,
    double? totalBudget,
    String? currency,
    String? theme,
    VenueType? venueType,
    EventStyle? style,
    List<String>? dietaryRequirements,
    List<String>? accessibilityRequirements,
    PlanningComplexity? planningComplexity,
    String? existingBookings,
    String? specialRequirements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      date: date ?? this.date,
      city: city ?? this.city,
      guestCount: guestCount ?? this.guestCount,
      totalBudget: totalBudget ?? this.totalBudget,
      currency: currency ?? this.currency,
      theme: theme ?? this.theme,
      venueType: venueType ?? this.venueType,
      style: style ?? this.style,
      dietaryRequirements: dietaryRequirements ?? this.dietaryRequirements,
      accessibilityRequirements: accessibilityRequirements ?? this.accessibilityRequirements,
      planningComplexity: planningComplexity ?? this.planningComplexity,
      existingBookings: existingBookings ?? this.existingBookings,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'date': date.toIso8601String(),
      'city': city,
      'guestCount': guestCount,
      'totalBudget': totalBudget,
      'currency': currency,
      'theme': theme,
      'venueType': venueType.name,
      'style': style.name,
      'dietaryRequirements': dietaryRequirements,
      'accessibilityRequirements': accessibilityRequirements,
      'planningComplexity': planningComplexity.name,
      'existingBookings': existingBookings,
      'specialRequirements': specialRequirements,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Event',
      category: EventCategory.fromString(json['category'] as String? ?? 'custom'),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      city: json['city'] as String? ?? 'Location Pending',
      guestCount: (json['guestCount'] as num?)?.toInt() ?? 50,
      totalBudget: (json['totalBudget'] as num?)?.toDouble() ?? 5000.0,
      currency: json['currency'] as String? ?? 'USD',
      theme: json['theme'] as String? ?? 'Modern Elegant',
      venueType: VenueType.values.firstWhere(
        (v) => v.name == (json['venueType'] as String?),
        orElse: () => VenueType.indoor,
      ),
      style: EventStyle.values.firstWhere(
        (s) => s.name == (json['style'] as String?),
        orElse: () => EventStyle.modern,
      ),
      dietaryRequirements: (json['dietaryRequirements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      accessibilityRequirements: (json['accessibilityRequirements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      planningComplexity: PlanningComplexity.values.firstWhere(
        (p) => p.name == (json['planningComplexity'] as String?),
        orElse: () => PlanningComplexity.balanced,
      ),
      existingBookings: json['existingBookings'] as String?,
      specialRequirements: json['specialRequirements'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
