import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../features/notifications/notification_router.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final navigatorKey = GlobalKey<NavigatorState>();
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _initialized = false;

  String? _currentToken;
  String? _registeredUid;
  String? _registeredToken;

  Future<void> initialize() async {
    if (_initialized ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    _initialized = true;

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (kDebugMode) {
        debugPrint(
          'FCM permission: ${settings.authorizationStatus}',
        );
      }

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Push tapped while the app was in the background.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

      // Push tapped while the app was closed (cold start).
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        unawaited(_handleTap(initialMessage));
      }

      // Get the current token without printing the token itself.
      _currentToken = await messaging.getToken();

      if (kDebugMode) {
        debugPrint('FCM token available: ${_currentToken != null}');
      }

      // Register a new token whenever Firebase refreshes it.
      messaging.onTokenRefresh.listen((newToken) async {
        _currentToken = newToken;

        final user = _auth.currentUser;
        if (user == null) return;

        try {
          await _registerToken(user, newToken);
        } catch (error) {
          debugPrint('FCM token refresh sync failed: $error');
        }
      });

      // This also handles a user who signs in after app startup.
      _auth.authStateChanges().listen((user) async {
        try {
          if (user == null) {
            // Backup cleanup if the auth session ends without the
            // normal sign-out cleanup completing first.
            final uid = _registeredUid;
            final token = _registeredToken ?? _currentToken;

            if (uid != null && token != null) {
              final deleted = await _deleteToken(uid, token);

              if (deleted &&
                  _registeredUid == uid &&
                  _registeredToken == token) {
                _registeredUid = null;
                _registeredToken = null;
              }
            }

            return;
          }

          final token = _currentToken ?? await messaging.getToken();

          if (token == null || token.isEmpty) return;

          _currentToken = token;
          await _registerToken(user, token);
        } catch (error) {
          debugPrint('FCM auth-state token sync failed: $error');
        }
      });

      if (kDebugMode) {
        debugPrint('FCM service initialized.');
      }
    } catch (error) {
      _initialized = false;
      debugPrint('FCM initialization failed: $error');
    }
  }

  Future<void> _registerToken(User user, String token) async {
    final oldUid = _registeredUid;
    final oldToken = _registeredToken;

    // Remove the previous registration if the account or token changed.
    if (oldUid != null &&
        oldToken != null &&
        (oldUid != user.uid || oldToken != token)) {
      await _deleteToken(oldUid, oldToken);
    }

    await _tokenDocument(user.uid, token).set(
      {
        'token': token,
        'platform': 'android',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    _currentToken = token;
    _registeredUid = user.uid;
    _registeredToken = token;

    if (kDebugMode) {
      debugPrint('FCM token registered for signed-in user.');
    }
  }

  /// Removes this device's token registration before normal sign-out.
  /// Failures are logged but must not prevent the user from signing out.
  Future<void> unregisterCurrentDeviceToken() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final uid = _registeredUid ?? _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final token = _registeredToken ??
          _currentToken ??
          await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) return;

      final deleted = await _deleteToken(uid, token);

      if (deleted && _registeredUid == uid && _registeredToken == token) {
        _registeredUid = null;
        _registeredToken = null;
      }
    } catch (error) {
      debugPrint('FCM sign-out cleanup failed: $error');
    }
  }

  Future<bool> _deleteToken(String uid, String token) async {
    try {
      await _tokenDocument(uid, token).delete();
      return true;
    } catch (error) {
      debugPrint('FCM token removal failed: $error');
      return false;
    }
  }

  DocumentReference<Map<String, dynamic>> _tokenDocument(
    String uid,
    String token,
  ) {
    // Base64 URL encoding produces a path-safe, repeatable document ID.
    final tokenId = base64Url.encode(utf8.encode(token)).replaceAll('=', '');

    return _db
        .collection(AppConstants.colDeviceTokens)
        .doc(uid)
        .collection('tokens')
        .doc(tokenId);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'AgriKonek';
    final body = message.notification?.body ?? 'You have a new notification.';

    if (kDebugMode) {
      debugPrint('Foreground FCM received: $title');
    }

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 7),
        content: Text('$title\n$body'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _handleTap(message),
        ),
      ),
    );
  }

  /// Marks the record read and opens the bid or barter it is about.
  /// Falls back to the inbox when the push has no screen to open.
  Future<void> _handleTap(RemoteMessage message) async {
    try {
      // On a cold start the saved sign-in may still be loading.
      final user = _auth.currentUser ??
          await _auth
              .authStateChanges()
              .firstWhere((u) => u != null)
              .timeout(const Duration(seconds: 10), onTimeout: () => null);
      if (user == null) return;

      final data = Map<String, dynamic>.from(message.data);
      final notificationId = (data['notificationId'] ?? '').toString();
      if (notificationId.isNotEmpty) {
        try {
          await _db
              .collection(AppConstants.colNotifications)
              .doc(notificationId)
              .update({'read': true});
        } catch (error) {
          debugPrint('Could not mark tapped notification read: $error');
        }
      }

      final navigator = await _waitForNavigator();
      if (navigator == null) return;

      final opened = openNotificationTarget(
        navigator,
        type: (data['type'] ?? '').toString(),
        payload: data,
      );
      if (!opened) navigator.pushNamed('/notifications');
    } catch (error) {
      debugPrint('Opening tapped notification failed: $error');
    }
  }

  Future<NavigatorState?> _waitForNavigator() async {
    for (var i = 0; i < 20; i++) {
      final navigator = navigatorKey.currentState;
      if (navigator != null) return navigator;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }
}
