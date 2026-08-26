# AgriKonek Calinan Capstone Study Guide

**Working system title:** *AgriKonek Calinan: A Mobile Marketplace and Connectivity Application for Pre-profiled Smallholder Farmers in Calinan District, Davao City*

**Basis of this guide:** direct review of the Flutter/Firebase repository on 5 August 2026, successful execution of all 49 automated tests, successful Flutter static analysis, and selected government, academic, and official technical sources.

> **Important thesis-integrity note:** The repository contains the application but not the approved manuscript, survey instrument, respondent dataset, usability results, or complete field-test records. Statements about farmer income, market access improvement, acceptance, effectiveness, or respondent satisfaction must therefore use the actual thesis data. Do not invent percentages or claim that the app improved livelihoods based only on software tests.

## The 30-second explanation

AgriKonek Calinan is an Android-oriented mobile marketplace for pre-profiled farmers, buyers, and traders in Calinan District. A researcher-admin creates verified user profiles; users then post agricultural products, search the live marketplace, submit cash bids or barter proposals, and negotiate through controlled accept, reject, and counter actions. Flutter provides the interface, Riverpod manages application state, and Firebase handles authentication, real-time records, and photo storage. The present prototype passes 49 unit tests and static analysis, but chat, push notifications, end-to-end Firebase testing, and field-based usability evaluation are not yet fully demonstrated in the repository.

---

# 1. Introduction

## 1.1 Background of the study

Agriculture remains structurally important in the Davao Region. The Philippine Statistics Authority reported 484,125 farms in operation in the region in the 2022 Census of Agriculture and Fisheries and an average farm size of 1.03 hectares, showing the relevance of tools designed for small-scale producers ([PSA, 2025](https://rsso11.psa.gov.ph/content/agricultural-farm-and-parcel-characteristics-davao-region-based-2022-census-agriculture-and)). At the same time, Philippine digital-agriculture research identifies online marketplaces as promising tools while warning that connectivity, device access, digital skills, and inclusion can limit adoption ([Briones, Galang, & Latigar, 2023](https://doi.org/10.62986/dp2023.29)).

AgriKonek Calinan responds to this setting with a locally scoped mobile marketplace. It does not scrape information from websites. Its records originate from researcher-led profiling and from listings, offers, and barter proposals entered by authenticated users. This distinction should be stated clearly because it defines the study's data source, privacy obligations, and implementation method.

## 1.2 Problem statement

The defensible problem is not simply that “farmers have no market.” A more precise statement is:

> Smallholder farmers may have limited visibility beyond their immediate contacts, while potential buyers and traders may lack one organized, local channel for discovering available farm products and negotiating cash or barter exchanges. General online marketplaces are not designed around researcher-verified farmer profiles, Calinan barangays, agricultural units, produce categories, optional farm-distance display, and turn-based barter or bid negotiation.

The project addresses the **information and coordination gap**. It does not, by itself, solve transport, quality inspection, payment, pricing policy, connectivity, or production constraints.

## 1.3 General objective

To design and develop a mobile marketplace that connects pre-profiled smallholder farmers, buyers, and traders in Calinan District through agricultural listings, searchable discovery, cash bidding, and barter negotiation.

## 1.4 Suggested specific objectives

Use these only if they agree with the approved manuscript:

1. Create and manage consent-based profiles for farmers, buyers, and traders.
2. Allow authenticated users to post agricultural listings with descriptions, categories, units, availability, prices, barter options, and photos.
3. Provide a searchable and categorized real-time marketplace.
4. Support cash offers and barter proposals with recorded negotiation histories.
5. Apply role- and ownership-based access controls to profiles, listings, offers, barter proposals, and media.
6. Assess the software's functional correctness through automated testing and, when field data are available, assess its usability or quality using the approved evaluation instrument.

## 1.5 Scope and delimitations

The repository supports an Android Flutter application backed by Firebase. Its implemented core covers authentication, researcher-admin profiling, marketplace listings, search and category filtering, listing photos, optional distance preview, bids, barter proposals, negotiation histories, and notification document creation.

The scope should not be overstated. Current repository evidence does not establish online payment, delivery or logistics, price forecasting, product inspection, web scraping, automated matching, a completed chat interface, a completed push-notification center, a working auction flow, an iOS release, or measured economic impact. The `auction` type and conversation models exist, but the corresponding full workflows do not.

## 1.6 Significance of the study

- **Farmers:** gain a structured channel for displaying products and considering cash or barter proposals.
- **Buyers and traders:** gain searchable access to local listings and direct negotiation with listing owners.
- **Researchers or administrators:** gain a consent-based profiling workflow and structured records for the pilot community.
- **Local stakeholders:** gain a prototype that can be evaluated for future coordination, training, and market-linkage programs.
- **Future researchers:** gain an implementation baseline for usability, adoption, security, logistics, and impact studies.

---

# 2. Review of Related Literature (RRL)

## 2.1 How to organize the RRL

Do not write one unrelated paragraph per source. Organize the chapter by themes, compare findings, identify limitations, and end with the gap addressed by AgriKonek. Table 1 provides a compact synthesis structure and should be introduced in the manuscript with a sentence such as: **“Table 1 synthesizes the literature according to the problem addressed, major finding, limitation, and relevance to the proposed system.”**

**Table 1. Suggested RRL synthesis matrix**

| Theme and source | Main evidence | Limitation or warning | Link to AgriKonek |
|---|---|---|---|
| Davao agricultural context — PSA (2025) | Davao Region recorded 484,125 farms in the 2022 CAF; average farm size was 1.03 ha. | Regional data do not prove the conditions of AgriKonek's exact Calinan participants. | Establishes regional relevance; local profiling remains necessary. |
| Philippine digital agriculture — Briones et al. (2023) | Digital tools may support productivity, market access, and sustainability. | Digital divide may exclude vulnerable users; many tools remain early-stage. | Supports researcher-assisted onboarding and collection of device/data-plan information. |
| Mobile technology and market participation — Nwangwu et al. (2024) | A 360-farmer study found mobile phones and radio influenced market participation and market-information access. | Evidence is from southeast Nigeria, not Calinan; context must not be generalized uncritically. | Supports testing a mobile channel while requiring local evaluation. |
| Mobile marketplace experiment — Bergquist and McIntosh (2021) | A Ugandan mobile marketplace increased trade and reduced price divergence. | Smaller farmers had difficulty reaching the scale needed to attract buyers; broad income effects were not significant for most. | Warns against claiming that an app automatically improves every farmer's income. |
| Privacy and consent — Republic Act No. 10173 | Personal data processing requires a lawful basis and gives data subjects rights to information, access, correction, and certain forms of removal. | A checked consent box alone is not a complete privacy program. | Supports informed profiling, data minimization, controlled location capture, and access rules. |
| Reactive mobile architecture — Flutter and Riverpod documentation | Declarative UI maps application state to interface state; providers encapsulate observable state. | Framework architecture does not prove usability or impact. | Explains the responsive interface and state separation used by the implementation. |
| Firebase real-time and security documentation | Snapshot listeners deliver current data and later updates; Authentication and Security Rules authorize mobile/web access. | Rules are not filters and must validate authorized queries and writes. | Supports the repository/stream design and highlights the need for rule tests. |

## 2.2 Ready-to-adapt synthesis

The literature supports the potential of mobile technology to reduce information and search barriers, but it does not justify assuming universal benefit. Nwangwu et al. (2024) found a relationship between ICT tools and market participation among smallholders, while Bergquist and McIntosh (2021) showed that a mobile marketplace could increase trade but that smaller producers might still struggle to reach buyers. In the Philippine setting, Briones et al. (2023) similarly describe the promise of online marketplaces while emphasizing digital-divide risks. These findings suggest that a useful local system should combine market discovery with assisted onboarding, simple interaction, low-data design decisions, and local validation. AgriKonek operationalizes that direction through pre-profiled accounts, Calinan-specific barangays, agricultural categories and units, image-light listing cards, and cash and barter negotiation. Its contribution is therefore a context-specific prototype and evaluation opportunity—not proof that technology alone resolves structural agricultural-market problems.

## 2.3 Research gap

The gap should be framed locally and modestly:

> Existing studies establish the potential and limitations of digital agricultural marketplaces, but the reviewed literature does not provide a Calinan-specific application combining researcher-verified profiles, locally categorized listings, direct cash bidding, structured barter proposals, and consent-based optional location data. AgriKonek addresses this design and implementation gap and creates a prototype that can be evaluated with its intended users.

Avoid the unsupported claim that “no similar system exists.” Say instead that the reviewed sources did not show the same combination in the target context.

---

# 3. Methodology

## 3.1 Separate two kinds of methodology

The paper should distinguish **system-development methodology** from **research/evaluation methodology**.

- The repository supports describing an iterative, feature-based development process: profiling, marketplace, and negotiation features are explicitly organized in sprints, followed by unit testing and static analysis.
- The repository does not reveal the final respondent sampling method, number of participants, questionnaire, statistical treatment, or field-test procedure. Insert these only from the approved research protocol.

A safe wording is:

> The proponents used an iterative development approach in which the application was divided into feature increments: account and farmer profiling, marketplace listings, and bid/barter negotiation. Each increment separated interface, state-management, repository, and data-model responsibilities. Pure business rules were subjected to automated unit tests, while the complete system was checked through Flutter static analysis. User evaluation, sampling, and statistical treatment followed the separately approved research protocol [insert the actual method here].

## 3.2 Frameworks and technologies

Table 2 should be cited in the framework paragraph: **“As summarized in Table 2, the system combines a Flutter interface with Riverpod state coordination and Firebase-managed authentication, records, and media.”**

**Table 2. Technology framework**

| Component | Project use | Plain-language explanation |
|---|---|---|
| Flutter/Dart | Android user interface and business models | Builds screens, validates forms, and compiles the application. |
| Riverpod | Providers, streams, loading/error states, controllers | Keeps screens updated when authentication or Firestore data change. |
| Firebase Authentication | Email/password and phone OTP code paths | Confirms identity and supplies the UID used for ownership checks. |
| Cloud Firestore | Profiles, listings, offers, barter proposals, notifications | Stores structured records and sends live updates to subscribed screens. |
| Cloud Storage | Profile and listing photos | Stores image files and returns URLs saved in Firestore records. |
| Geolocator | Optional farm coordinates and display-only distance | Requests permission, reads coordinates, and calculates straight-line distance. |
| Image Picker | Camera/gallery input | Lets the researcher or user select images for upload. |
| Flutter Test/Lints | Automated checks | Verifies pure business logic and detects static code issues. |

## 3.3 Conceptual framework

**Figure 1 should be introduced before it appears:** “Figure 1 presents the study's conceptual relationship: contextual barriers and user needs motivate system functions, while user evaluation is needed to determine whether the resulting prototype is usable and acceptable.”

**Figure 1. Conceptual framework of AgriKonek Calinan**

```text
LOCAL CONTEXT AND USER NEEDS
• Limited visibility of available produce
• Search and coordination barriers
• Cash and non-cash exchange needs
• Device, connectivity, and digital-skill constraints
                 │
                 ▼
AGRIKONEK SYSTEM INTERVENTION
• Researcher-assisted, consent-based profiling
• Agricultural listing and discovery
• Cash bid and barter negotiation
• Ownership/role controls and transaction history
                 │
                 ▼
IMMEDIATE SYSTEM OUTPUTS
• Organized local marketplace records
• Visible offers and barter proposals
• Traceable negotiation status/history
• A testable mobile prototype
                 │
                 ▼
EVALUATION OUTCOMES — MUST COME FROM ACTUAL DATA
• Functional suitability • usability • reliability
• user acceptance • observed limitations
```

The framework deliberately labels the last box as evaluation-dependent. Market visibility is a system output; improved income or livelihood is a longer-term outcome that requires longitudinal or economic evidence.

## 3.4 Operational framework: Input–Process–Output

**Figure 2 should be referenced in its preceding paragraph:** “Figure 2 translates the concept into the operational Input–Process–Output sequence used to guide specific implementation.”

**Figure 2. Operational Input–Process–Output framework**

```text
INPUT
User credentials and roles
Consent and farmer profile data
Products, prices, units, availability, photos
Search terms and category selection
Cash offers or barter items
Device location, when permitted
        │
        ▼
PROCESS
Validate → authenticate → authorize
Create/read/update Firestore documents
Upload permitted images
Stream and filter active listings
Compute optional straight-line distance
Validate negotiation turn and transition
Append history and create notification record
        │
        ▼
OUTPUT
Verified user profile
Live searchable marketplace
Listing details and optional distance
Recorded cash bid or barter proposal
Accepted/rejected/countered status
Traceable negotiation history and action badge
```

Table 3 expands Figure 2 and should be discussed directly: **“Table 3 shows that every user action is mapped to a validation or authorization process and a stored or displayed output.”**

**Table 3. Operational mapping**

| User operation | Input | Main process | Output |
|---|---|---|---|
| Researcher profiles farmer | Identity, roles, products, consent, optional GPS/photos | Validate form; create secondary Auth account; upload photos; save profile at UID | Login credentials and profile record |
| User signs in | Email/password or phone/OTP | Firebase verifies credential; app watches profile | Admin or farmer interface based on role |
| Farmer posts listing | Title, category, unit, price/barter choice, dates, photos | Validate; best-effort photo upload; save listing | Active marketplace listing |
| User discovers listing | Live records, category, keyword | Stream newest records; remove closed items; filter locally | Searchable feed and detail view |
| Buyer places cash bid | Listing, amount, optional message | Create offer with buyer/seller IDs and first history entry | Pending offer and recipient notification record |
| User proposes barter | Offered/requested items and optional note | Create proposal and history entry | Pending barter proposal and notification record |
| Participant responds | Accept, reject, or counter | Check participant, turn, and legal status transition; append history | Updated status, amount/note, history, and badge |

## 3.5 How the system operates

1. Firebase initializes before the app renders. During development, an environment flag can point Auth, Firestore, and Storage to local emulators.
2. Authentication state determines whether the login screen or the application shell appears.
3. The signed-in user's profile determines role routing: an admin reaches researcher tools; other profiled users reach Market, Bids, and Barter tabs.
4. The researcher-admin creates farmer credentials without losing the admin session by using a secondary Firebase app instance.
5. The marketplace subscribes to a newest-first Firestore stream capped at 100 records. Closed listings are removed, while category and keyword filters are applied locally.
6. A listing owner can manage a listing. Another authenticated user can bid or propose a barter when that mode is available.
7. A negotiation state machine permits accept, reject, or counter only while an item is pending/countered and only for the participant whose turn it is.
8. Each action appends a history entry. Accepted and rejected records are terminal and cannot return to an earlier state through the application logic.

## 3.6 Software architecture

**Figure 3 should be referenced in text:** “Figure 3 shows the implemented separation of concerns, from Flutter screens through Riverpod coordination and repositories to Firebase services.”

**Figure 3. Implemented architecture**

```text
┌─────────────────────────────────────────────┐
│ PRESENTATION: Flutter screens and widgets   │
│ Login • Profiling • Market • Bids • Barter  │
└──────────────────────┬──────────────────────┘
                       ▼
┌─────────────────────────────────────────────┐
│ STATE/CONTROL: Riverpod                     │
│ Providers • live state • filters • actions  │
└──────────────────────┬──────────────────────┘
                       ▼
┌─────────────────────────────────────────────┐
│ DOMAIN/DATA ACCESS                          │
│ Models • repositories • transition rules    │
└──────────────────────┬──────────────────────┘
                       ▼
┌─────────────────────────────────────────────┐
│ BACK END: Firebase                          │
│ Auth • Firestore • Storage • security rules │
└─────────────────────────────────────────────┘
```

This is a layered, reactive architecture. Screens do not directly construct Firestore queries; repositories centralize data access, and Riverpod exposes the resulting streams and controller operations to the interface.

## 3.7 Database design

Table 4 should be introduced as follows: **“Table 4 lists the Firestore collections evidenced in the project and distinguishes working flows from structures reserved for later work.”**

**Table 4. Main data collections**

| Collection | Key information | Access purpose | Current status |
|---|---|---|---|
| `profiles` | Identity, role map, barangay, products, barter preference, optional GPS, consent | Role routing and farmer details | Implemented |
| `listings` | Owner, product, category, unit, price, modes, photos, dates, status | Marketplace feed and details | Implemented |
| `offers` | Listing, buyer, seller, amount, status, history | Cash negotiation | Implemented |
| `barterProposals` | Listing, proposer, owner, offered/requested items, status, history | Goods-for-goods negotiation | Implemented |
| `notifications` | Recipient, type, payload, timestamps/read state | Records events for later notification UI/FCM | Document creation implemented; full delivery UI pending |
| `conversations/{id}/messages` | Participants and messages | Direct chat | Models/rules exist; user-facing chat flow pending |

## 3.8 Implementation section: short code excerpts only

Use only excerpts that demonstrate an important decision. Explain the function before or after the excerpt; do not paste whole files.

### A. Firebase initialization and dependency scope

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
runApp(const ProviderScope(child: AgriKonekApp()));
```

This initializes the shared back end, then places `ProviderScope` above the interface so Riverpod providers can supply authentication, repositories, and live data to screens.

### B. Role-based routing

```dart
if (profile == null) return const _MissingProfileScreen();
if (profile.isAdmin) return const AdminHomeScreen();
return const _FarmerShell();
```

The interface is chosen from the authenticated user's profile. Admins receive researcher profiling tools, while other profiled users receive marketplace and negotiation tabs.

### C. Search without repeated database reads

```dart
if (category != null) {
  result = result.where((l) => l.category == category).toList();
}
return ListingRepository.filterByKeyword(result, query);
```

One live feed is reused for different search terms and category chips. For the small pilot dataset, local filtering avoids opening a new Firestore query whenever the user changes a filter.

### D. Controlled negotiation transition

```dart
if (!Offer.canTransition(offer.status, to)) {
  throw StateError('Illegal offer transition.');
}
if (to == OfferStatus.countered &&
    (counterAmount == null || counterAmount <= 0)) {
  throw StateError('A counter needs a valid amount.');
}
```

This protects terminal offers and rejects invalid counter amounts in application logic. The final production version should also validate immutable fields and legal transitions in Firestore Security Rules or trusted server code.

### E. Core negotiation algorithm

The algorithm is better shown as short black-and-white pseudocode than as a long source listing.

```text
Algorithm 1: Process a negotiation response
Input: negotiation N, acting user U, action A, optional counter value V
Output: updated negotiation or validation error

1. If U is not the buyer/proposer or seller/owner, reject.
2. If N is accepted or rejected, reject because it is terminal.
3. If U made the last recorded move, reject because it is the other party's turn.
4. If A is counter and V is invalid or empty, reject.
5. Set the new status and current amount/note.
6. Append {U, A, V, timestamp} to history.
7. Save the update and create a notification record for the other party.
```

For a formal paper, the transition rule may also be written as:

\[
T(s,a)=
\begin{cases}
\{accepted,rejected,countered\}, & s\in\{pending,countered\}\\
\varnothing, & s\in\{accepted,rejected\}
\end{cases}
\]

where \(s\) is the current state and \(a\) is the requested action.

## 3.9 Privacy and security procedure

The profiling form requires confirmation of written consent before saving and treats farm location as optional. The system uses Authentication UIDs and Firestore rules for role, ownership, and participant access. Listing photos are limited by Storage Rules to authenticated reads, owner-folder writes, image content types, and files under 2 MB.

Do not claim complete RA 10173 compliance solely because the form contains consent. A full privacy procedure should also document the purpose and retention period, authorized recipients, correction/withdrawal process, breach procedure, privacy notice, and deletion process. These correspond to lawful-processing and data-subject-rights provisions of the Data Privacy Act ([National Privacy Commission, RA 10173](https://privacy.gov.ph/data-privacy-act/)).

---

# 4. Results and Discussion

## 4.1 Rule for writing this chapter

This chapter should present observable outputs and interpret them against objectives and literature. Do not insert implementation code here unless a very short excerpt is indispensable. Screenshots, concise test tables, usability results, and a discussion of limitations are more appropriate.

## 4.2 Verified technical results

Table 5 should be referenced in the results narrative: **“As shown in Table 5, all 49 automated unit tests passed, and static analysis found no issues in the reviewed build.”**

**Table 5. Verified software checks on 5 August 2026**

| Test area | Number | Result |
|---|---:|---|
| Barter proposal model and state machine | 7 | Passed |
| Listing model and keyword filtering | 8 | Passed |
| Offer model and state machine | 7 | Passed |
| Profile conversion and role handling | 5 | Passed |
| Phone/email validators | 8 | Passed |
| Offer and barter turn/transition logic | 14 | Passed |
| **Total automated tests** | **49** | **All passed** |
| Flutter static analysis | Project-wide | **No issues found** |

These results support the narrow conclusion that the tested model conversions, validators, keyword search, turn-taking rules, and negotiation transitions behaved as expected in the automated test environment. They do not test the complete Firebase deployment, actual network interruptions, security-rule enforcement, physical-device OTP delivery, user experience, or real-world market outcomes.

## 4.3 Functional status

Table 6 should be introduced in the discussion: **“Table 6 distinguishes demonstrated core functionality from partially implemented or unverified functions, preventing the chapter from presenting planned features as completed results.”**

**Table 6. Repository-based feature status**

| Feature | Evidence-based status | Discussion |
|---|---|---|
| Email/password sign-in | Implemented | Error messages are translated into simpler English/Cebuano-style guidance. |
| Phone OTP | Code path implemented | Requires device and Firebase-provider testing before claiming deployment success. |
| Researcher-led profiling | Implemented | Captures roles, products, barter preference, device/data plan, consent, optional GPS/photos. |
| Role routing | Implemented | Admins and non-admin users receive different home interfaces. |
| Marketplace feed | Implemented | Live newest-first feed, closed-item filtering, category chips, and keyword search. |
| Post listing | Implemented | Supports sale and barter modes, unit, dates, description, and best-effort photos. |
| Straight-line distance | Implemented in code | Display-only; depends on saved farm GPS, user permission, and device location. It is not route distance. |
| Cash bidding | Implemented | Create, accept, reject, counter, history, and “Your move” badge are present. |
| Barter negotiation | Implemented | Offered/requested items and note-based counters are present. |
| Notification records | Implemented | Full FCM push delivery and in-app center are deferred. |
| Direct messaging | Partial/planned | Data models and rules exist; the listing action opens a coming-soon screen. |
| Auction workflow | Not implemented | An enum value exists, but there is no full auction posting or bidding workflow. |
| Automated unit testing | Implemented | 49 tests pass. |
| Integration, widget, rule, and field usability tests | Not demonstrated | Necessary before broader deployment claims. |

## 4.4 Discussion of design choices

The prototype responds to digital-divide concerns through several choices: accounts are seeded during researcher profiling, cards use one small thumbnail, uploads can fail without discarding the entire listing form, and marketplace filters reuse one capped feed. These choices align with the literature's warning that connectivity, device access, and support affect digital-agriculture adoption. However, the application still depends on internet-connected Firebase services for live records, so it should not be described as fully offline.

Bid and barter histories improve traceability within the application because every proposed action creates an append-style history entry. Turn-taking prevents the same party from repeatedly acting before the other responds, and accepted/rejected states are terminal in the tested application logic. This is a useful implementation result, but application-side checks should be reinforced in back-end rules before production deployment.

The current security rules restrict records by authentication, ownership, participant identity, or admin role. The review also found hardening opportunities: participant updates do not yet validate which offer/barter fields may change; any authenticated account can create a notification document; and profile-photo rules allow an authenticated writer to target any profile folder. These are appropriate limitations and future-work items, not reasons to hide the prototype's current status.

## 4.5 Where actual respondent results belong

If the team has evaluation data, add one compact table per major research question and cite each table in the paragraph immediately before it. Use this pattern:

> “Table 7 presents respondents' assessment of functional suitability. The overall mean of **[actual value]** corresponds to **[actual verbal interpretation from the approved scale]**. The strongest item was **[item]**, while **[item]** received the lowest rating, indicating that **[evidence-based interpretation]**.”

Never write “highly acceptable” unless the value, scale boundaries, sample, and instrument support that interpretation. Report respondent groups separately when the approved methodology requires it.

---

# 5. Conclusions

## 5.1 Repository-supported conclusion

AgriKonek Calinan successfully implements the core of a localized mobile agricultural marketplace: consent-based researcher profiling, authenticated role routing, searchable live listings, optional product photos and farm-distance display, and structured cash and barter negotiations. The modular Flutter/Riverpod/Firebase design separates interface, state coordination, business rules, and data access. All 49 available unit tests passed, and static analysis found no issues in the reviewed code.

The evidence supports calling the application a functioning, testable prototype for its implemented core features. It does not yet support conclusions that the system increases farmer income, eliminates intermediaries, improves market access in practice, or is accepted by the intended population; such claims require the approved field evaluation and actual respondent or transaction data. Further work should complete chat and push notifications, harden server-side validation, add security-rule and end-to-end tests, verify OTP and photo behavior on physical devices, and evaluate usability under realistic Calinan connectivity conditions.

## 5.2 One-sentence defense conclusion

> The project demonstrates that the proposed local marketplace workflow is technically feasible and that its tested business rules are correct, while real-world usability and socioeconomic impact remain questions for field evaluation rather than assumptions made from the code.

---

# 6. References

Bergquist, L. F., & McIntosh, C. (2021). *Search cost, intermediation, and trade: Experimental evidence from Ugandan agricultural markets*. https://doi.org/10.26085/C3759K

Briones, R. M., Galang, I. M. R., & Latigar, J. S. (2023). *Transforming Philippine agri-food systems with digital technology: Extent, prospects, and inclusiveness* (PIDS Discussion Paper DP 2023-29). Philippine Institute for Development Studies. https://doi.org/10.62986/dp2023.29

Firebase. (2026). *Get realtime updates with Cloud Firestore*. https://firebase.google.com/docs/firestore/query-data/listen

Firebase. (2026). *Secure data in Cloud Firestore*. https://firebase.google.com/docs/firestore/security/overview

Firebase. (2026). *Upload files with Cloud Storage on Flutter*. https://firebase.google.com/docs/storage/flutter/upload-files

Flutter. (2026). *Flutter architectural overview*. https://docs.flutter.dev/resources/architectural-overview

Flutter. (2026). *Guide to app architecture*. https://docs.flutter.dev/app-architecture/guide

National Privacy Commission. (2012). *Republic Act No. 10173: Data Privacy Act of 2012*. https://privacy.gov.ph/data-privacy-act/

Nwangwu, K. N., Onyenekwe, C. S., Opata, P. I., Ume, C. O., & Ume, N. N. C. (2024). Can digital technology promote market participation among smallholder farmers? *International Food and Agribusiness Management Review, 27*(4), 706–728. https://doi.org/10.22434/ifamr2023.0065

Philippine Statistics Authority Regional Statistical Services Office XI. (2025). *Agricultural farm and parcel characteristics of Davao Region (based on the 2022 Census of Agriculture and Fisheries)*. https://rsso11.psa.gov.ph/content/agricultural-farm-and-parcel-characteristics-davao-region-based-2022-census-agriculture-and

Riverpod. (n.d.). *Getting started*. Retrieved August 5, 2026, from https://riverpod.dev/docs/introduction/getting_started

Base the final reference list on works actually cited in the manuscript. Apply the citation style required by the school consistently.

---

# 7. Appendix

## Appendix A. What belongs in the appendix

Include supporting evidence that would interrupt the main discussion:

- selected source excerpts for critical functions, not entire files;
- test command and concise summary;
- static-analysis summary;
- questionnaire or evaluation instrument;
- informed-consent form and privacy notice, with personal data removed;
- compact data dictionary;
- additional interface screenshots;
- installation or deployment steps;
- security-rule excerpts;
- user-test tasks and anonymized result summaries.

Avoid long raw Firestore tables, complete source files, repetitive screenshots, secret keys, real phone numbers, personal coordinates, signed consent images, or Firebase credentials.

## Appendix B. Compact test evidence

```text
Command: flutter test
Result: 49 tests passed

Command: flutter analyze
Result: No issues found

Verification date: 5 August 2026
Environment: local project workspace
```

## Appendix C. Suggested screenshot set

Use a consistent phone frame and readable captions:

1. Login and OTP options.
2. Researcher profiling form and consent section.
3. Marketplace feed with search/category controls.
4. Listing creation and listing detail.
5. Cash bid detail showing status and history.
6. Barter proposal showing offered/requested items.
7. Firestore structure or Firebase console with all personal data redacted.
8. Test summary.

Every figure should be mentioned in the body before it appears. A good caption identifies what the figure proves, for example: **“Figure 6. Offer-detail screen showing the current bid, negotiation status, and append-only action history.”**

## Appendix D. Compact data dictionary

Table A1 should be referenced in the appendix text: **“Table A1 defines the principal records without reproducing long raw database exports.”**

**Table A1. Principal record identifiers and relationships**

| Record | Primary identifier | Important relationship |
|---|---|---|
| Profile | Firebase Auth UID | One profile represents the authenticated account. |
| Listing | Firestore document ID | `ownerId` links to the profile UID. |
| Offer | Firestore document ID | Links one listing, buyer UID, and seller UID. |
| Barter proposal | Firestore document ID | Links one listing, proposer UID, and owner UID. |
| Notification | Firestore document ID | `recipientId` identifies the intended account. |

---

# Technical Output Mini-Presentation for Thursday

## Recommended 8-slide sequence

Keep slides visual and sparse. The speaker notes below contain what to explain; do not place every sentence on the slide.

### Slide 1 — Title and one-line value

**On slide:** title, team, location, and one sentence: “A local mobile marketplace for profiled farmers, buyers, and traders.”

**Say:** “AgriKonek Calinan organizes local agricultural listings and supports direct cash or barter negotiation among authenticated, pre-profiled users.”

### Slide 2 — Problem and users

**On slide:** farmer, buyer/trader, researcher-admin icons; two or three short pain points.

**Say:** “We focused on an information and coordination gap: products may be available, but potential trading partners lack one structured local channel for discovery and negotiation.”

### Slide 3 — Conceptual and IPO framework

**On slide:** simplified Input → Process → Output figure.

**Say:** “Profiles, listings, search criteria, and offers enter the system. It authenticates, validates, stores, filters, and manages negotiations. It outputs a live marketplace and traceable transaction proposals.”

### Slide 4 — System architecture

**On slide:** four layers from Figure 3.

**Say:** “Flutter renders the screens, Riverpod coordinates state, repositories contain data operations and business rules, and Firebase provides identity, live records, and media storage.”

### Slide 5 — Live user workflow

**On slide:** Profile → Login → Post/Search → Bid/Barter → Respond.

**Demonstrate:** use a prepared admin account, a seller account, and a buyer account. Preload one listing and have backup screenshots in case the network fails.

### Slide 6 — Important implementation decision

**On slide:** a state diagram, not a long code block.

```text
Pending ───┬──→ Countered ───┬──→ Countered
           ├──→ Accepted     ├──→ Accepted
           └──→ Rejected     └──→ Rejected
Accepted/Rejected = terminal
```

**Say:** “Only the other party can make the next move. Accepted and rejected states are final, and every action is added to the negotiation history.”

### Slide 7 — Verified results and limitations

**On slide:** “49/49 tests passed” and “0 analyzer issues,” plus three honest limitations.

**Say:** “The verified results cover model conversion, validators, search, and negotiation rules. Chat, complete push delivery, rule integration tests, and field usability evidence remain future or separate evaluation work.”

### Slide 8 — Conclusion and next work

**On slide:** one conclusion and three next steps.

**Say:** “The prototype demonstrates technical feasibility for the core local marketplace workflow. Our next priorities are back-end rule hardening, end-to-end field testing, and completion of messaging and notification delivery.”

## Demo safety checklist

- Use test identities and fake coordinates; never show actual respondent data.
- Sign in and preload records before presenting.
- Keep screenshots or a screen recording as an offline fallback.
- Disable disruptive phone notifications.
- Test projector readability and font size.
- Demonstrate one complete path instead of every screen.
- Never call the feature “web scraping.”
- Never claim a field result that is not in the dataset.

---

# Defense Practice

## Likely questions and concise answers

### 1. What is the main contribution?

“The contribution is a Calinan-focused prototype that combines researcher-verified profiles, agricultural listing discovery, cash bidding, and structured barter negotiation in one mobile workflow.”

### 2. Why is profiling performed by a researcher instead of open registration?

“The project prioritizes a controlled pilot population and more reliable profile records. Assisted onboarding also helps users who may have limited digital familiarity. This reduces anonymous accounts, although it creates administrative work and is a scalability trade-off.”

### 3. Why Flutter?

“Flutter gives us one Dart codebase and a reactive widget model suitable for a mobile prototype. It also integrates with the Firebase packages used by the system.”

### 4. Why Firebase?

“Firebase supplies authentication, real-time document updates, and image storage without maintaining a separate custom server. That fits the prototype timeline, but it also creates internet and platform dependencies.”

### 5. Is the application offline?

“No. Some Firebase clients may cache data, but the application is designed around online authentication and live Firestore operations. We describe it as bandwidth-conscious, not fully offline.”

### 6. Does it eliminate middlemen?

“It enables direct discovery and negotiation, but we do not claim it eliminates intermediaries. Traders may also be valid users, and logistics, aggregation, financing, and trust can make intermediaries useful.”

### 7. How is barter controlled?

“The proposal records offered and requested items. Only the party who did not act last may respond. They can accept, reject, or counter with an explanatory note, and the history is preserved.”

### 8. How do you protect personal data?

“Profiling requires confirmed written consent, farm GPS is optional, authentication identifies owners, and access rules limit many records by role or participation. We also acknowledge that full compliance requires documented retention, correction, withdrawal, deletion, and breach procedures beyond the consent control.”

### 9. How is distance calculated?

“With permission, the app reads the device position and computes straight-line distance to a consented farm coordinate. It is only a display estimate, not travel time, route distance, or automatic matching.”

### 10. What do the 49 passing tests prove?

“They prove the tested validators, model conversion, keyword filtering, and negotiation rules behaved as expected. They do not prove complete deployment security, usability, or economic impact.”

### 11. What is your strongest technical design decision?

“The negotiation state machine is a strong decision because it makes allowed transitions explicit, prevents terminal records from reopening in application logic, enforces turn-taking, and retains a traceable history.”

### 12. What is the biggest current limitation?

“The biggest evidence limitation is the absence of demonstrated field and end-to-end results in the repository. Technically, messaging and push delivery are incomplete, and server-side validation should be strengthened before production use.”

### 13. Why are category and keyword filters client-side?

“The pilot expects only dozens of active listings. One capped stream is reused for all filters, reducing repeated reads and index complexity. If data volume grows, filtering and pagination should move to scalable server queries or a search service.”

### 14. Is there web scraping?

“No. Data are entered through profiling and marketplace forms, then stored in Firebase. The implementation uses real-time database listeners, not scraping.”

### 15. Can you conclude that farmer income improved?

“Not from the code or unit tests. That conclusion would require valid baseline and follow-up economic data or another appropriate impact design.”

## A strong explanation pattern

For every technical feature, answer in this order:

1. **Purpose:** What user problem does it address?
2. **Input:** What information or action enters the feature?
3. **Process:** What validation, state rule, or database operation occurs?
4. **Output:** What does the user see or what record is produced?
5. **Limitation:** What does the feature not prove or not yet cover?

Example:

> “The bid feature lets a buyer negotiate a cash amount. It receives the listing, buyer identity, amount, and optional message. The system creates a pending offer, records the first history entry, and notifies the seller. The other party may accept, reject, or counter. This supports negotiation, but it does not process payment or guarantee delivery.”

## Final rehearsal priorities

Know these without reading:

- the exact problem and target users;
- the difference between conceptual and operational frameworks;
- the full Input–Process–Output flow;
- why there is no web scraping;
- why Riverpod and repositories are separate from screens;
- the offer/barter transition rule;
- what 49 passing tests do and do not prove;
- three current limitations;
- the exact field-evaluation numbers from the real manuscript, if available.
