enum EventCategory {
  wedding,
  birthday,
  communityEvent,
  anniversary,
  engagement,
  babyShower,
  custom;

  String get displayName {
    switch (this) {
      case EventCategory.wedding:
        return 'Wedding';
      case EventCategory.birthday:
        return 'Birthday Party';
      case EventCategory.communityEvent:
        return 'Community Gathering';
      case EventCategory.anniversary:
        return 'Anniversary Celebration';
      case EventCategory.engagement:
        return 'Engagement Party';
      case EventCategory.babyShower:
        return 'Baby Shower';
      case EventCategory.custom:
        return 'Custom Event';
    }
  }

  static EventCategory fromString(String val) {
    return EventCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => EventCategory.custom,
    );
  }
}

enum VenueType {
  indoor,
  outdoor,
  hybrid;

  String get displayName {
    switch (this) {
      case VenueType.indoor:
        return 'Indoor';
      case VenueType.outdoor:
        return 'Outdoor';
      case VenueType.hybrid:
        return 'Hybrid (Indoor & Outdoor)';
    }
  }
}

enum EventStyle {
  formal,
  casual,
  traditional,
  modern;

  String get displayName {
    switch (this) {
      case EventStyle.formal:
        return 'Formal & Sophisticated';
      case EventStyle.casual:
        return 'Casual & Relaxed';
      case EventStyle.traditional:
        return 'Traditional & Cultural';
      case EventStyle.modern:
        return 'Modern & Minimalist';
    }
  }
}

enum PlanningComplexity {
  relaxed,
  balanced,
  highDetail;

  String get displayName {
    switch (this) {
      case PlanningComplexity.relaxed:
        return 'Relaxed (Essential Milestones)';
      case PlanningComplexity.balanced:
        return 'Balanced (Standard Coordination)';
      case PlanningComplexity.highDetail:
        return 'High Detail (Full Production & Run Sheet)';
    }
  }
}
