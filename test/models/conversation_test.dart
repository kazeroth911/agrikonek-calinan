import 'package:agrikonek_calinan/models/conversation.dart';
import 'package:agrikonek_calinan/models/message.dart';
import 'package:agrikonek_calinan/services/chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Conversation', () {
    test('idFor is the same whichever user starts the chat', () {
      expect(Conversation.idFor('bUser', 'aUser'), 'aUser_bUser');
      expect(Conversation.idFor('aUser', 'bUser'), 'aUser_bUser');
    });

    test('toMap writes exactly the fields the security rules allow', () {
      const conversation = Conversation(
        conversationId: 'aUser_bUser',
        participantIds: ['aUser', 'bUser'],
        participantNames: {'aUser': 'Ana', 'bUser': 'Ben'},
        unreadCounts: {'aUser': 0, 'bUser': 0},
        relatedListingId: 'lst1',
        relatedListingTitle: 'Durian',
      );
      final map = conversation.toMap();
      expect(map.keys.toSet(), {
        'participantIds',
        'participantNames',
        'lastMessage',
        'lastSenderId',
        'unreadCounts',
        'relatedListingId',
        'relatedListingTitle',
        'updatedAt',
      });
      expect(map['lastMessage'], isNull);
    });

    test('fromMap reads unread counts and finds the other participant', () {
      final conversation = Conversation.fromMap('aUser_bUser', {
        'participantIds': ['aUser', 'bUser'],
        'participantNames': {'aUser': 'Ana', 'bUser': 'Ben'},
        'lastMessage': 'Hello',
        'lastSenderId': 'aUser',
        'unreadCounts': {'aUser': 0, 'bUser': 3},
      });
      expect(conversation.otherParticipant('aUser'), 'bUser');
      expect(conversation.nameOf('bUser'), 'Ben');
      expect(conversation.unreadFor('bUser'), 3);
      expect(conversation.unreadFor('aUser'), 0);
      expect(conversation.lastSenderId, 'aUser');
    });

    test('handles an empty map defensively', () {
      final conversation = Conversation.fromMap('x', {});
      expect(conversation.participantIds, isEmpty);
      expect(conversation.otherParticipant('aUser'), '');
      expect(conversation.nameOf('aUser'), 'AgriKonek user');
      expect(conversation.unreadFor('aUser'), 0);
    });
  });

  group('Message', () {
    test('toMap writes exactly the fields the security rules allow', () {
      const message = Message(
        messageId: '',
        conversationId: 'aUser_bUser',
        senderId: 'aUser',
        text: 'Pila ang durian?',
        readBy: ['aUser'],
      );
      final map = message.toMap();
      expect(map.keys.toSet(),
          {'senderId', 'text', 'attachmentUrl', 'sentAt', 'readBy'});
      expect(map['attachmentUrl'], isNull);
      expect(map['readBy'], ['aUser']);
    });
  });

  group('ChatRepository.preview', () {
    test('keeps short messages and shortens long ones to the rule limit', () {
      expect(ChatRepository.preview('Hello'), 'Hello');
      final long = 'a' * 500;
      final preview = ChatRepository.preview(long);
      expect(preview.length, Conversation.previewLength);
      expect(preview.endsWith('...'), isTrue);
    });
  });
}
