// Tests for ../firestore.rules against the Firestore emulator.
//
// Run from the project root (needs Java and the Firebase CLI):
//   cd firestore-tests && npm install && cd ..
//   firebase emulators:exec --only firestore --project demo-agrikonek "npm --prefix firestore-tests test"
//
// "demo-agrikonek" is a throwaway emulator-only project: nothing here
// touches the real kalinan-app data.

"use strict";

const fs = require("node:fs");
const path = require("node:path");
const {describe, it, before, beforeEach, after} = require("node:test");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");
const {
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  collection,
  query,
  where,
  serverTimestamp,
  arrayUnion,
  Timestamp,
  writeBatch,
  limit,
} = require("firebase/firestore");

let env;

const db = (uid) => env.authenticatedContext(uid).firestore();
const entry = (byUserId, action, amount) => ({
  byUserId,
  action,
  ...(amount === undefined ? {} : {amount}),
  at: Timestamp.now(),
});

const SELLER = "seller1";
const BUYER = "buyer1";
const OTHER = "other1";
const ADMIN = "admin1";
const CONVO = "buyer1_seller1"; // Conversation.idFor: sorted, joined by "_"

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    const now = Timestamp.now();
    await setDoc(doc(d, "profiles", ADMIN),
      {fullName: "Researcher", barangay: "Wangan", roles: {admin: true, seller: false}});
    await setDoc(doc(d, "profiles", SELLER),
      {fullName: "Ana", barangay: "Wangan", roles: {seller: true}});
    await setDoc(doc(d, "profiles", BUYER),
      {fullName: "Ben", barangay: "Riverside", roles: {buyer: true}});
    await setDoc(doc(d, "profiles", OTHER),
      {fullName: "Cris", barangay: "Lamanan", roles: {buyer: true}});
    await setDoc(doc(d, "listings", "lst1"), {
      ownerId: SELLER, ownerName: "Ana", ownerBarangay: "Wangan",
      title: "Durian", category: "Fruits", description: "", unit: "kg",
      price: 100, modes: ["sale", "barter"], photoUrls: [],
      availableFrom: null, availableTo: null, status: "active", createdAt: now,
    });
    await setDoc(doc(d, "offers", "off1"), {
      listingId: "lst1", listingTitle: "Durian", buyerId: BUYER, sellerId: SELLER,
      amount: 90, currency: "PHP", message: null, status: "pending",
      history: [entry(BUYER, "bid", 90)], createdAt: now, updatedAt: now,
    });
    await setDoc(doc(d, "barterProposals", "bar1"), {
      listingId: "lst1", listingTitle: "Durian", proposerId: BUYER, ownerId: SELLER,
      offeredItems: [{name: "compost", quantity: 2, unit: "sack"}],
      requestedItems: [{name: "Durian", quantity: null, unit: null}],
      note: null, status: "pending",
      history: [entry(BUYER, "propose")], createdAt: now, updatedAt: now,
    });
    await setDoc(doc(d, "conversations", CONVO), {
      participantIds: [BUYER, SELLER], participantNames: {[BUYER]: "Ben", [SELLER]: "Ana"},
      lastMessage: null, lastSenderId: null, unreadCounts: {[BUYER]: 0, [SELLER]: 0},
      relatedListingId: "lst1", relatedListingTitle: "Durian", updatedAt: now,
    });
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-agrikonek",
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, "..", "firestore.rules"), "utf8"),
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed();
});

after(async () => {
  await env.cleanup();
});

// ---------------------------------------------------------------------------
describe("listings", () => {
  const newListing = (overrides = {}) => ({
    ownerId: SELLER, ownerName: "Ana", ownerBarangay: "Wangan",
    title: "Eggs", category: "Poultry", description: "", unit: "tray",
    price: 200, modes: ["sale"], photoUrls: [],
    availableFrom: null, availableTo: null, status: "active",
    createdAt: serverTimestamp(), ...overrides,
  });

  it("a farmer can post under their own name", async () => {
    await assertSucceeds(setDoc(doc(db(SELLER), "listings", "new1"), newListing()));
  });

  it("nobody can post under another farmer's name", async () => {
    await assertFails(setDoc(doc(db(SELLER), "listings", "new1"),
      newListing({ownerName: "Ben"})));
    await assertFails(setDoc(doc(db(BUYER), "listings", "new1"), newListing()));
  });

  it("a negative price is refused", async () => {
    await assertFails(setDoc(doc(db(SELLER), "listings", "new1"),
      newListing({price: -5})));
  });

  it("the owner can edit, but never hand the listing to someone else", async () => {
    await assertSucceeds(updateDoc(doc(db(SELLER), "listings", "lst1"), {title: "Durian (Puyat)"}));
    await assertFails(updateDoc(doc(db(SELLER), "listings", "lst1"), {ownerId: BUYER}));
    await assertFails(updateDoc(doc(db(SELLER), "listings", "lst1"), {ownerName: "Someone"}));
  });

  it("others cannot edit or delete it", async () => {
    await assertFails(updateDoc(doc(db(BUYER), "listings", "lst1"), {status: "closed"}));
  });
});

// ---------------------------------------------------------------------------
describe("bids (offers)", () => {
  const newOffer = (overrides = {}) => ({
    listingId: "lst1", listingTitle: "Durian", buyerId: OTHER, sellerId: SELLER,
    amount: 95, currency: "PHP", message: null, status: "pending",
    history: [entry(OTHER, "bid", 95)],
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...overrides,
  });

  it("a buyer can bid on an open listing", async () => {
    await assertSucceeds(setDoc(doc(db(OTHER), "offers", "new1"), newOffer()));
  });

  it("the seller must be the listing's real owner", async () => {
    await assertFails(setDoc(doc(db(OTHER), "offers", "new1"), newOffer({sellerId: BUYER})));
  });

  it("nobody can bid on their own listing", async () => {
    await assertFails(setDoc(doc(db(SELLER), "offers", "new1"), newOffer({
      buyerId: SELLER, history: [entry(SELLER, "bid", 95)],
    })));
  });

  it("no bids on a closed listing", async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), "listings", "lst1"), {status: "closed"}));
    await assertFails(setDoc(doc(db(OTHER), "offers", "new1"), newOffer()));
  });

  it("the seller can accept the buyer's bid", async () => {
    await assertSucceeds(updateDoc(doc(db(SELLER), "offers", "off1"), {
      status: "accepted", amount: 90, updatedAt: serverTimestamp(),
      history: arrayUnion(entry(SELLER, "accept", 90)),
    }));
  });

  it("a buyer cannot accept their own bid", async () => {
    await assertFails(updateDoc(doc(db(BUYER), "offers", "off1"), {
      status: "accepted", updatedAt: serverTimestamp(),
      history: arrayUnion(entry(BUYER, "accept", 90)),
    }));
  });

  it("a buyer can revise their open bid (a counter)", async () => {
    await assertSucceeds(updateDoc(doc(db(BUYER), "offers", "off1"), {
      status: "countered", amount: 95, updatedAt: serverTimestamp(),
      history: arrayUnion(entry(BUYER, "counter", 95)),
    }));
  });

  it("accepting cannot change the amount", async () => {
    await assertFails(updateDoc(doc(db(SELLER), "offers", "off1"), {
      status: "accepted", amount: 1, updatedAt: serverTimestamp(),
      history: arrayUnion(entry(SELLER, "accept", 1)),
    }));
  });

  it("who the buyer is can never change", async () => {
    await assertFails(updateDoc(doc(db(SELLER), "offers", "off1"), {
      buyerId: OTHER, status: "countered", amount: 80,
      history: arrayUnion(entry(SELLER, "counter", 80)),
    }));
  });

  it("earlier history entries cannot be rewritten", async () => {
    await assertFails(updateDoc(doc(db(SELLER), "offers", "off1"), {
      status: "countered", amount: 80, updatedAt: serverTimestamp(),
      history: [entry(BUYER, "bid", 1), entry(SELLER, "counter", 80)],
    }));
  });

  it("an accepted bid is final", async () => {
    await updateDoc(doc(db(SELLER), "offers", "off1"), {
      status: "accepted", updatedAt: serverTimestamp(),
      history: arrayUnion(entry(SELLER, "accept", 90)),
    });
    await assertFails(updateDoc(doc(db(BUYER), "offers", "off1"), {
      status: "countered", amount: 50, updatedAt: serverTimestamp(),
      history: arrayUnion(entry(BUYER, "counter", 50)),
    }));
  });

  it("only the two parties can read a bid", async () => {
    await assertSucceeds(getDoc(doc(db(BUYER), "offers", "off1")));
    await assertSucceeds(getDoc(doc(db(SELLER), "offers", "off1")));
    await assertFails(getDoc(doc(db(OTHER), "offers", "off1")));
  });
});

// ---------------------------------------------------------------------------
describe("barters", () => {
  const newBarter = (overrides = {}) => ({
    listingId: "lst1", listingTitle: "Durian", proposerId: OTHER, ownerId: SELLER,
    offeredItems: [{name: "eggs", quantity: 1, unit: "tray"}],
    requestedItems: [{name: "Durian", quantity: null, unit: null}],
    note: null, status: "pending", history: [entry(OTHER, "propose")],
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...overrides,
  });

  it("a farmer can propose a barter", async () => {
    await assertSucceeds(setDoc(doc(db(OTHER), "barterProposals", "new1"), newBarter()));
  });

  it("the owner must be the listing's real owner", async () => {
    await assertFails(setDoc(doc(db(OTHER), "barterProposals", "new1"),
      newBarter({ownerId: BUYER})));
  });

  it("the owner can accept; the proposer cannot accept their own proposal", async () => {
    await assertFails(updateDoc(doc(db(BUYER), "barterProposals", "bar1"), {
      status: "accepted", updatedAt: serverTimestamp(),
      history: arrayUnion(entry(BUYER, "accept")),
    }));
    await assertSucceeds(updateDoc(doc(db(SELLER), "barterProposals", "bar1"), {
      status: "accepted", updatedAt: serverTimestamp(),
      history: arrayUnion(entry(SELLER, "accept")),
    }));
  });

  it("the offered items cannot be changed afterwards", async () => {
    await assertFails(updateDoc(doc(db(SELLER), "barterProposals", "bar1"), {
      offeredItems: [{name: "gold", quantity: 100, unit: "kg"}],
      status: "accepted", history: arrayUnion(entry(SELLER, "accept")),
    }));
  });
});

// ---------------------------------------------------------------------------
describe("notifications", () => {
  const note = (sender, recipient, type, payload) => ({
    recipientId: recipient, senderId: sender, type, payload,
    read: false, createdAt: serverTimestamp(),
  });

  it("a party can notify the other party of their bid", async () => {
    await assertSucceeds(setDoc(doc(db(BUYER), "notifications", "n1"),
      note(BUYER, SELLER, "bid", {offerId: "off1", action: "bid"})));
  });

  it("nobody can notify a stranger about someone else's bid", async () => {
    await assertFails(setDoc(doc(db(BUYER), "notifications", "n1"),
      note(BUYER, OTHER, "bid", {offerId: "off1", action: "bid"})));
    await assertFails(setDoc(doc(db(OTHER), "notifications", "n1"),
      note(OTHER, SELLER, "bid", {offerId: "off1", action: "bid"})));
  });

  it("only admins can send announcements", async () => {
    await assertFails(setDoc(doc(db(SELLER), "notifications", "n1"),
      note(SELLER, BUYER, "admin", {title: "Fake", body: "Fake"})));
    await assertSucceeds(setDoc(doc(db(ADMIN), "notifications", "n1"),
      note(ADMIN, BUYER, "admin", {title: "Market day", body: "Saturday"})));
  });

  it("only the recipient can read it or mark it read", async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), "notifications", "n1"),
      {recipientId: SELLER, senderId: BUYER, type: "bid", payload: {}, read: false,
        createdAt: Timestamp.now()}));
    await assertFails(getDoc(doc(db(OTHER), "notifications", "n1")));
    await assertSucceeds(updateDoc(doc(db(SELLER), "notifications", "n1"), {read: true}));
    await assertFails(updateDoc(doc(db(SELLER), "notifications", "n1"), {type: "admin"}));
  });
});

// ---------------------------------------------------------------------------
describe("chat", () => {
  const message = (sender, text = "Pila?") => ({
    senderId: sender, text, attachmentUrl: null,
    sentAt: serverTimestamp(), readBy: [sender],
  });

  it("a thread must use the two sorted user IDs as its ID", async () => {
    const thread = {
      participantIds: [OTHER, SELLER], participantNames: {[OTHER]: "Cris", [SELLER]: "Ana"},
      lastMessage: null, lastSenderId: null, unreadCounts: {[OTHER]: 0, [SELLER]: 0},
      relatedListingId: null, relatedListingTitle: null, updatedAt: serverTimestamp(),
    };
    await assertSucceeds(setDoc(doc(db(OTHER), "conversations", "other1_seller1"), thread));
    await assertFails(setDoc(doc(db(OTHER), "conversations", "random-id"), thread));
  });

  it("participants can send; outsiders cannot read or send", async () => {
    await assertSucceeds(setDoc(doc(db(BUYER), "conversations", CONVO, "messages", "m1"),
      message(BUYER)));
    await assertFails(getDocs(collection(db(OTHER), "conversations", CONVO, "messages")));
    await assertFails(setDoc(doc(db(OTHER), "conversations", CONVO, "messages", "m2"),
      message(OTHER)));
  });

  it("messages cannot be edited", async () => {
    await setDoc(doc(db(BUYER), "conversations", CONVO, "messages", "m1"), message(BUYER));
    await assertFails(updateDoc(doc(db(BUYER), "conversations", CONVO, "messages", "m1"),
      {text: "changed"}));
  });

  it("the thread's participants cannot be changed", async () => {
    await assertFails(updateDoc(doc(db(BUYER), "conversations", CONVO),
      {participantIds: [BUYER, OTHER]}));
  });
});

// ---------------------------------------------------------------------------
describe("profile hiding", () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const d = ctx.firestore();
      await updateDoc(doc(d, "profiles", SELLER), {hidden: true});
      await setDoc(doc(d, "hiddenProfiles", SELLER), {hiddenAt: Timestamp.now(), hiddenBy: SELLER});
    });
  });

  it("a hidden profile is readable only by its owner and admins", async () => {
    await assertFails(getDoc(doc(db(BUYER), "profiles", SELLER)));
    await assertSucceeds(getDoc(doc(db(SELLER), "profiles", SELLER)));
    await assertSucceeds(getDoc(doc(db(ADMIN), "profiles", SELLER)));
  });

  it("the list of hidden IDs is readable by signed-in users", async () => {
    await assertSucceeds(getDocs(collection(db(BUYER), "hiddenProfiles")));
  });

  it("a hidden profile gets no new bids or messages", async () => {
    await assertFails(setDoc(doc(db(OTHER), "offers", "new1"), {
      listingId: "lst1", listingTitle: "Durian", buyerId: OTHER, sellerId: SELLER,
      amount: 95, currency: "PHP", message: null, status: "pending",
      history: [entry(OTHER, "bid", 95)],
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(db(BUYER), "conversations", CONVO, "messages", "m1"), {
      senderId: BUYER, text: "hi", attachmentUrl: null,
      sentAt: serverTimestamp(), readBy: [BUYER],
    }));
  });

  it("only the owner or an admin can hide a profile", async () => {
    const marker = {hiddenAt: serverTimestamp(), hiddenBy: OTHER};
    await assertFails(setDoc(doc(db(OTHER), "hiddenProfiles", BUYER), marker));
    await assertSucceeds(setDoc(doc(db(BUYER), "hiddenProfiles", BUYER),
      {hiddenAt: serverTimestamp(), hiddenBy: BUYER}));
  });
});

// ---------------------------------------------------------------------------
describe("profiles and announcements", () => {
  it("farmers cannot give themselves the admin role or change consent", async () => {
    await assertFails(updateDoc(doc(db(BUYER), "profiles", BUYER), {roles: {admin: true}}));
    await assertFails(updateDoc(doc(db(BUYER), "profiles", BUYER), {consentGiven: false}));
    await assertSucceeds(updateDoc(doc(db(BUYER), "profiles", BUYER), {fullName: "Ben C."}));
  });

  it("only admins can read the announcement history", async () => {
    await assertFails(getDocs(query(collection(db(BUYER), "announcements"),
      where("sentBy", "==", ADMIN))));
    await assertSucceeds(getDocs(collection(db(ADMIN), "announcements")));
  });
});

// ---------------------------------------------------------------------------
describe("withdrawing (paper §3.5.3)", () => {
  it("the buyer can withdraw their waiting bid", async () => {
    await assertSucceeds(updateDoc(doc(db(BUYER), "offers", "off1"), {
      status: "withdrawn", updatedAt: serverTimestamp(),
      history: arrayUnion(entry(BUYER, "withdraw", 90)),
    }));
  });

  it("the other party cannot withdraw it for them", async () => {
    await assertFails(updateDoc(doc(db(SELLER), "offers", "off1"), {
      status: "withdrawn", updatedAt: serverTimestamp(),
      history: arrayUnion(entry(SELLER, "withdraw", 90)),
    }));
  });

  it("a withdrawn bid is final", async () => {
    await updateDoc(doc(db(BUYER), "offers", "off1"), {
      status: "withdrawn", updatedAt: serverTimestamp(),
      history: arrayUnion(entry(BUYER, "withdraw", 90)),
    });
    await assertFails(updateDoc(doc(db(SELLER), "offers", "off1"), {
      status: "accepted", updatedAt: serverTimestamp(),
      history: arrayUnion(entry(SELLER, "accept", 90)),
    }));
  });

  it("the proposer can withdraw a waiting barter; the owner cannot", async () => {
    await assertFails(updateDoc(doc(db(SELLER), "barterProposals", "bar1"), {
      status: "withdrawn", updatedAt: serverTimestamp(),
      history: arrayUnion(entry(SELLER, "withdraw")),
    }));
    await assertSucceeds(updateDoc(doc(db(BUYER), "barterProposals", "bar1"), {
      status: "withdrawn", updatedAt: serverTimestamp(),
      history: arrayUnion(entry(BUYER, "withdraw")),
    }));
  });
});

// ---------------------------------------------------------------------------
describe("verification levels (Table 3.4)", () => {
  it("a farmer cannot raise their own verification level", async () => {
    await assertFails(updateDoc(doc(db(BUYER), "profiles", BUYER), {verificationLevel: 2}));
  });

  it("a researcher-admin can set it", async () => {
    await assertSucceeds(updateDoc(doc(db(ADMIN), "profiles", BUYER), {verificationLevel: 2}));
  });

  it("a researcher-admin can prepare a hidden profile", async () => {
    await assertSucceeds(setDoc(doc(db(ADMIN), "profiles", "new1"), {
      fullName: "Dina", barangay: "Wangan", roles: {seller: true},
      phone: "+639171234567", verificationLevel: 1, hidden: true,
      hiddenAt: serverTimestamp(),
    }));
    await assertSucceeds(setDoc(doc(db(ADMIN), "hiddenProfiles", "new1"),
      {hiddenAt: serverTimestamp(), hiddenBy: ADMIN}));
    await assertFails(getDoc(doc(db(BUYER), "profiles", "new1")));
  });
});

// ---------------------------------------------------------------------------
describe("push tokens and their language", () => {
  const token = (extra = {}) => ({
    token: "fcm-token", platform: "android", updatedAt: serverTimestamp(), ...extra,
  });

  it("a user can save their own token in English or Cebuano", async () => {
    await assertSucceeds(setDoc(doc(db(BUYER), "deviceTokens", BUYER, "tokens", "t1"),
      token({language: "ceb"})));
    await assertSucceeds(setDoc(doc(db(BUYER), "deviceTokens", BUYER, "tokens", "t2"),
      token({language: "en"})));
    await assertSucceeds(setDoc(doc(db(BUYER), "deviceTokens", BUYER, "tokens", "t3"),
      token()));
  });

  it("an unknown language is refused", async () => {
    await assertFails(setDoc(doc(db(BUYER), "deviceTokens", BUYER, "tokens", "t4"),
      token({language: "fr"})));
  });

  it("nobody can save a token under someone else's account", async () => {
    await assertFails(setDoc(doc(db(OTHER), "deviceTokens", BUYER, "tokens", "t5"),
      token({language: "en"})));
  });
});

// ---------------------------------------------------------------------------
describe("profile claiming by phone (paper 3.5.4)", () => {
  const PHONE = "+639171112222";
  const PREP = "prep1";
  const FARMER = "phoneUser1";
  const phoneDb = (uid, phone) =>
    env.authenticatedContext(uid, {phone_number: phone}).firestore();

  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const d = ctx.firestore();
      await setDoc(doc(d, "profiles", PREP), {
        fullName: "Carla", barangay: "Wangan", roles: {seller: true, admin: false},
        phone: PHONE, verificationLevel: 1, consentGiven: true,
        hidden: true, hiddenAt: Timestamp.now(), createdAt: Timestamp.now(),
      });
      await setDoc(doc(d, "hiddenProfiles", PREP), {hiddenAt: Timestamp.now(), hiddenBy: ADMIN});
    });
  });

  async function claimBatch(db, uid, change = {}) {
    const snap = await getDoc(doc(db, "profiles", PREP));
    const batch = writeBatch(db);
    batch.set(doc(db, "profiles", uid),
      {...snap.data(), ...change, claimedFrom: PREP, claimedAt: serverTimestamp()});
    batch.update(doc(db, "profiles", PREP), {claimedBy: uid, claimedAt: serverTimestamp()});
    batch.set(doc(db, "hiddenProfiles", uid), {hiddenAt: serverTimestamp(), hiddenBy: uid});
    return batch.commit();
  }

  it("the verified phone owner can find their hidden prepared profile", async () => {
    const db = phoneDb(FARMER, PHONE);
    await assertSucceeds(getDocs(query(collection(db, "profiles"),
      where("phone", "==", PHONE), limit(10))));
    await assertSucceeds(getDoc(doc(db, "profiles", PREP)));
  });

  it("someone with another number cannot read it", async () => {
    await assertFails(getDoc(doc(phoneDb("x1", "+639990000000"), "profiles", PREP)));
    await assertFails(getDoc(doc(db(OTHER), "profiles", PREP)));
  });

  it("the verified phone owner can claim it", async () => {
    await assertSucceeds(claimBatch(phoneDb(FARMER, PHONE), FARMER));
  });

  it("a claim cannot change the prepared details", async () => {
    await assertFails(claimBatch(phoneDb(FARMER, PHONE), FARMER, {verificationLevel: 2}));
    await assertFails(claimBatch(phoneDb(FARMER, PHONE), FARMER, {roles: {seller: true, admin: true}}));
  });

  it("the copy and the claimed mark must be written together", async () => {
    const db = phoneDb(FARMER, PHONE);
    const snap = await getDoc(doc(db, "profiles", PREP));
    await assertFails(setDoc(doc(db, "profiles", FARMER),
      {...snap.data(), claimedFrom: PREP, claimedAt: serverTimestamp()}));
    await assertFails(updateDoc(doc(db, "profiles", PREP),
      {claimedBy: FARMER, claimedAt: serverTimestamp()}));
  });

  it("a profile can be claimed only once", async () => {
    await assertSucceeds(claimBatch(phoneDb(FARMER, PHONE), FARMER));
    await assertFails(claimBatch(phoneDb("phoneUser2", PHONE), "phoneUser2"));
  });

  it("an account without a verified phone cannot claim", async () => {
    await assertFails(claimBatch(db(OTHER), OTHER));
  });

  it("owners cannot change their phone, cooperative or claim fields", async () => {
    await assertFails(updateDoc(doc(db(BUYER), "profiles", BUYER), {phone: PHONE}));
    await assertFails(updateDoc(doc(db(BUYER), "profiles", BUYER), {cooperativeId: "coop1"}));
    await assertFails(updateDoc(doc(db(BUYER), "profiles", BUYER), {claimedBy: "x"}));
  });
});

// ---------------------------------------------------------------------------
describe("cooperatives (Figure 3.4)", () => {
  it("a researcher-admin can add and read cooperatives", async () => {
    await assertSucceeds(setDoc(doc(db(ADMIN), "cooperatives", "coop1"),
      {name: "Calinan Farmers Cooperative", barangay: "Wangan", createdAt: serverTimestamp()}));
    await assertSucceeds(getDoc(doc(db(ADMIN), "cooperatives", "coop1")));
  });

  it("farmers cannot read or add cooperatives", async () => {
    await assertFails(getDoc(doc(db(BUYER), "cooperatives", "coop1")));
    await assertFails(setDoc(doc(db(BUYER), "cooperatives", "coop2"),
      {name: "X", barangay: null, createdAt: serverTimestamp()}));
  });

  it("only a researcher-admin can record a profile's cooperative", async () => {
    await assertSucceeds(updateDoc(doc(db(ADMIN), "profiles", SELLER), {cooperativeId: "coop1"}));
  });
});
