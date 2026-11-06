// Widget tests for the key widgets named in paper §3.11 (layer 2):
// listing cards, the bid dialog, the barter composer and message bubbles.
// Each is built on its own, with no Firebase connection.
import 'package:agrikonek_calinan/core/l10n/app_language.dart';
import 'package:agrikonek_calinan/core/theme/app_theme.dart';
import 'package:agrikonek_calinan/features/auth/providers/auth_providers.dart';
import 'package:agrikonek_calinan/features/chat/screens/chat_screen.dart';
import 'package:agrikonek_calinan/features/listings/widgets/listing_card.dart';
import 'package:agrikonek_calinan/features/offers/screens/place_bid_sheet.dart';
import 'package:agrikonek_calinan/features/offers/screens/propose_barter_sheet.dart';
import 'package:agrikonek_calinan/models/listing.dart';
import 'package:agrikonek_calinan/models/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for a signed-in Firebase user; only the uid is used.
class _FakeUser implements User {
  @override
  String get uid => 'buyer1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _durian = Listing(
  listingId: 'l1',
  ownerId: 'seller1',
  ownerName: 'Ana Cruz',
  ownerBarangay: 'Wangan',
  title: 'Durian',
  category: 'Fruits',
  price: 120,
  unit: 'kg',
  modes: [ListingMode.sale, ListingMode.barter],
);

const _compost = Listing(
  listingId: 'l2',
  ownerId: 'seller1',
  ownerName: 'Ana Cruz',
  ownerBarangay: 'Wangan',
  title: 'Compost',
  category: 'Compost & By-products',
  modes: [ListingMode.barter],
);

/// Builds [child] the way the app does: theme, chosen language, and a
/// provider scope whose signed-in user is [user].
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  User? user,
  AppLanguage language = AppLanguage.english,
}) async {
  tester.view.physicalSize = const Size(1080, 2400); // 360 x 800 phone
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    authStateProvider.overrideWith((ref) => Stream<User?>.value(user)),
  ]);
  addTearDown(container.dispose);
  // Resolve the signed-in user before the widget reads it.
  container.listen(authStateProvider, (_, __) {});
  await container.read(authStateProvider.future);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      builder: (context, page) =>
          LanguageScope(language: language, child: page!),
      home: Scaffold(body: child),
    ),
  ));
  await tester.pump();
}

void main() {
  group('Listing card', () {
    testWidgets('shows title, price, seller, category and barter tag',
        (tester) async {
      var tapped = false;
      await _pump(
          tester, ListingCard(listing: _durian, onTap: () => tapped = true));

      expect(find.text('Durian'), findsOneWidget);
      expect(find.text('₱120 / kg'), findsOneWidget);
      expect(find.text('Ana Cruz · Wangan'), findsOneWidget);
      expect(find.text('Fruits'), findsOneWidget);
      expect(find.text('Open to barter'), findsOneWidget);

      await tester.tap(find.byType(ListingCard));
      expect(tapped, isTrue);
    });

    testWidgets('a barter-only listing in Cebuano says Baylo',
        (tester) async {
      await _pump(tester, ListingCard(listing: _compost, onTap: () {}),
          language: AppLanguage.cebuano);

      expect(find.text('Baylo'), findsOneWidget);
      expect(find.text('Abono ug uban pa'), findsOneWidget);
      expect(find.text('Pwede i-baylo'), findsOneWidget);
    });
  });

  group('Bid dialog', () {
    testWidgets('shows the asking price and refuses an invalid amount',
        (tester) async {
      await _pump(tester, const PlaceBidSheet(listing: _durian));
      await tester.pumpAndSettle();

      expect(find.text('Place a Bid'), findsOneWidget);
      expect(find.text('Asking price: ₱120 / kg'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'abc');
      await tester.ensureVisible(find.text('SEND BID'));
      await tester.tap(find.text('SEND BID'));
      await tester.pump();

      expect(find.text('Enter a valid amount'), findsOneWidget);
    });
  });

  group('Barter composer', () {
    testWidgets('starts with the listing as the item wanted', (tester) async {
      await _pump(tester, const ProposeBarterSheet(listing: _durian),
          user: _FakeUser());

      expect(find.text('Propose a Barter'), findsOneWidget);
      expect(find.text('You give'), findsOneWidget);
      expect(find.text('You receive'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Durian'), findsOneWidget);
    });

    testWidgets('asks for something to offer before sending', (tester) async {
      await _pump(tester, const ProposeBarterSheet(listing: _durian),
          user: _FakeUser());

      await tester.ensureVisible(find.text('SEND PROPOSAL'));
      await tester.tap(find.text('SEND PROPOSAL'));
      await tester.pump();

      expect(find.text('Add at least one item you are offering.'),
          findsOneWidget);
      // No confirmation dialog: nothing is sent.
      expect(find.text('Send this proposal?'), findsNothing);
    });
  });

  group('Message bubble', () {
    testWidgets('my message sits on the right; theirs on the left',
        (tester) async {
      await _pump(
        tester,
        Column(children: [
          MessageBubble(
            mine: true,
            message: Message(
              messageId: 'm1',
              conversationId: 'c1',
              senderId: 'buyer1',
              text: 'Pwede pa ba?',
              sentAt: DateTime(2026, 11, 1, 9, 30),
            ),
          ),
          const MessageBubble(
            mine: false,
            message: Message(
              messageId: 'm2',
              conversationId: 'c1',
              senderId: 'seller1',
              text: 'Oo, naa pa.',
            ),
          ),
        ]),
      );

      final aligns = tester
          .widgetList<Align>(find.descendant(
              of: find.byType(MessageBubble), matching: find.byType(Align)))
          .toList();
      expect(aligns.first.alignment, Alignment.centerRight);
      expect(aligns.last.alignment, Alignment.centerLeft);
      expect(find.text('Pwede pa ba?'), findsOneWidget);
      // A message not yet confirmed by the server says so.
      expect(find.text('Sending...'), findsOneWidget);
    });
  });
}
