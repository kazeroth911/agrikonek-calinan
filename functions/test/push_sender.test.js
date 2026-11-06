"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {sendPushForNotification} = require("../push_sender");

// Minimal stand-ins for Firestore and FCM.
function fakeRef() {
  return {updates: [], async update(u) { this.updates.push(u); }};
}

// tokens: strings, or {token, language}. results[i] is the send result
// for tokens[i]: true, or an FCM error code.
function fakeDeps(tokens, results) {
  const entries = tokens.map((t) => (typeof t === "string" ? {token: t} : t));
  const tokenDocs = entries.map((e) => ({
    deleted: false,
    get: (k) => e[k],
    ref: {async delete() { tokenDocs.find((d) => d.get("token") === e.token).deleted = true; }},
  }));
  const sent = [];
  return {
    tokenDocs,
    sent,
    deps: {
      db: {collection: () => ({doc: () => ({collection: () => ({get: async () => ({docs: tokenDocs})})})})},
      messaging: {
        async sendEachForMulticast(msg) {
          sent.push(msg);
          const responses = msg.tokens.map((tok) => {
            const r = results[entries.findIndex((e) => e.token === tok)];
            return r === true ? {success: true} : {success: false, error: {code: r}};
          });
          return {
            responses,
            successCount: responses.filter((r) => r.success).length,
            failureCount: responses.filter((r) => !r.success).length,
          };
        },
      },
      serverTimestamp: () => "TS",
      log: {info() {}, warn() {}},
    },
  };
}

const bid = {
  recipientId: "seller1",
  type: "bid",
  payload: {action: "bid", offerId: "off1", listingTitle: "Durian", amount: 500},
};

test("sends title, body, channel and link data, then records sent", async () => {
  const ref = fakeRef();
  const f = fakeDeps(["tokA"], [true]);
  const status = await sendPushForNotification(ref, "n1", bid, f.deps);

  assert.equal(status, "sent");
  const msg = f.sent[0];
  assert.deepEqual(msg.tokens, ["tokA"]);
  assert.equal(msg.notification.title, "New cash offer");
  assert.equal(msg.android.notification.channelId, "agrikonek_alerts");
  assert.deepEqual(msg.data, {notificationId: "n1", type: "bid", offerId: "off1"});
  assert.equal(ref.updates[0].pushStatus, "sent");
});

test("records no_device and sends nothing when the recipient has no phone", async () => {
  const ref = fakeRef();
  const f = fakeDeps([], []);
  assert.equal(await sendPushForNotification(ref, "n2", bid, f.deps), "no_device");
  assert.equal(f.sent.length, 0);
});

test("deletes only dead tokens", async () => {
  const ref = fakeRef();
  const f = fakeDeps(["dead", "flaky"], [
    "messaging/registration-token-not-registered",
    "messaging/internal-error",
  ]);
  assert.equal(await sendPushForNotification(ref, "n3", bid, f.deps), "failed");
  assert.equal(f.tokenDocs[0].deleted, true);
  assert.equal(f.tokenDocs[1].deleted, false);
});

test("rejects a record without a recipient", async () => {
  const ref = fakeRef();
  const f = fakeDeps(["tokA"], [true]);
  assert.equal(await sendPushForNotification(ref, "n4", {type: "bid"}, f.deps), "invalid");
  assert.equal(f.sent.length, 0);
});

test("each phone gets the push in its own language", async () => {
  const ref = fakeRef();
  const f = fakeDeps([
    {token: "phoneEn", language: "en"},
    {token: "phoneCeb", language: "ceb"},
    {token: "oldPhone"}, // saved before the language setting existed
  ], [true, true, "messaging/registration-token-not-registered"]);
  assert.equal(await sendPushForNotification(ref, "n5", bid, f.deps), "sent");

  assert.equal(f.sent.length, 2);
  const en = f.sent.find((m) => m.tokens.includes("phoneEn"));
  const ceb = f.sent.find((m) => m.tokens.includes("phoneCeb"));
  assert.deepEqual(en.tokens, ["phoneEn", "oldPhone"]);
  assert.equal(en.notification.title, "New cash offer");
  assert.deepEqual(ceb.tokens, ["phoneCeb"]);
  assert.equal(ceb.notification.title, "Bag-ong tanyag");
  assert.equal(f.tokenDocs[2].deleted, true);
  assert.equal(ref.updates[0].pushSuccessCount, 2);
  assert.equal(ref.updates[0].pushFailureCount, 1);
});
