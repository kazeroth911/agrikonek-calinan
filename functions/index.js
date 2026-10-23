// AgriKonek Calinan Cloud Functions.
//
// DFD process 6.0 (Send Notification): the app first writes a record to
// /notifications. This function is triggered by that write and sends the
// FCM push to every registered device of the recipient. The record is
// therefore always saved before the push leaves the system, and the
// in-app inbox still works if a push is lost.
//
// Requires the Blaze plan (Cloud Functions cannot be deployed on Spark).

"use strict";

const {setGlobalOptions} = require("firebase-functions/v2");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

const {describe} = require("./notification_text");

initializeApp();

// The trigger must run in the same region as the Firestore database.
// Change this if the project's database is not in asia-southeast1
// (Firebase console > Firestore > the location shown under the database name).
// maxInstances caps cost for the pilot.
setGlobalOptions({region: "asia-southeast1", maxInstances: 5});

// Must match the channel created in android/.../MainActivity.kt.
const ANDROID_CHANNEL_ID = "agrikonek_alerts";

// FCM error codes meaning the token will never work again.
const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

// IDs the app needs to open the right screen when the push is tapped.
// FCM data values must be strings.
const LINK_KEYS = ["offerId", "barterId", "listingId", "conversationId"];

exports.sendPushOnNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const notificationId = event.params.notificationId;
    const data = snap.data() || {};
    const recipientId = data.recipientId;
    const type = typeof data.type === "string" ? data.type : "admin";
    const payload = data.payload && typeof data.payload === "object" ? data.payload : {};

    if (typeof recipientId !== "string" || recipientId === "") {
      logger.warn("Notification has no recipient", {notificationId});
      await snap.ref.update({pushStatus: "invalid", pushedAt: FieldValue.serverTimestamp()});
      return;
    }

    const db = getFirestore();
    const tokenSnaps = await db
      .collection("deviceTokens")
      .doc(recipientId)
      .collection("tokens")
      .get();

    const tokenDocs = tokenSnaps.docs.filter((d) => typeof d.get("token") === "string");
    if (tokenDocs.length === 0) {
      // Normal when the recipient has not signed in on a phone yet.
      await snap.ref.update({pushStatus: "no_device", pushedAt: FieldValue.serverTimestamp()});
      return;
    }

    const {title, body} = describe(type, payload);
    const linkData = {notificationId, type};
    for (const key of LINK_KEYS) {
      if (typeof payload[key] === "string" && payload[key] !== "") {
        linkData[key] = payload[key];
      }
    }

    const response = await getMessaging().sendEachForMulticast({
      tokens: tokenDocs.map((d) => d.get("token")),
      notification: {title, body},
      data: linkData,
      android: {
        priority: "high",
        notification: {channelId: ANDROID_CHANNEL_ID},
      },
    });

    // Remove registrations for uninstalled apps or expired tokens.
    const deletions = [];
    response.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error && r.error.code;
        logger.warn("FCM send failed", {notificationId, code});
        if (DEAD_TOKEN_CODES.has(code)) deletions.push(tokenDocs[i].ref.delete());
      }
    });
    await Promise.all(deletions);

    // Delivery result kept on the record for testing evidence.
    // Admin SDK writes bypass the security rules, so the recipient-only
    // update rule is unaffected.
    await snap.ref.update({
      pushStatus: response.successCount > 0 ? "sent" : "failed",
      pushSuccessCount: response.successCount,
      pushFailureCount: response.failureCount,
      pushedAt: FieldValue.serverTimestamp(),
    });

    logger.info("Push processed", {
      notificationId,
      type,
      sent: response.successCount,
      failed: response.failureCount,
      pruned: deletions.length,
    });
  },
);
