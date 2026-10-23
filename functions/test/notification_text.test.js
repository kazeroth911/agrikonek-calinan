"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {describe, TEXT} = require("../notification_text");

test("bid notifications show the bilingual action and peso amount", () => {
  assert.deepEqual(describe("bid", {action: "bid", listingTitle: "Durian", amount: 1250}), {
    title: "New cash offer / Bag-ong tanyag",
    body: "Durian (₱1250.00)",
  });
  assert.equal(describe("bid", {action: "counter", amount: 90}).title,
    "Counter offer / Counter nga tanyag");
  assert.equal(describe("bid", {action: "accept"}).title, "Offer accepted / Gidawat ang tanyag");
});

test("barter notifications use barter wording", () => {
  assert.deepEqual(describe("barter", {action: "propose", listingTitle: "Cacao"}), {
    title: "New barter proposal / Bag-ong tanyag sa baylo",
    body: "Cacao",
  });
  assert.equal(describe("barter", {action: "accept"}).title, "Barter accepted / Gidawat ang baylo");
});

test("missing, bad or odd fields fall back safely", () => {
  assert.deepEqual(describe("bid", {}), {
    title: "Bid update / Update sa tanyag",
    body: "a listing / usa ka baligya",
  });
  assert.equal(describe("bid", {action: "constructor"}).title, TEXT.bid.fallback);
  assert.equal(describe("bid", {action: "fallback"}).title, TEXT.bid.fallback);
  assert.equal(describe("bid", {amount: "500"}).body, "a listing / usa ka baligya");
  assert.equal(describe("unknown", {}).title, "AgriKonek");
  assert.equal(describe("admin", {}).title, "AgriKonek announcement / Pahibalo sa AgriKonek");
  assert.equal(describe("msg", {preview: "  "}).body,
    "You have a new message. / Naa kay bag-ong mensahe.");
});

// The app's inbox (Dart) and the push (this file) must say the same thing.
test("every wording here also appears in the Dart notification_text.dart", () => {
  const dartPath = path.join(__dirname, "..", "..", "lib", "features", "notifications",
    "notification_text.dart");
  if (!fs.existsSync(dartPath)) return; // e.g. when only functions/ is deployed
  const dart = fs.readFileSync(dartPath, "utf8");
  const strings = [
    ...Object.values(TEXT.bid),
    ...Object.values(TEXT.barter),
    TEXT.listingFallback, TEXT.msgTitle, TEXT.msgBody,
    TEXT.adminTitle, TEXT.adminBody, TEXT.defaultTitle, TEXT.defaultBody,
  ];
  for (const s of strings) {
    assert.ok(dart.includes(`'${s}'`), `Missing from notification_text.dart: ${s}`);
  }
});
