import 'vendor_category.dart';

class VendorModel {
  final String id;
  final String eventId;
  final String name;
  final VendorCategory category;
  final String? customCategoryName;
  final String? contactEmail;
  final String? contactPhone;
  final String? website;
  final double estimatedPrice;
  final double quotedPrice;
  final BookingStatus bookingStatus;
  final PaymentStatus paymentStatus;
  final double userRating; // 0 to 5
  final DateTime? followUpDate;
  final String? notes;
  final bool isDemoData;

  const VendorModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.category,
    this.customCategoryName,
    this.contactEmail,
    this.contactPhone,
    this.website,
    this.estimatedPrice = 0.0,
    this.quotedPrice = 0.0,
    this.bookingStatus = BookingStatus.inquiry,
    this.paymentStatus = PaymentStatus.unpaid,
    this.userRating = 0.0,
    this.followUpDate,
    this.notes,
    this.isDemoData = false,
  });

  VendorModel copyWith({
    String? id,
    String? eventId,
    String? name,
    VendorCategory? category,
    String? customCategoryName,
    String? contactEmail,
    String? contactPhone,
    String? website,
    double? estimatedPrice,
    double? quotedPrice,
    BookingStatus? bookingStatus,
    PaymentStatus? paymentStatus,
    double? userRating,
    DateTime? followUpDate,
    String? notes,
    bool? isDemoData,
  }) {
    return VendorModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      category: category ?? this.category,
      customCategoryName: customCategoryName ?? this.customCategoryName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      website: website ?? this.website,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      quotedPrice: quotedPrice ?? this.quotedPrice,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      userRating: userRating ?? this.userRating,
      followUpDate: followUpDate ?? this.followUpDate,
      notes: notes ?? this.notes,
      isDemoData: isDemoData ?? this.isDemoData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'name': name,
      'category': category.name,
      'customCategoryName': customCategoryName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'website': website,
      'estimatedPrice': estimatedPrice,
      'quotedPrice': quotedPrice,
      'bookingStatus': bookingStatus.name,
      'paymentStatus': paymentStatus.name,
      'userRating': userRating,
      'followUpDate': followUpDate?.toIso8601String(),
      'notes': notes,
      'isDemoData': isDemoData,
    };
  }

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Vendor',
      category: VendorCategory.fromString(json['category'] as String? ?? 'custom'),
      customCategoryName: json['customCategoryName'] as String?,
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
      website: json['website'] as String?,
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      quotedPrice: (json['quotedPrice'] as num?)?.toDouble() ?? 0.0,
      bookingStatus: BookingStatus.fromString(json['bookingStatus'] as String? ?? 'inquiry'),
      paymentStatus: PaymentStatus.fromString(json['paymentStatus'] as String? ?? 'unpaid'),
      userRating: (json['userRating'] as num?)?.toDouble() ?? 0.0,
      followUpDate: json['followUpDate'] != null
          ? DateTime.tryParse(json['followUpDate'] as String)
          : null,
      notes: json['notes'] as String?,
      isDemoData: json['isDemoData'] as bool? ?? false,
    );
  }
}
