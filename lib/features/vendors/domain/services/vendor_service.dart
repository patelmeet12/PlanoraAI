import 'package:uuid/uuid.dart';
import '../../../events/domain/models/event_category.dart';
import '../models/vendor_category.dart';
import '../models/vendor_model.dart';

class VendorComparisonItem {
  final VendorModel vendor;
  final double priceDifference; // compared to category average
  final bool isLowestPrice;
  final bool isHighestRated;

  const VendorComparisonItem({
    required this.vendor,
    required this.priceDifference,
    required this.isLowestPrice,
    required this.isHighestRated,
  });
}

class VendorService {
  /// Compare a list of vendors in the same category
  static List<VendorComparisonItem> compareVendors(List<VendorModel> vendors) {
    if (vendors.isEmpty) return [];

    final activePrices = vendors.map((v) => v.quotedPrice > 0 ? v.quotedPrice : v.estimatedPrice).toList();
    final double avgPrice = activePrices.reduce((a, b) => a + b) / activePrices.length;

    double lowestPrice = double.infinity;
    double highestRating = -1.0;

    for (final v in vendors) {
      final price = v.quotedPrice > 0 ? v.quotedPrice : v.estimatedPrice;
      if (price > 0 && price < lowestPrice) lowestPrice = price;
      if (v.userRating > highestRating) highestRating = v.userRating;
    }

    return vendors.map((v) {
      final price = v.quotedPrice > 0 ? v.quotedPrice : v.estimatedPrice;
      return VendorComparisonItem(
        vendor: v,
        priceDifference: price - avgPrice,
        isLowestPrice: price > 0 && price == lowestPrice,
        isHighestRated: v.userRating > 0 && v.userRating == highestRating,
      );
    }).toList();
  }

  /// Calculates percentage of vendors confirmed/booked
  static double calculateBookingProgress(List<VendorModel> vendors) {
    if (vendors.isEmpty) return 0.0;
    final bookedCount = vendors.where((v) => v.bookingStatus == BookingStatus.booked).length;
    return (bookedCount / vendors.length) * 100.0;
  }

  /// Generate sample benchmark vendors tailored to the event category
  static List<VendorModel> generateSampleVendors({
    required String eventId,
    required EventCategory category,
    required double totalBudget,
  }) {
    const uuid = Uuid();

    if (category == EventCategory.wedding) {
      return [
        VendorModel(
          id: uuid.v4(),
          eventId: eventId,
          name: 'Grand Heritage Glasshouse & Garden',
          category: VendorCategory.venue,
          contactEmail: 'events@grandheritage.example',
          contactPhone: '+1 (555) 019-2831',
          estimatedPrice: totalBudget * 0.35,
          quotedPrice: totalBudget * 0.34,
          bookingStatus: BookingStatus.shortlisted,
          paymentStatus: PaymentStatus.unpaid,
          userRating: 4.8,
          notes: 'Includes ambient evening uplighting, private bridal suite, and 12-hour exclusive access.',
          isDemoData: true,
        ),
        VendorModel(
          id: uuid.v4(),
          eventId: eventId,
          name: 'Artisan Culinary Collective',
          category: VendorCategory.caterer,
          contactEmail: 'tastings@artisanculinary.example',
          contactPhone: '+1 (555) 014-9923',
          estimatedPrice: totalBudget * 0.28,
          quotedPrice: totalBudget * 0.27,
          bookingStatus: BookingStatus.quoted,
          paymentStatus: PaymentStatus.unpaid,
          userRating: 4.9,
          notes: 'Full farm-to-table farm service with comprehensive vegan & nut-free certified handling.',
          isDemoData: true,
        ),
        VendorModel(
          id: uuid.v4(),
          eventId: eventId,
          name: 'Lumina Cinema & Photography',
          category: VendorCategory.photographerVideographer,
          contactEmail: 'studio@luminacinema.example',
          contactPhone: '+1 (555) 018-4422',
          estimatedPrice: totalBudget * 0.12,
          quotedPrice: totalBudget * 0.115,
          bookingStatus: BookingStatus.shortlisted,
          paymentStatus: PaymentStatus.unpaid,
          userRating: 4.7,
          notes: 'Two master shooters, 4K drone coverage, online gallery within 14 days.',
          isDemoData: true,
        ),
        VendorModel(
          id: uuid.v4(),
          eventId: eventId,
          name: 'Botanical Alchemy Florals',
          category: VendorCategory.florist,
          contactEmail: 'hello@botanicalalchemy.example',
          contactPhone: '+1 (555) 012-7711',
          estimatedPrice: totalBudget * 0.08,
          quotedPrice: totalBudget * 0.075,
          bookingStatus: BookingStatus.inquiry,
          paymentStatus: PaymentStatus.unpaid,
          userRating: 4.6,
          notes: 'Specializes in seasonal organic arrangements and sustainable foam-free floral arches.',
          isDemoData: true,
        ),
      ];
    } else if (category == EventCategory.communityEvent) {
      return [
        VendorModel(
          id: uuid.v4(),
          eventId: eventId,
          name: 'Civic Cultural Center Hall',
          category: VendorCategory.venue,
          contactEmail: 'bookings@civiccenter.example',
          contactPhone: '+1 (555) 011-3000',
          estimatedPrice: totalBudget * 0.30,
          quotedPrice: totalBudget * 0.28,
          bookingStatus: BookingStatus.shortlisted,
          paymentStatus: PaymentStatus.unpaid,
          userRating: 4.5,
          notes: 'Municipal hall with ADA wheelchair ramps, hearing loop system, and public transit connectivity.',
          isDemoData: true,
        ),
        VendorModel(
          id: uuid.v4(),
          eventId: eventId,
          name: 'Harmony Sound & Stage Production',
          category: VendorCategory.rentals,
          contactEmail: 'sound@harmonystage.example',
          contactPhone: '+1 (555) 015-8822',
          estimatedPrice: totalBudget * 0.20,
          quotedPrice: totalBudget * 0.19,
          bookingStatus: BookingStatus.quoted,
          paymentStatus: PaymentStatus.unpaid,
          userRating: 4.8,
          notes: 'Wireless lapel microphones, dual projector displays, and sound engineer onsite.',
          isDemoData: true,
        ),
      ];
    } else {
      // Birthday / Anniversary
      return [
        VendorModel(
          id: uuid.v4(),
          eventId: eventId,
          name: 'Skyline Terrace Lounge',
          category: VendorCategory.venue,
          contactEmail: 'lounge@skylineterrace.example',
          contactPhone: '+1 (555) 017-5500',
          estimatedPrice: totalBudget * 0.40,
          quotedPrice: totalBudget * 0.38,
          bookingStatus: BookingStatus.shortlisted,
          paymentStatus: PaymentStatus.unpaid,
          userRating: 4.7,
          notes: 'Rooftop venue with sound isolation, indoor fallback hall, and catering prep kitchen.',
          isDemoData: true,
        ),
        VendorModel(
          id: uuid.v4(),
          eventId: eventId,
          name: 'Groove Collective Live DJ',
          category: VendorCategory.entertainerDj,
          contactEmail: 'dj@groovecollective.example',
          contactPhone: '+1 (555) 013-1122',
          estimatedPrice: totalBudget * 0.15,
          quotedPrice: totalBudget * 0.14,
          bookingStatus: BookingStatus.inquiry,
          paymentStatus: PaymentStatus.unpaid,
          userRating: 4.9,
          notes: 'Custom playlist curation, party lighting package, and MC coordination.',
          isDemoData: true,
        ),
      ];
    }
  }
}
