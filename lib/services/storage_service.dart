// Storage is deferred until the project upgrades to Blaze tier.
// The stub keeps all import references valid so nothing else breaks.
class StorageService {
  Future<String> uploadFarmPhoto({
    required String uid,
    required dynamic file,
  }) async {
    throw UnimplementedError(
        'Storage not yet enabled. Upgrade to Blaze tier first.');
  }
}
