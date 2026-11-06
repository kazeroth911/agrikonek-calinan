import 'package:agrikonek_calinan/models/cooperative.dart';
import 'package:agrikonek_calinan/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile claim status (paper 3.5.4)', () {
    test('reads claimedBy and claimedFrom', () {
      final prepared = Profile.fromMap('prep1', {'claimedBy': 'phoneUser'});
      final claimed = Profile.fromMap('phoneUser', {'claimedFrom': 'prep1'});
      expect(prepared.isClaimed, isTrue);
      expect(claimed.isClaimed, isFalse);
      expect(claimed.claimedFrom, 'prep1');
    });

    test('toMap never writes the claim fields', () {
      final p = Profile.fromMap('a', {
        'fullName': 'Ana',
        'barangay': 'Wangan',
        'claimedBy': 'x',
        'claimedFrom': 'y',
      });
      final map = p.toMap();
      expect(map.containsKey('claimedBy'), isFalse);
      expect(map.containsKey('claimedFrom'), isFalse);
      expect(map.containsKey('claimedAt'), isFalse);
    });
  });

  group('Cooperative reference (Figure 3.4)', () {
    test('profile keeps its cooperative through edits', () {
      final p = Profile.fromMap('a', {'cooperativeId': 'coop1'});
      expect(p.cooperativeId, 'coop1');
      expect(p.copyWith(fullName: 'Ana').cooperativeId, 'coop1');
      expect(p.toMap()['cooperativeId'], 'coop1');
    });

    test('cooperative writes exactly the fields the rules accept', () {
      const c = Cooperative(cooperativeId: '', name: '  Calinan Coop ');
      expect(c.toMap().keys.toSet(), {'name', 'barangay', 'createdAt'});
      expect(c.toMap()['name'], 'Calinan Coop');
    });
  });
}
