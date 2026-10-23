# Running the automated tests

AgriKonek has three test suites. Run all three before a release and record each total for the paper.

| Suite | What it checks | Where | Command (from the project root) |
|---|---|---|---|
| Flutter unit tests | Models, validators, search, negotiation rules, notification wording, recipient picking, listing expiry, passwords | `test/` | `flutter test` |
| Cloud Function tests | Push wording, the send logic, dead-token clean-up, and that push and inbox wording match | `functions/test/` | `cd functions; npm test; cd ..` |
| Security-rule tests | Who may read and write each collection: bids, barters, listings, chat, notifications, hiding, announcements | `firestore-tests/` | see below |

## Security-rule tests

These run `firestore.rules` in Firebase's local emulator, on a throwaway project called `demo-agrikonek`, so they never touch the real `kalinan-app` data.

### One-time setup

1. **Java 21.** The Firestore emulator needs Java. Install the Temurin 21 LTS build from https://adoptium.net (Windows x64 `.msi`, and tick "Set JAVA_HOME"). Open a new PowerShell window and check with `java -version`.
2. **Test packages:**

```powershell
cd firestore-tests
npm install
cd ..
```

### Run

```powershell
firebase emulators:exec --only firestore --project demo-agrikonek "npm --prefix firestore-tests test"
```

The first run downloads the emulator (about 60 MB). Every test should pass. A failure names the rule that let through, or blocked, something it should not have. If that happens, send the output to whoever maintains the rules.

### What the tests cover

- **Listings:** a farmer can post only under their own name and can never hand a listing to someone else. Negative prices are refused.
- **Bids and barters:** the seller must be the listing's real owner, and nobody can bid on their own or a closed listing. Accepting your own bid or proposal is refused, while countering is allowed. History can only grow by one entry per move. Accepted and rejected are final. Only the two parties can read a bid.
- **Notifications:** only a party to the bid, barter or chat can notify the other party. Only admins can send announcements, and only the recipient can read a notification or mark it read.
- **Chat:** a thread's ID must be the two sorted user IDs. Outsiders cannot read or send, and messages cannot be edited.
- **Profile hiding:** a hidden profile is readable only by its owner and admins. It receives no new bids or messages, and only the owner or an admin can hide it.
- **Profiles and announcements:** farmers cannot make themselves admin or change their consent record. Only admins can read the announcement history.

## Storage rules

`storage.rules` is deployed with `firebase deploy --only storage --project kalinan-app`, which needs Cloud Storage, and therefore the Blaze plan. The first deploy asks to let Storage read Firestore (used to recognize researcher-admins); answer yes.
