import 'package:agrikonek_calinan/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile', () {
    test('fromMap round-trips core fields', () {
      final profile = Profile.fromMap('uid123', {
        'fullName': 'Mang Nelson Alvaro',
        'roles': ['seller', 'trader'],
        'barangay': 'Wangan',
        'phone': '+639171234567',
        'products': ['durian', 'banana'],
        'barterWillingness': true,
        'consentGiven': true,
      });

      expect(profile.userId, 'uid123');
      expect(profile.fullName, 'Mang Nelson Alvaro');
      expect(profile.roles, containsAll(['seller', 'trader']));
      expect(profile.isAdmin, isFalse);
      expect(profile.barterWillingness, isTrue);

      final map = profile.toMap();
      expect(map['fullName'], 'Mang Nelson Alvaro');
      expect(map['barangay'], 'Wangan');
      expect(map['products'], ['durian', 'banana']);
    });

    test('handles missing/empty map defensively', () {
      final profile = Profile.fromMap('x', {});
      expect(profile.fullName, '');
      expect(profile.roles, isEmpty);
      expect(profile.consentGiven, isFalse);
    });

    test('isAdmin reflects roles', () {
      final admin = Profile.fromMap('a', {'roles': ['admin']});
      expect(admin.isAdmin, isTrue);
    });
  });
}
