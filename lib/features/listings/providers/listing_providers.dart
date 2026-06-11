import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/listing.dart';
import '../../../models/profile.dart';
import '../../../services/listing_repository.dart';
import '../../auth/providers/auth_providers.dart';

// ---- Repository -------------------------------------------------------
final listingRepositoryProvider = Provider<ListingRepository>(
    (ref) => ListingRepository(ref.watch(firestoreProvider)));

// ---- Feed filters (UI state) -------------------------------------------
/// null = "All" chip selected.
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

// ---- Streams -------------------------------------------------------------
/// One Firestore subscription feeds every chip/search combination —
/// category and keyword are applied client-side below, so switching
/// filters never re-reads documents (free-tier read protection).
final listingFeedProvider = StreamProvider<List<Listing>>(
    (ref) => ref.watch(listingRepositoryProvider).watchFeed());

/// The feed the marketplace screen actually renders: category chip +
/// keyword search applied over the live stream.
final filteredFeedProvider = Provider<AsyncValue<List<Listing>>>((ref) {
  final feed = ref.watch(listingFeedProvider);
  final category = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider);

  return feed.whenData((listings) {
    var result = listings;
    if (category != null) {
      result = result.where((l) => l.category == category).toList();
    }
    return ListingRepository.filterByKeyword(result, query);
  });
});

final listingDetailProvider = StreamProvider.family<Listing?, String>(
    (ref, listingId) =>
        ref.watch(listingRepositoryProvider).watchListing(listingId));

/// The signed-in user's own listings (any status) for self-management.
final myListingsProvider = StreamProvider<List<Listing>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const <Listing>[]);
  return ref.watch(listingRepositoryProvider).watchListingsByOwner(user.uid);
});

// ---- Distance preview (display only, per panel decision) -----------------
/// The listing owner's profile — one read, cached by family argument,
/// used for the farm location on the detail screen.
final ownerProfileProvider = FutureProvider.family<Profile?, String>(
    (ref, ownerId) => ref.watch(profileRepositoryProvider).getProfile(ownerId));

/// Straight-line distance in km between this device and the listing
/// owner's consented farm location. Returns null whenever anything is
/// missing (no consent/GPS on profile, permission denied, no fix) —
/// the UI simply hides the distance line. Display only: proximity
/// matching was removed from scope by the panel.
final listingDistanceKmProvider =
    FutureProvider.family<double?, String>((ref, ownerId) async {
  final owner = await ref.watch(ownerProfileProvider(ownerId).future);
  final farm = owner?.farmLocation;
  if (farm == null) return null;

  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition();
    final meters = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, farm.latitude, farm.longitude);
    return meters / 1000.0;
  } catch (_) {
    return null; // GPS off / timeout — distance is a nicety, never an error
  }
});
