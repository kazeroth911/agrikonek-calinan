import 'dart:math';

import 'package:agrikonek_calinan/models/listing.dart';
import 'package:agrikonek_calinan/services/admin_account_service.dart';
import 'package:agrikonek_calinan/services/listing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Listing _listing({String status = 'active', DateTime? availableTo}) =>
    Listing(
      listingId: 'l1',
      ownerId: 'o1',
      ownerName: 'Ana',
      ownerBarangay: 'Wangan',
      title: 'Durian',
      category: 'Fruits',
      status: status == 'active' ? ListingStatus.active : ListingStatus.closed,
      availableTo: availableTo,
    );

void main() {
  group('ListingRepository.isOpenForFeed', () {
    final now = DateTime(2026, 10, 23, 15);

    test('active listings with no end date stay in the feed', () {
      expect(ListingRepository.isOpenForFeed(_listing(), now), isTrue);
    });

    test('closed listings leave the feed', () {
      expect(
          ListingRepository.isOpenForFeed(_listing(status: 'closed'), now),
          isFalse);
    });

    test('the "available until" day counts until midnight', () {
      final today = _listing(availableTo: DateTime(2026, 10, 23));
      final yesterday = _listing(availableTo: DateTime(2026, 10, 22));
      expect(ListingRepository.isOpenForFeed(today, now), isTrue);
      expect(ListingRepository.isOpenForFeed(yesterday, now), isFalse);
    });
  });

  group('AdminAccountService.generateStarterPassword', () {
    test('uses only unambiguous characters and the requested length', () {
      final password = AdminAccountService.generateStarterPassword();
      expect(password.length, 8);
      for (final c in password.split('')) {
        expect(AdminAccountService.passwordAlphabet.contains(c), isTrue);
      }
    });

    test('is not repeated across calls', () {
      final passwords = {
        for (var i = 0; i < 50; i++)
          AdminAccountService.generateStarterPassword()
      };
      expect(passwords.length, 50);
    });

    test('accepts an injected random source', () {
      final a = AdminAccountService.generateStarterPassword(random: Random(1));
      final b = AdminAccountService.generateStarterPassword(random: Random(1));
      expect(a, b);
    });
  });
}
