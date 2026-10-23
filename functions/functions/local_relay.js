// FOR TESTING ON THE SPARK PLAN ONLY.
//
// Spark cannot deploy Cloud Functions, so this script does the
// sendPushOnNotification job from a laptop: it watches the LIVE project's
// /notifications collection and sends the FCM push for each new record,
// using the same push_sender.js code the Cloud Function uses.
// Pushes only go out while this window stays open.
//
// Usage (PowerShell, from the functions folder):
//   $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\Users\Aaron\firebase-keys\kalinan-app.json"
//   npm run relay -- kalinan-app
//
// The key file gives full admin access to the project. Keep it OUTSIDE
// the project folder, never commit or share it, and delete the key in the
// Google Cloud console once testing is done.

"use strict";

const fs = require("node:fs");
const path = require("node:path");
const {initializeApp, applicationDefault} = require("firebase-admin/app");
const {getFirestore, FieldValue, Timestamp} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

const {sendPushForNotification} = require("./push_sender");

function fail(message) {
  console.error(`\n${message}\n`);
  process.exit(1);
}

const projectId = process.argv[2];
if (!projectId) fail("Name the project: npm run relay -- kalinan-app");

const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!keyPath || !fs.existsSync(keyPath)) {
  fail("Set GOOGLE_APPLICATION_CREDENTIALS to the service-account key file first.");
}

const projectRoot = path.resolve(__dirname, "..");
const resolvedKey = path.resolve(keyPath);
if (resolvedKey.toLowerCase().startsWith(projectRoot.toLowerCase() + path.sep)) {
  fail("The key file is inside the project folder, where it could be committed.\n" +
    "Move it somewhere else (for example C:\\Users\\<you>\\firebase-keys) and try again.");
}

let keyProject;
try {
  keyProject = JSON.parse(fs.readFileSync(resolvedKey, "utf8")).project_id;
} catch (e) {
  fail(`Could not read the key file: ${e.message}`);
}
if (keyProject !== projectId) {
  fail(`The key is for "${keyProject}", but you asked for "${projectId}".`);
}

initializeApp({credential: applicationDefault(), projectId});
const db = getFirestore();
const deps = {
  db,
  messaging: getMessaging(),
  serverTimestamp: () => FieldValue.serverTimestamp(),
  log: {
    info: (msg, meta) => console.log(new Date().toLocaleTimeString(), msg, meta || ""),
    warn: (msg, meta) => console.warn(new Date().toLocaleTimeString(), "WARN", msg, meta || ""),
  },
};

// Only records created after the relay starts, so old ones are not re-sent.
const startedAt = Timestamp.now();
const inFlight = new Set();

console.log(`Relay running for ${projectId}. Waiting for new notifications... (Ctrl+C to stop)`);

db.collection("notifications")
  .where("createdAt", ">=", startedAt)
  .onSnapshot(
    (snapshot) => {
      for (const change of snapshot.docChanges()) {
        if (change.type !== "added") continue;
        const doc = change.doc;
        const data = doc.data();
        if (data.pushStatus || inFlight.has(doc.id)) continue;
        inFlight.add(doc.id);
        sendPushForNotification(doc.ref, doc.id, data, deps)
          .catch((e) => console.error("Send failed:", doc.id, e.message))
          .finally(() => inFlight.delete(doc.id));
      }
    },
    (error) => fail(`Listening stopped: ${error.message}`),
  );
