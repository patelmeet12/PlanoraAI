import 'package:flutter_test/flutter_test.dart';
import 'package:planora_ai/features/vendors/domain/models/vendor_category.dart';
import 'package:planora_ai/features/vendors/domain/models/vendor_model.dart';
import 'package:planora_ai/features/vendors/domain/services/vendor_service.dart';

void main() {
  group('VendorService Tests', () {
    test('Calculates booking progress percentage correctly', () {
      final vendors = [
        const VendorModel(
          id: 'v1',
          eventId: 'e1',
          name: 'Venue',
          category: VendorCategory.venue,
          bookingStatus: BookingStatus.booked,
        ),
        const VendorModel(
          id: 'v2',
          eventId: 'e1',
          name: 'Caterer',
          category: VendorCategory.caterer,
          bookingStatus: BookingStatus.shortlisted,
        ),
        const VendorModel(
          id: 'v3',
          eventId: 'e1',
          name: 'Photo',
          category: VendorCategory.photographerVideographer,
          bookingStatus: BookingStatus.inquiry,
        ),
        const VendorModel(
          id: 'v4',
          eventId: 'e1',
          name: 'DJ',
          category: VendorCategory.entertainerDj,
          bookingStatus: BookingStatus.booked,
        ),
      ];

      final progress = VendorService.calculateBookingProgress(vendors);
      expect(progress, 50.0); // 2 out of 4 = 50%
    });

    test('Performs side-by-side vendor comparison and identifies lowest price and top rating', () {
      final vendors = [
        const VendorModel(
          id: 'v1',
          eventId: 'e1',
          name: 'Affordable Catering Co',
          category: VendorCategory.caterer,
          quotedPrice: 3000,
          userRating: 4.2,
        ),
        const VendorModel(
          id: 'v2',
          eventId: 'e1',
          name: 'Gourmet Artisan Dining',
          category: VendorCategory.caterer,
          quotedPrice: 5000,
          userRating: 4.9,
        ),
        const VendorModel(
          id: 'v3',
          eventId: 'e1',
          name: 'Classic Banquet Service',
          category: VendorCategory.caterer,
          quotedPrice: 4000,
          userRating: 4.5,
        ),
      ];

      final comparison = VendorService.compareVendors(vendors);

      expect(comparison.length, 3);
      // Average price is (3000 + 5000 + 4000) / 3 = 4000

      final v1Comp = comparison.firstWhere((c) => c.vendor.id == 'v1');
      expect(v1Comp.isLowestPrice, true);
      expect(v1Comp.isHighestRated, false);
      expect(v1Comp.priceDifference, -1000.0);

      final v2Comp = comparison.firstWhere((c) => c.vendor.id == 'v2');
      expect(v2Comp.isLowestPrice, false);
      expect(v2Comp.isHighestRated, true);
      expect(v2Comp.priceDifference, 1000.0);
    });
  });
}
