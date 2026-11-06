import 'package:agrikonek_calinan/models/announcement.dart';
import 'package:agrikonek_calinan/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile(String id, String barangay, {bool admin = false}) => Profile(
      userId: id,
      fullName: 'User $id',
      roles: admin ? const ['admin'] : const ['seller'],
      barangay: barangay,
    );

void main() {
  final profiles = [
    _profile('admin1', 'Calinan Proper', admin: true),
    _profile('f1', 'Calinan Proper'),
    _profile('f2', 'Dacudao'),
    _profile('f3', 'Dacudao'),
  ];

  group('Announcement.pickRecipients', () {
    test('everyone means every non-admin account', () {
      final ids = Announcement.pickRecipients(
        profiles: profiles,
        audience: AnnouncementAudience.all,
        senderId: 'admin1',
      ).map((p) => p.userId);
      expect(ids, ['f1', 'f2', 'f3']);
    });

    test('barangay keeps only that barangay', () {
      final ids = Announcement.pickRecipients(
        profiles: profiles,
        audience: AnnouncementAudience.barangay,
        senderId: 'admin1',
        barangay: 'Dacudao',
      ).map((p) => p.userId);
      expect(ids, ['f2', 'f3']);
    });

    test('barangay with none chosen reaches nobody', () {
      expect(
        Announcement.pickRecipients(
          profiles: profiles,
          audience: AnnouncementAudience.barangay,
          senderId: 'admin1',
        ),
        isEmpty,
      );
    });

    test('chosen people never include admins or the sender', () {
      final ids = Announcement.pickRecipients(
        profiles: profiles,
        audience: AnnouncementAudience.selected,
        senderId: 'f1',
        selectedIds: {'admin1', 'f1', 'f3'},
      ).map((p) => p.userId);
      expect(ids, ['f3']);
    });
  });

  group('Announcement.chunk', () {
    test('splits into batches no larger than the size', () {
      final chunks = Announcement.chunk(List.generate(450, (i) => i), 200);
      expect(chunks.map((c) => c.length), [200, 200, 50]);
      expect(Announcement.chunk(<int>[], 200), isEmpty);
    });
  });

  group('Announcement map', () {
    test('toMap writes exactly the fields the security rules allow', () {
      const announcement = Announcement(
        announcementId: '',
        title: 'Market day',
        body: 'Bring your produce on Saturday.',
        audience: AnnouncementAudience.barangay,
        barangay: 'Dacudao',
        recipientCount: 2,
        sentBy: 'admin1',
        sentByName: 'Researcher',
      );
      final map = announcement.toMap();
      expect(map.keys.toSet(), {
        'title',
        'body',
        'audience',
        'barangay',
        'recipientCount',
        'sentBy',
        'sentByName',
        'createdAt',
      });
      expect(map['audience'], 'barangay');
    });

    test('fromMap falls back safely', () {
      final a = Announcement.fromMap('x', {'audience': 'unknown'});
      expect(a.audience, AnnouncementAudience.all);
      expect(a.recipientCount, 0);
      expect(a.title, '');
    });
  });
}
