// Sends the FCM push for one /notifications record (DFD process 6.0).
// Shared by the Cloud Function (index.js) and the laptop test relay
// (local_relay.js), so both run exactly the same logic.
//
// Dependencies are passed in, so this file can be unit-tested without
// Firebase: deps = {db, messaging, serverTimestamp, log}.

"use strict";

const {describe, normalizeLanguage} = require("./notification_text");

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

/**
 * @param {FirebaseFirestore.DocumentReference} ref the notification record
 * @param {string} notificationId
 * @param {Record<string, any>} data the record's fields
 * @param {{db: any, messaging: any, serverTimestamp: () => any, log: any}} deps
 * @returns {Promise<string>} the pushStatus written to the record
 */
async function sendPushForNotification(ref, notificationId, data, deps) {
  const {db, messaging, serverTimestamp, log} = deps;
  const recipientId = data.recipientId;
  const type = typeof data.type === "string" ? data.type : "admin";
  const payload = data.payload && typeof data.payload === "object" ? data.payload : {};

  if (typeof recipientId !== "string" || recipientId === "") {
    log.warn("Notification has no recipient", {notificationId});
    await ref.update({pushStatus: "invalid", pushedAt: serverTimestamp()});
    return "invalid";
  }

  const tokenSnaps = await db
    .collection("deviceTokens")
    .doc(recipientId)
    .collection("tokens")
    .get();

  const tokenDocs = tokenSnaps.docs.filter((d) => typeof d.get("token") === "string");
  if (tokenDocs.length === 0) {
    // Normal when the recipient has not signed in on a phone yet.
    await ref.update({pushStatus: "no_device", pushedAt: serverTimestamp()});
    return "no_device";
  }

  const linkData = {notificationId, type};
  for (const key of LINK_KEYS) {
    if (typeof payload[key] === "string" && payload[key] !== "") {
      linkData[key] = payload[key];
    }
  }

  // Each phone saved the language chosen in the app's Settings with its
  // token. Send one batch per language so every phone gets its own wording.
  const byLanguage = new Map();
  for (const doc of tokenDocs) {
    const language = normalizeLanguage(doc.get("language"));
    if (!byLanguage.has(language)) byLanguage.set(language, []);
    byLanguage.get(language).push(doc);
  }

  let successCount = 0;
  let failureCount = 0;
  const deletions = [];
  for (const [language, docs] of byLanguage) {
    const {title, body} = describe(type, payload, language);
    const response = await messaging.sendEachForMulticast({
      tokens: docs.map((d) => d.get("token")),
      notification: {title, body},
      data: linkData,
      android: {
        priority: "high",
        notification: {channelId: ANDROID_CHANNEL_ID},
      },
    });
    successCount += response.successCount;
    failureCount += response.failureCount;

    // Remove registrations for uninstalled apps or expired tokens.
    response.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error && r.error.code;
        log.warn("FCM send failed", {notificationId, code});
        if (DEAD_TOKEN_CODES.has(code)) deletions.push(docs[i].ref.delete());
      }
    });
  }
  await Promise.all(deletions);

  // Delivery result kept on the record for testing evidence.
  // Admin SDK writes bypass the security rules, so the recipient-only
  // update rule is unaffected.
  const pushStatus = successCount > 0 ? "sent" : "failed";
  await ref.update({
    pushStatus,
    pushSuccessCount: successCount,
    pushFailureCount: failureCount,
    pushedAt: serverTimestamp(),
  });

  log.info("Push processed", {
    notificationId,
    type,
    sent: successCount,
    failed: failureCount,
    pruned: deletions.length,
  });
  return pushStatus;
}

module.exports = {sendPushForNotification, ANDROID_CHANNEL_ID};
