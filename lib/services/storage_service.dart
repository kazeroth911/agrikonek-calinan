import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';

/// Cloud Storage uploads for listing and profile photos.
///
/// GUARDED BY DESIGN: Storage only works once the Firebase project is on
/// Blaze tier. Every public method here is best-effort — if the bucket is
/// unreachable (still on Spark, no network, rules deny), the method returns
/// whatever succeeded instead of throwing, so a farmer can still post a
/// listing without photos rather than losing the whole form.
class StorageService {
  StorageService([FirebaseStorage? storage]) : _storage = storage;

  // Lazily resolved so constructing the service never throws, even when
  // the Storage plugin/bucket is not yet usable.
  final FirebaseStorage? _storage;

  FirebaseStorage get _instance => _storage ?? FirebaseStorage.instance;

  /// Uploads listing photos under listings/{ownerUid}/.
  /// Returns the download URLs of the photos that made it; an empty list
  /// means Storage is unavailable and the listing should post photo-less.
  Future<List<String>> uploadListingPhotos({
    required String ownerUid,
    required List<File> files,
  }) {
    return _uploadAll(
      folder: '${AppConstants.storageListingsFolder}/$ownerUid',
      files: files,
    );
  }

  /// Uploads farm/consent photos captured during researcher profiling
  /// under profiles/{uid}/.
  Future<List<String>> uploadProfilePhotos({
    required String uid,
    required List<File> files,
  }) {
    return _uploadAll(
      folder: '${AppConstants.storageProfilesFolder}/$uid',
      files: files,
    );
  }

  Future<List<String>> _uploadAll({
    required String folder,
    required List<File> files,
  }) async {
    final urls = <String>[];
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < files.length; i++) {
      try {
        final ref = _instance.ref('$folder/${stamp}_$i.jpg');
        await ref.putFile(
          files[i],
          SettableMetadata(contentType: 'image/jpeg'),
        );
        urls.add(await ref.getDownloadURL());
      } catch (e) {
        // One failure means the bucket is effectively down (Spark tier,
        // offline, rules) — skip the remaining files instead of stalling
        // the form on each retry.
        debugPrint('StorageService: upload failed, continuing without '
            'remaining photos: $e');
        break;
      }
    }
    return urls;
  }
}
