# Phone sign-in and profile claiming

This is the step in paper §3.5.4 where a farmer who joined a separately consented testing phase signs in with their phone number and takes over the profile a researcher prepared during the farm visit.

## How it works

1. On the sign-in screen the farmer taps **Use phone number instead**, enters the number and the SMS code.
2. The new phone account has no profile yet, so the app looks for researcher-prepared profiles whose **mobile number** is the same verified number.
3. The farmer confirms "Is this you?" (or picks one, if family members share the phone).
4. In one batch, the app copies the prepared profile to the phone account and marks the original as claimed.
5. The profile stays **hidden** until the farmer turns it on in My profile, or a researcher unhides it, as the testing-phase consent allows.

The paper's design does steps 2 to 4 in a Cloud Function. Here the **security rules** check the same conditions instead, so it works on the free Spark plan:

- the prepared profile's phone number equals the number Firebase verified;
- it is not yet claimed and is not a researcher account;
- the copy is identical to the prepared profile except for the claim fields (nobody can raise their own verification level or roles while claiming);
- the copy and the "claimed" mark are written together.

The original email account of a claimed profile shows "This profile now signs in with a phone number" if anyone signs in to it. Researchers can delete that account in the Firebase console later.

One phone number is one Firebase account. If two family members share a phone, only one of them can sign in with it; the other keeps the researcher-made email account.

## One-time Firebase setup

1. Firebase console → Authentication → Sign-in method → enable **Phone**.
2. Project settings → your Android app → add the **SHA-1 and SHA-256** fingerprints of your debug key. Get them with:

   ```powershell
   cd android
   .\gradlew signingReport
   cd ..
   ```

3. **For testing without SMS:** Authentication → Sign-in method → Phone → *Phone numbers for testing* → add a number and code (for example `+639171112222` / `123456`). Use the same number in the researcher's profiling form. Test numbers need no SMS and work on the Spark plan.
4. Sending **real SMS** codes may require the Blaze plan, depending on Firebase's current SMS policy. Check the Firebase pricing page before relying on it in the field.
5. Deploy the updated rules: `firebase deploy --only firestore:rules --project kalinan-app`.

## Trying it

1. As a researcher, profile a farmer with a test phone number (for example `09171112222`).
2. Sign out. Tap **Use phone number instead**, enter `09171112222`, then the test code.
3. The app shows the prepared profile. Tap **YES, THIS IS ME**. The marketplace opens.
4. In the researcher's Profiled Accounts list, the prepared profile now says "Moved to a phone sign-in", and the new one says "Signs in by phone (claimed)".
