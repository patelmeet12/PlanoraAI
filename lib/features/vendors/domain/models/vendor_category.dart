enum VendorCategory {
  venue,
  caterer,
  decorator,
  photographerVideographer,
  entertainerDj,
  florist,
  transportation,
  rentals,
  custom;

  String get displayName {
    switch (this) {
      case VendorCategory.venue:
        return 'Venue';
      case VendorCategory.caterer:
        return 'Caterer & Dining';
      case VendorCategory.decorator:
        return 'Decorator & Stylist';
      case VendorCategory.photographerVideographer:
        return 'Photographer & Videographer';
      case VendorCategory.entertainerDj:
        return 'DJ & Entertainer';
      case VendorCategory.florist:
        return 'Florist';
      case VendorCategory.transportation:
        return 'Transportation';
      case VendorCategory.rentals:
        return 'Rentals & Staging';
      case VendorCategory.custom:
        return 'Custom Vendor';
    }
  }

  static VendorCategory fromString(String val) {
    return VendorCategory.values.firstWhere(
      (v) => v.name.toLowerCase() == val.toLowerCase(),
      orElse: () => VendorCategory.custom,
    );
  }
}

enum BookingStatus {
  inquiry,
  shortlisted,
  quoted,
  booked,
  declined;

  String get displayName {
    switch (this) {
      case BookingStatus.inquiry:
        return 'Inquiry Sent';
      case BookingStatus.shortlisted:
        return 'Shortlisted';
      case BookingStatus.quoted:
        return 'Quote Received';
      case BookingStatus.booked:
        return 'Booked & Confirmed';
      case BookingStatus.declined:
        return 'Declined';
    }
  }

  static BookingStatus fromString(String val) {
    return BookingStatus.values.firstWhere(
      (b) => b.name.toLowerCase() == val.toLowerCase(),
      orElse: () => BookingStatus.inquiry,
    );
  }
}

enum PaymentStatus {
  unpaid,
  depositPaid,
  fullyPaid;

  String get displayName {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.depositPaid:
        return 'Deposit Paid';
      case PaymentStatus.fullyPaid:
        return 'Fully Paid';
    }
  }

  static PaymentStatus fromString(String val) {
    return PaymentStatus.values.firstWhere(
      (p) => p.name.toLowerCase() == val.toLowerCase(),
      orElse: () => PaymentStatus.unpaid,
    );
  }
}
