// End-to-end flows against the Firebase Emulator Suite (paper §3.11,
// layer 3): sign-in, profile claiming, posting a listing, placing a bid,
// accepting a barter, and sending a message. They use the app's own
// controllers and repositories, so the security rules in firestore.rules
// check every write, exactly as on a phone.
//
// Nothing here touches the real kalinan-app data: Auth and Firestore are
// pointed at the local emulators before anything else runs, and the
// emulators are wiped at the start. See docs/TESTING.md for how to run.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agrikonek_calinan/features/admin/providers/profiling_providers.dart';
import 'package:agrikonek_calinan/features/auth/providers/auth_providers.dart';
import 'package:agrikonek_calinan/features/chat/providers/chat_providers.dart';
import 'package:agrikonek_calinan/features/listings/providers/listing_providers.dart';
import 'package:agrikonek_calinan/features/offers/providers/barter_providers.dart';
import 'package:agrikonek_calinan/features/offers/providers/offer_providers.dart';
import 'package:agrikonek_calinan/firebase_options.dart';
import 'package:agrikonek_calinan/models/barter_proposal.dart';
import 'package:agrikonek_calinan/models/conversation.dart';
import 'package:agrikonek_calinan/models/listing.dart';
import 'package:agrikonek_calinan/models/offer.dart';
import 'package:agrikonek_calinan/models/profile.dart';
import 'package:agrikonek_calinan/services/admin_account_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The laptop running the emulators. 10.0.2.2 from the Android emulator;
/// pass --dart-define=EMULATOR_HOST=<laptop Wi-Fi IP> for a real phone.
const _host =
    String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');

const _password = 'test1234';
const _sellerEmail = 'ana.seller@agrikonek.test';
const _buyerEmail = 'ben.buyer@agrikonek.test';
const _adminEmail = 'researcher@agrikonek.test';
const _farmerPhone = '+639171112222';

late ProviderContainer container;
bool _ready = false;
late String projectId;

String adminUid = '';
String sellerUid = '';
String buyerUid = '';
late Listing listing;

// ---- emulator helpers -------------------------------------------------------

Future<Map<String, dynamic>> _http(String method, int port, String path,
    {Object? body, bool owner = false}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, Uri.http('$_host:$port', path));
    request.headers.contentType = ContentType.json;
    // "Bearer owner" lets the test seed data past the security rules, as
    // the emulator allows. Only used to create the first researcher.
    if (owner) request.headers.set('Authorization', 'Bearer owner');
    if (body != null) request.write(jsonEncode(body));
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 300) {
      throw StateError('$method $path -> ${response.statusCode}: $text');
    }
    if (text.isEmpty) return {};
    final decoded = jsonDecode(text.trim().startsWith('{') ? text : '{}');
    return decoded as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

Future<void> _wipeEmulators() async {
  try {
    await _http('GET', 8080, '/');
  } on SocketException catch (e) {
    throw StateError(
        'Cannot reach the Firestore emulator at $_host:8080 ($e).\n'
        'Is "firebase emulators:start --only auth,firestore" running? On a '
        'real phone, pass the laptop\'s Wi-Fi address with '
        '--dart-define=EMULATOR_HOST=<IPv4 from ipconfig> (see docs/TESTING.md).');
  }
  await _http('DELETE', 8080,
      '/emulator/v1/projects/$projectId/databases/(default)/documents');
  await _http('DELETE', 9099, '/emulator/v1/projects/$projectId/accounts');
}

/// The SMS code the Auth emulator "sent" to [phone].
Future<String> _smsCodeFor(String phone) async {
  final json = await _http(
      'GET', 9099, '/emulator/v1/projects/$projectId/verificationCodes');
  final codes = (json['verificationCodes'] as List? ?? const [])
      .cast<Map<String, dynamic>>()
      .where((c) => c['phoneNumber'] == phone)
      .toList();
  if (codes.isEmpty) throw StateError('No code was sent to $phone');
  return codes.last['code'] as String;
}

// ---- sign-in helpers ----------------------------------------------------------

/// Waits until the app's own auth state (the provider every screen reads)
/// shows [uid], or nobody when [uid] is null.
Future<void> _authStateIs(String? uid) async {
  for (var i = 0; i < 100; i++) {
    if (container.read(authStateProvider).valueOrNull?.uid == uid) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw TimeoutException('Auth state never became $uid');
}

Future<String> _signIn(String email) async {
  await FirebaseAuth.instance.signOut();
  final credential = await container
      .read(authServiceProvider)
      .signInWithEmail(email: email, password: _password);
  final uid = credential.user!.uid;
  await _authStateIs(uid);
  return uid;
}

Future<String> _signInWithPhone(String phone) async {
  await FirebaseAuth.instance.signOut();
  final sent = Completer<String>();
  await FirebaseAuth.instance.verifyPhoneNumber(
    phoneNumber: phone,
    verificationCompleted: (_) {},
    verificationFailed: (e) {
      if (!sent.isCompleted) sent.completeError(e);
    },
    codeSent: (verificationId, _) {
      if (!sent.isCompleted) sent.complete(verificationId);
    },
    codeAutoRetrievalTimeout: (_) {},
  );
  final verificationId = await sent.future.timeout(const Duration(seconds: 30));
  final code = await _smsCodeFor(phone);
  final credential = await container.read(authServiceProvider).confirmSmsCode(
      verificationId: verificationId, smsCode: code);
  final uid = credential.user!.uid;
  await _authStateIs(uid);
  return uid;
}

Profile _draft(String name, String barangay, {String? phone}) => Profile(
      userId: '',
      fullName: name,
      roles: const ['seller', 'buyer'],
      barangay: barangay,
      phone: phone,
      consentGiven: true,
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The Firebase plugin rewrites 127.0.0.1 and localhost to 10.0.2.2 on
  // Android, so they cannot reach a laptop from a real phone.
  assert(_host != '127.0.0.1' && _host != 'localhost',
      'Use the laptop\'s Wi-Fi address for EMULATOR_HOST, not $_host.');

  setUpAll(() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    projectId = Firebase.app().options.projectId;

    // Emulators first, before any read or write.
    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: false);
    FirebaseFirestore.instance.useFirestoreEmulator(_host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(_host, 9099);
    AdminAccountService.authEmulatorHost = _host;
    await FirebaseAuth.instance
        .setSettings(appVerificationDisabledForTesting: true);

    await _wipeEmulators();

    container = ProviderContainer();
    container.listen(authStateProvider, (_, __) {});
    _ready = true;

    // The first researcher-admin is seeded directly, as in the console.
    final admin = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _adminEmail, password: _password);
    adminUid = admin.user!.uid;
    await _http(
      'PATCH',
      8080,
      '/v1/projects/$projectId/databases/(default)/documents/profiles/$adminUid',
      owner: true,
      body: {
        'fields': {
          'fullName': {'stringValue': 'Researcher'},
          'barangay': {'stringValue': 'Wangan'},
          'roles': {
            'mapValue': {
              'fields': {
                'admin': {'booleanValue': true},
                'seller': {'booleanValue': false},
              }
            }
          },
        }
      },
    );
  });

  tearDownAll(() async {
    if (!_ready) return; // setUpAll failed; its error is the one to read
    await FirebaseAuth.instance.signOut();
    container.dispose();
  });

  testWidgets('1. Sign-in: a researcher-prepared farmer signs in by email',
      (tester) async {
    await _signIn(_adminEmail);
    final profiling = container.read(profilingControllerProvider);
    final repo = container.read(profileRepositoryProvider);

    final seller = await profiling.saveNewFarmer(
        draft: _draft('Ana Cruz', 'Wangan'),
        email: _sellerEmail,
        starterPassword: _password);
    final buyer = await profiling.saveNewFarmer(
        draft: _draft('Ben Reyes', 'Riverside'),
        email: _buyerEmail,
        starterPassword: _password);
    // Prepared profiles are hidden; the testing phase makes these visible.
    await repo.setHidden(uid: seller.uid, hidden: false, byUid: adminUid);
    await repo.setHidden(uid: buyer.uid, hidden: false, byUid: adminUid);

    sellerUid = await _signIn(_sellerEmail);
    final profile = await repo.getProfile(sellerUid);
    expect(profile?.fullName, 'Ana Cruz');
    expect(profile?.verificationLevel, Profile.levelVisited);
    expect(profile?.isAdmin, isFalse);
  });

  testWidgets('2. Profile claiming: a phone sign-in takes over its profile',
      (tester) async {
    await _signIn(_adminEmail);
    final prepared = await container.read(profilingControllerProvider)
        .saveNewFarmer(
            draft: _draft('Carla Santos', 'Biao Joaquin', phone: _farmerPhone),
            email: 'carla@agrikonek.test',
            starterPassword: _password);

    final phoneUid = await _signInWithPhone(_farmerPhone);
    final repo = container.read(profileRepositoryProvider);
    final matches = await repo.findClaimableProfiles(
        e164Phone: _farmerPhone, uid: phoneUid);
    expect(matches.map((d) => d.id), [prepared.uid]);

    await repo.claimProfile(prepared: matches.single, uid: phoneUid);

    final mine = await repo.getProfile(phoneUid);
    expect(mine?.fullName, 'Carla Santos');
    expect(mine?.claimedFrom, prepared.uid);
    expect(mine?.hidden, isTrue, reason: 'stays hidden until shown');
    final original = await repo.getProfile(prepared.uid);
    expect(original?.claimedBy, phoneUid);
    // The claimed profile is no longer offered to anyone.
    expect(
        await repo.findClaimableProfiles(
            e164Phone: _farmerPhone, uid: phoneUid),
        isEmpty);
  });

  testWidgets('3. Posting a listing: it appears in the marketplace feed',
      (tester) async {
    sellerUid = await _signIn(_sellerEmail);
    final listings = container.read(listingRepositoryProvider);
    final id = await listings.createListing(Listing(
      listingId: '',
      ownerId: sellerUid,
      ownerName: 'Ana Cruz',
      ownerBarangay: 'Wangan',
      title: 'Durian (Puyat)',
      category: 'Fruits',
      price: 120,
      unit: 'kg',
      modes: const [ListingMode.sale, ListingMode.barter],
    ));
    listing = Listing.fromDoc(
        await FirebaseFirestore.instance.collection('listings').doc(id).get());

    final feed = await listings.watchFeed().first;
    expect(feed.map((l) => l.listingId), contains(id));
    expect(listing.ownerId, sellerUid);
  });

  testWidgets('4. Placing a bid: the seller sees it and accepts',
      (tester) async {
    buyerUid = await _signIn(_buyerEmail);
    final offers = container.read(offerControllerProvider);
    await offers.placeBid(
        listing: listing, buyerId: buyerUid, amount: 100, message: 'Sabado?');

    final open = await offers.findOpenOffer(
        listingId: listing.listingId, buyerId: buyerUid);
    expect(open, isNotNull);
    expect(open!.status, OfferStatus.pending);
    expect(open.amount, 100);

    await _signIn(_sellerEmail);
    final fresh = Offer.fromDoc(await FirebaseFirestore.instance
        .collection('offers')
        .doc(open.offerId)
        .get());
    await offers.accept(offer: fresh, byUserId: sellerUid);
    final accepted = Offer.fromDoc(await FirebaseFirestore.instance
        .collection('offers')
        .doc(open.offerId)
        .get());
    expect(accepted.status, OfferStatus.accepted);
  });

  testWidgets('5. Accepting a barter: the owner accepts the proposal',
      (tester) async {
    buyerUid = await _signIn(_buyerEmail);
    await container.read(barterControllerProvider).propose(
      listing: listing,
      proposerId: buyerUid,
      offeredItems: const [BarterItem(name: 'Compost', quantity: 2, unit: 'sack')],
      requestedItems: const [BarterItem(name: 'Durian', quantity: 5, unit: 'kg')],
    );
    final sent = await FirebaseFirestore.instance
        .collection('barterProposals')
        .where('proposerId', isEqualTo: buyerUid)
        .where('listingId', isEqualTo: listing.listingId)
        .get();
    expect(sent.docs, hasLength(1));
    final barterId = sent.docs.single.id;

    await _signIn(_sellerEmail);
    final proposal = BarterProposal.fromDoc(await FirebaseFirestore.instance
        .collection('barterProposals')
        .doc(barterId)
        .get());
    await container
        .read(barterControllerProvider)
        .accept(proposal: proposal, byUserId: sellerUid);
    final after = BarterProposal.fromDoc(await FirebaseFirestore.instance
        .collection('barterProposals')
        .doc(barterId)
        .get());
    expect(after.status, BarterStatus.accepted);
  });

  testWidgets('6. Sending a message: the seller receives it', (tester) async {
    buyerUid = await _signIn(_buyerEmail);
    final chat = container.read(chatControllerProvider);
    final conversationId = await chat.openChat(
      otherId: sellerUid,
      otherName: 'Ana Cruz',
      listingId: listing.listingId,
      listingTitle: listing.title,
    );
    final conversation = Conversation.fromDoc(await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .get());
    await chat.send(conversation: conversation, text: 'Pwede pa ba ang durian?');

    await _signIn(_sellerEmail);
    final messages = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .get();
    expect(messages.docs.map((d) => d.data()['text']),
        contains('Pwede pa ba ang durian?'));
  });
}
