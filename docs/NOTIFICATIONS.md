# Notifications: how they work, deploy, and test

This covers DFD process 6.0 (Send Notification) and the in-app notification center.

## 1. How a notification travels

```
Buyer taps "Place bid"
  │
  ├─ 1. OfferController.placeBid writes /offers/{id}            (offer_providers.dart)
  ├─ 2. NotificationRepository.notify writes /notifications/{id} (notification_repository.dart)
  │      recipientId, senderId, type, payload, read=false, createdAt
  │      Security rules check that the sender is really the buyer
  │      or seller of that offer before allowing the write.
  │
  ├─ 3. Cloud Function sendPushOnNotification runs on that new record (functions/index.js)
  │      reads /deviceTokens/{recipientId}/tokens/*
  │      sends the FCM push on channel "agrikonek_alerts"
  │      deletes tokens FCM reports as dead
  │      writes pushStatus back onto the record (sent | no_device | failed)
  │
  └─ 4. Seller's phone
         app closed or in background → Android shows the push; tapping it opens that offer
         app open → a snackbar with "View" appears; the bell badge count goes up
         Notifications screen → list of all records, tap one to open it, "mark all read"
```

The record is always saved before the push is sent. If a push is lost (no signal in the field, phone off), the farmer still sees it in the inbox the next time they open the app.

## 2. Which file does what

| File | Job |
|---|---|
| `lib/services/push_notification_service.dart` | Asks for notification permission, saves this phone's FCM token under the signed-in user, removes it on sign-out, handles taps and foreground pushes |
| `lib/services/notification_repository.dart` | Writes, streams and marks notification records as read |
| `lib/models/app_notification.dart` | Record shape: `recipientId`, `senderId`, `type` (bid, barter, msg, admin), `payload`, `read`, `createdAt` |
| `lib/features/notifications/notification_text.dart` | Title and body wording for the inbox |
| `functions/notification_text.js` | Same wording for the phone push. **Change both files together.** |
| `lib/features/notifications/notification_router.dart` | Opens the offer or barter a notification is about |
| `lib/features/notifications/screens/notifications_screen.dart` | Inbox |
| `lib/features/notifications/widgets/notification_bell.dart` | Bell with unread count on Market, Bids, Barter and Researcher screens |
| `lib/services/chat_repository.dart` | Chat threads and messages in Firestore |
| `lib/features/chat/` | Messages tab, chat screen, Message buttons; each sent message writes a `msg` notification |
| `functions/index.js` | Cloud Function that sends the push (Blaze) |
| `functions/push_sender.js` | The send logic itself, shared by the function and the relay |
| `functions/local_relay.js` | Laptop stand-in for the function while on Spark (testing only) |
| `firestore.rules` | Who may create, read and mark notifications; who may save device tokens |
| `android/.../MainActivity.kt` | Creates the "Bids and barters" Android notification channel |

## 3. Deploy (once, by the Firebase project owner)

Cloud Functions need the **Blaze** plan. Confirm it is active and the budget alert is set before deploying.

1. Install Node.js 22 LTS and the Firebase CLI: `npm install -g firebase-tools`, then `firebase login`.
2. Check the Firestore location: Firebase console → Firestore Database. If it is **not** `asia-southeast1`, change the `region` in `functions/index.js` to match.
3. Deploy to the same project the app uses. On the `firebase-kalinan-testing` branch the app connects to `kalinan-app` (see `lib/firebase_options.dart`), but `.firebaserc` still defaults to `agrikonek-calinan`. A deploy to the wrong project does nothing for the app. From the project folder:

```powershell
cd functions
npm install
npm test
cd ..
firebase deploy --only firestore:rules,functions --project kalinan-app
```

4. In the Firebase console → Functions, confirm `sendPushOnNotification` appears.

Deploy the rules and the app update together. The new rules reject notification records without `senderId`, so an older app build's notifications would be refused (the bid itself still saves).

## 3b. Testing on Spark: the laptop relay

While the project stays on Spark, the Cloud Function cannot be deployed. `functions/local_relay.js` does its job from a laptop instead: it watches the live project's notifications and sends each push, using the same `push_sender.js` code. Pushes only go out while the relay window stays open.

One-time setup:

1. Firebase console → Project settings (gear) → **Service accounts** → **Generate new private key**. This downloads a JSON key.
2. Move it **outside** the project folder, for example `C:\Users\Aaron\firebase-keys\kalinan-app.json`. The relay refuses to start if the key is inside the project. Never commit, upload or share this file: it gives full admin access to the project.

Each test session (PowerShell):

```powershell
cd functions
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\Users\Aaron\firebase-keys\kalinan-app.json"
npm run relay -- kalinan-app
```

Leave that window open, then run the test in section 4. Each new record gets `pushStatus` and a "Push processed" line in the relay window (use that window instead of the Functions logs in step 7). Press Ctrl+C to stop.

When testing is finished, delete the key: Google Cloud console → IAM & Admin → Service accounts → the `firebase-adminsdk` account → Keys → delete it.

## 4. Test on two phones (or one phone and one emulator with Google Play)

Use test accounts only. A is the seller, B is the buyer.

1. Install the new build on both. Sign in. Allow notifications when asked (Android 13 and up).
2. In Firestore, check `deviceTokens/{A's uid}/tokens` has one document.
3. **App closed:** close the app on A. On B, place a bid on A's listing. A should get "New cash offer" with the listing and amount. Tap it: the offer opens.
4. **App open:** keep A on the Market screen. On B, counter. A sees a snackbar and the bell count goes up.
5. **Inbox:** on A, open the bell. The newest item is on top and bold. Tap it: it opens and turns normal. Try "mark all read".
6. **Barter:** repeat step 3 with a barter proposal.
7. **Evidence:** in Firestore, each record now has `pushStatus: "sent"`. In Firebase console → Functions → Logs (or the relay window on Spark), there is a "Push processed" line per record. Screenshot both for the paper.
8. **Sign-out:** sign out on A. Its token document disappears. A new bid now gives `pushStatus: "no_device"` and no push.
9. **Rules:** in the Firestore Rules Playground, try creating a notification as a user who is not part of the offer. It must be denied.

## 4b. Test chat

Use the same two accounts, with the relay running on Spark.

1. **Start a chat:** on B (buyer), open A's listing and tap **Message / Mensahe**. The chat opens with "About: <listing>" at the top.
2. **Send:** B types a message and sends. It appears at once, then its time replaces "Sending...".
3. **Push:** with A's app closed, A gets a push titled with B's name and the message text. Tapping it opens the chat.
4. **Badge:** with A's app open on Market, the **Messages** tab shows an unread count. Opening the chat clears it, and the matching bell notifications turn read.
5. **No double alert:** while A has that chat open, a new message from B appears in the chat without a snackbar.
6. **From a bid or barter:** open an offer or barter and tap the chat icon at the top right. It opens the same thread with that person.
7. **Rules:** in the Rules Playground, as a third user, try reading `conversations/<A_B id>/messages` and creating a message there. Both must be denied.

## 5. What is not covered yet

- `admin` announcements are allowed for admins only, but there is no screen to write one yet.
- Push wording is English only. A Cebuano version should be checked by a Cebuano speaker before it is added.
- Chat is text only (no photos), and messages cannot be edited or deleted.
- iOS is not set up.
