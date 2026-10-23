"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {sendPushForNotification} = require("../push_sender");

// Minimal stand-ins for Firestore and FCM.
function fakeRef() {
  return {updates: [], async update(u) { this.updates.push(u); }};
}

function fakeDeps(tokens, results) {
  const tokenDocs = tokens.map((t) => ({
    deleted: false,
    get: (k) => (k === "token" ? t : undefined),
    ref: {async delete() { tokenDocs.find((d) => d.get("token") === t).deleted = true; }},
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
          const responses = results.map((r) => (r === true ? {success: true} : {success: false, error: {code: r}}));
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
