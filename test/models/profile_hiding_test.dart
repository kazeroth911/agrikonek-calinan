import 'package:agrikonek_calinan/models/listing.dart';
import 'package:agrikonek_calinan/models/profile.dart';
import 'package:agrikonek_calinan/services/listing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Listing _listing(String id, String ownerId) => Listing.fromMap(id, {
      'ownerId': ownerId,
      'ownerName': 'Owner $ownerId',
      'ownerBarangay': 'Wangan',
      'title': 'Item $id',
      'category': 'Fruits',
      'description': '',
      'modes': ['sale'],
      'status': 'active',
    });

void main() {
  group('Profile.hidden', () {
    test('reads the hidden flag and defaults to visible', () {
      expect(Profile.fromMap('a', {'hidden': true}).hidden, isTrue);
      expect(Profile.fromMap('b', {}).hidden, isFalse);
      expect(Profile.fromMap('c', {'hidden': 'yes'}).hidden, isFalse);
    });

    test('toMap never writes hidden, so profile edits cannot unhide', () {
      final profile = Profile.fromMap('a', {
        'fullName': 'Ana',
        'roles': ['seller'],
        'barangay': 'Wangan',
        'hidden': true,
      });
      expect(profile.toMap().containsKey('hidden'), isFalse);
      expect(profile.copyWith(fullName: 'Ana B.').hidden, isTrue);
    });
  });

  group('ListingRepository.withoutHiddenOwners', () {
    final listings = [
      _listing('l1', 'visible'),
      _listing('l2', 'hiddenUser'),
      _listing('l3', 'visible'),
    ];

    test('drops only listings from hidden owners', () {
      final result =
          ListingRepository.withoutHiddenOwners(listings, {'hiddenUser'});
      expect(result.map((l) => l.listingId), ['l1', 'l3']);
    });

    test('keeps everything when nobody is hidden', () {
      expect(ListingRepository.withoutHiddenOwners(listings, {}), listings);
    });
  });
}
