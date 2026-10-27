enum BudgetCategory {
  venue,
  catering,
  decoration,
  photographyVideography,
  entertainment,
  clothing,
  invitations,
  transportation,
  accommodation,
  giftsFavors,
  contingency,
  custom;

  String get displayName {
    switch (this) {
      case BudgetCategory.venue:
        return 'Venue & Location';
      case BudgetCategory.catering:
        return 'Catering & Dining';
      case BudgetCategory.decoration:
        return 'Decoration & Floral';
      case BudgetCategory.photographyVideography:
        return 'Photo & Video';
      case BudgetCategory.entertainment:
        return 'Music & Entertainment';
      case BudgetCategory.clothing:
        return 'Attire & Wardrobe';
      case BudgetCategory.invitations:
        return 'Invitations & Print';
      case BudgetCategory.transportation:
        return 'Transportation & Logistics';
      case BudgetCategory.accommodation:
        return 'Guest Accommodation';
      case BudgetCategory.giftsFavors:
        return 'Gifts & Favors';
      case BudgetCategory.contingency:
        return 'Contingency Reserve';
      case BudgetCategory.custom:
        return 'Custom Category';
    }
  }

  bool get isEssential {
    switch (this) {
      case BudgetCategory.venue:
      case BudgetCategory.catering:
      case BudgetCategory.contingency:
        return true;
      default:
        return false;
    }
  }

  static BudgetCategory fromString(String val) {
    return BudgetCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => BudgetCategory.custom,
    );
  }
}

enum BudgetThresholdState {
  withinBudget,
  approachingLimit,
  overBudget;

  String get label {
    switch (this) {
      case BudgetThresholdState.withinBudget:
        return 'Within Budget';
      case BudgetThresholdState.approachingLimit:
        return 'Approaching Limit';
      case BudgetThresholdState.overBudget:
        return 'Over Budget';
    }
  }
}
