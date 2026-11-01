import 'package:agrikonek_calinan/features/listings/widgets/listing_map_preview.dart';
import 'package:agrikonek_calinan/models/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile verification level (Table 3.4)', () {
    test('reads levels 1 and 2 and their labels', () {
      final visited = Profile.fromMap('a', {'verificationLevel': 1});
      final coop = Profile.fromMap('b', {'verificationLevel': 2});
      expect(visited.verificationLevel, Profile.levelVisited);
      expect(visited.verificationLabel, startsWith('Visited by researchers'));
      expect(coop.verificationLevel, Profile.levelCooperativeConfirmed);
      expect(coop.verificationLabel, startsWith('Cooperative-confirmed'));
    });

    test('anything else means not recorded, with no label', () {
      expect(Profile.fromMap('c', {}).verificationLevel, 0);
      expect(Profile.fromMap('d', {'verificationLevel': 7}).verificationLevel, 0);
      expect(Profile.fromMap('e', {}).verificationLabel, isNull);
    });

    test('profile edits keep the level', () {
      final p = Profile.fromMap('a', {
        'fullName': 'Ana',
        'roles': ['seller'],
        'barangay': 'Wangan',
        'verificationLevel': 2,
      });
      expect(p.toMap()['verificationLevel'], 2);
      expect(p.copyWith(fullName: 'Ana B.').verificationLevel, 2);
    });
  });

  group('ListingMapPreview.approximate', () {
    test('rounds the farm point to about one kilometre', () {
      final point = ListingMapPreview.approximate(
          const GeoPoint(7.192345, 125.454321));
      expect(point.latitude, closeTo(7.19, 1e-9));
      expect(point.longitude, closeTo(125.45, 1e-9));
    });
  });
}
