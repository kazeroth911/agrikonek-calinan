// AgriKonek Calinan Cloud Functions.
//
// DFD process 6.0 (Send Notification): the app first writes a record to
// /notifications. This function is triggered by that write and sends the
// FCM push to every registered device of the recipient. The record is
// therefore always saved before the push leaves the system, and the
// in-app inbox still works if a push is lost.
//
// Requires the Blaze plan (Cloud Functions cannot be deployed on Spark).
// While the project is on Spark, local_relay.js runs the same logic from
// a laptop for testing.

"use strict";

const {setGlobalOptions} = require("firebase-functions/v2");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

const {sendPushForNotification} = require("./push_sender");

initializeApp();

// The trigger must run in the same region as the Firestore database.
// Change this if the project's database is not in asia-southeast1
// (Firebase console > Firestore > the location shown under the database name).
// maxInstances caps cost for the pilot.
setGlobalOptions({region: "asia-southeast1", maxInstances: 5});

exports.sendPushOnNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    await sendPushForNotification(snap.ref, event.params.notificationId, snap.data() || {}, {
      db: getFirestore(),
      messaging: getMessaging(),
      serverTimestamp: () => FieldValue.serverTimestamp(),
      log: logger,
    });
  },
);
