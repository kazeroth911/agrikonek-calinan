import 'package:agrikonek_calinan/models/listing.dart';
import 'package:agrikonek_calinan/services/listing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Listing', () {
    test('fromMap round-trips core fields', () {
      final listing = Listing.fromMap('lst1', {
        'ownerId': 'uid123',
        'ownerName': 'Mang Nelson Alvaro',
        'ownerBarangay': 'Wangan',
        'title': 'Durian (Puyat)',
        'category': 'Fruits',
        'description': 'Sweet, freshly harvested',
        'unit': 'kg',
        'price': 120,
        'modes': ['sale', 'barter'],
        'photoUrls': ['https://example.com/p.jpg'],
        'status': 'active',
      });

      expect(listing.listingId, 'lst1');
      expect(listing.ownerName, 'Mang Nelson Alvaro');
      expect(listing.ownerBarangay, 'Wangan');
      expect(listing.price, 120);
      expect(listing.modes,
          containsAll([ListingMode.sale, ListingMode.barter]));
      expect(listing.status, ListingStatus.active);

      final map = listing.toMap();
      expect(map['title'], 'Durian (Puyat)');
      expect(map['modes'], ['sale', 'barter']);
      expect(map['price'], 120);
    });

    test('handles missing/empty map defensively', () {
      final listing = Listing.fromMap('x', {});
      expect(listing.title, '');
      expect(listing.category, 'Others');
      expect(listing.price, isNull);
      expect(listing.modes, [ListingMode.sale]);
      expect(listing.status, ListingStatus.active);
      expect(listing.photoUrls, isEmpty);
    });

    test('barter-only listing carries null price', () {
      final listing = Listing.fromMap('b', {
        'title': 'Chicken manure for compost',
        'modes': ['barter'],
      });
      expect(listing.price, isNull);
      expect(listing.modes, [ListingMode.barter]);
    });
  });

  group('ListingRepository.filterByKeyword', () {
    final listings = [
      Listing.fromMap('1', {
        'title': 'Durian (Puyat)',
        'description': 'Sweet variety',
        'category': 'Fruits',
        'ownerName': 'Nelson Alvaro',
        'ownerBarangay': 'Wangan',
      }),
      Listing.fromMap('2', {
        'title': 'Native eggs',
        'description': 'Free range',
        'category': 'Poultry & Eggs',
        'ownerName': 'Maria Santos',
        'ownerBarangay': 'Lamanan',
      }),
    ];

    test('empty query returns everything', () {
      expect(ListingRepository.filterByKeyword(listings, ''), hasLength(2));
      expect(ListingRepository.filterByKeyword(listings, '   '), hasLength(2));
    });

    test('matches title case-insensitively', () {
      final result = ListingRepository.filterByKeyword(listings, 'DURIAN');
      expect(result, hasLength(1));
      expect(result.first.listingId, '1');
    });

    test('matches owner name and barangay', () {
      expect(ListingRepository.filterByKeyword(listings, 'santos'),
          hasLength(1));
      expect(ListingRepository.filterByKeyword(listings, 'wangan'),
          hasLength(1));
    });

    test('matches category and description', () {
      expect(ListingRepository.filterByKeyword(listings, 'poultry'),
          hasLength(1));
      expect(ListingRepository.filterByKeyword(listings, 'free range'),
          hasLength(1));
    });

    test('no match returns empty list', () {
      expect(
          ListingRepository.filterByKeyword(listings, 'carabao'), isEmpty);
    });
  });
}
