# Notification wording: Cebuano review sheet

The Cebuano below was written to match words the app already uses (*tanyag* = bid/offer, *baylo* = barter, *Gidawat* = accepted, *Wala gidawat* = rejected, *Gi-counter* = countered, *baligya* = listing, *pahibalo* = notice). It has **not yet been checked by a native speaker**. Please have a Cebuano-speaking team member go through each line before the app is shown to farmers.

For each row, write **OK** or a better phrasing in the last column. Keep each Cebuano title short: phones cut off long push titles.

| # | Where farmers see it | English | Cebuano | OK / suggested change |
|---|---|---|---|---|
| 1 | Push and inbox: someone bids on your listing | New cash offer | Bag-ong tanyag | |
| 2 | Push and inbox: your bid was accepted | Offer accepted | Gidawat ang tanyag | |
| 3 | Push and inbox: your bid was rejected | Offer rejected | Wala gidawat ang tanyag | |
| 4 | Push and inbox: a counter-offer on a bid | Counter offer | Counter nga tanyag | |
| 5 | Push and inbox: other bid change | Bid update | Update sa tanyag | |
| 6 | Push and inbox: someone proposes a barter | New barter proposal | Bag-ong tanyag sa baylo | |
| 7 | Push and inbox: your barter was accepted | Barter accepted | Gidawat ang baylo | |
| 8 | Push and inbox: your barter was declined | Barter declined | Wala gidawat ang baylo | |
| 9 | Push and inbox: a counter-proposal on a barter | Barter counter-proposal | Gi-counter ang baylo | |
| 10 | Push and inbox: other barter change | Barter update | Update sa baylo | |
| 11 | When a listing has no title | a listing | usa ka baligya | |
| 12 | Chat push title if the sender's name is missing | New message | Bag-ong mensahe | |
| 13 | Chat push text if the message is empty | You have a new message. | Naa kay bag-ong mensahe. | |
| 14 | Announcement push title if none was written | AgriKonek announcement | Pahibalo sa AgriKonek | |
| 15 | Announcement push text if none was written | Open the app to read it. | Ablihi ang app aron mabasa. | |
| 16 | Any other notification | You have a new notification. | Naa kay bag-ong pahibalo. | |
| 17 | Android Settings → Notifications (channel name) | Bids and barters | Tanyag ug baylo | |
| 18 | Push and inbox: the other party withdrew a bid | Offer withdrawn | Gibawi ang tanyag | |
| 19 | Push and inbox: the other party withdrew a barter | Barter withdrawn | Gibawi ang baylo | |

Not translated on purpose: listing titles, peso amounts, people's names, chat messages and announcement text written by researchers. Those are shown exactly as typed.

## On-screen labels added on 1 November 2026

These make the screens in the paper's figures bilingual. Same instructions: write **OK** or a better phrasing.

| # | Screen | English | Cebuano | OK / suggested change |
|---|---|---|---|---|
| L1 | Sign in | Password / Sign in | Pasword / Mo-login | |
| L2 | Marketplace title | Calinan Marketplace | Merkado | |
| L3 | Listing detail title | Listing | Baligya | |
| L4 | Post a listing | Post a Listing / Edit Listing | Mag-post og Baligya / Usba ang Baligya | |
| L5 | Post a listing | What are you selling? | Unsa imong ibaligya? | |
| L6 | Post a listing | Price / Per unit / Description | Presyo / Matag / Paghulagway | |
| L7 | Post a listing | Leave blank if barter only | Ayaw butangi kung baylo lang | |
| L8 | Post a listing | Availability / From / Until / Photos | Kanus-a available / Gikan / Hangtod / Mga litrato | |
| L9 | Listing owner | Re-open Listing / Delete Listing | Ablihi pag-usab / Papasa | |
| L10 | My listings | Sold / Expired / Active | Nabaligya / Lapas na / Aktibo | |
| L11 | Bid and barter | Send this offer? / Send | Ipadala ang tanyag? / Ipadala | |
| L12 | Bid and barter | Withdraw my offer | Bawion | |
| L13 | Barter | Decline | Balibari | |
| L14 | Status | Withdrawn | Gibawi | |
| L15 | Profiles | Visited by researchers | Gibisita sa mga researcher | |
| L16 | Profiles | Cooperative-confirmed | Gikumpirma sa kooperatiba | |
| L17 | Listing map | Approximate area only | Gibanabana lang nga lugar | |
| L18 | Learn | Learn / Lessons are coming soon | Kat-onan / Umaabot pa ang mga leksyon | |
| L19 | Researcher screens | Profile a Farmer / Profiled Accounts | I-profile ang Mag-uuma / Mga na-profile | |
| L20 | Chat | About | Bahin sa | |

The four bottom tabs (Market, Bids, Barter, Messages) stay in English: two languages do not fit in a tab label on small phones.

## Changing a line

Every line lives in two files that must match exactly:

- `functions/notification_text.js` (the phone push)
- `lib/features/notifications/notification_text.dart` (the in-app inbox)

Row 17 lives in `android/app/src/main/kotlin/com/agrikonek/agrikonek_calinan/MainActivity.kt`.

After editing, run `npm test` in `functions` (it fails if the two files disagree) and `flutter test` in the project root, then update the expected text in `functions/test/notification_text.test.js` and `test/models/app_notification_test.dart` if those tests name the line you changed.
