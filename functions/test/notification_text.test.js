"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {describe, normalizeLanguage, TEXT, LANGUAGES} = require("../notification_text");

test("bid notifications show the action and peso amount in English by default", () => {
  assert.deepEqual(describe("bid", {action: "bid", listingTitle: "Durian", amount: 1250}), {
    title: "New cash offer",
    body: "Durian (₱1250.00)",
  });
  assert.equal(describe("bid", {action: "counter", amount: 90}).title, "Counter offer");
  assert.equal(describe("bid", {action: "accept"}).title, "Offer accepted");
});

test("Cebuano phones get Cebuano wording only", () => {
  assert.deepEqual(describe("bid", {action: "bid", listingTitle: "Durian", amount: 1250}, "ceb"), {
    title: "Bag-ong tanyag",
    body: "Durian (₱1250.00)",
  });
  assert.equal(describe("barter", {action: "withdraw"}, "ceb").title, "Gibawi ang baylo");
  assert.equal(describe("bid", {}, "ceb").body, "usa ka baligya");
  assert.ok(!describe("msg", {}, "ceb").body.includes("/"));
});

test("unknown languages fall back to English", () => {
  assert.equal(normalizeLanguage("ceb"), "ceb");
  assert.equal(normalizeLanguage("fil"), "en");
  assert.equal(normalizeLanguage(undefined), "en");
  assert.equal(describe("bid", {action: "accept"}, "xx").title, "Offer accepted");
});

test("barter notifications use barter wording", () => {
  assert.deepEqual(describe("barter", {action: "propose", listingTitle: "Cacao"}), {
    title: "New barter proposal",
    body: "Cacao",
  });
  assert.equal(describe("barter", {action: "accept"}).title, "Barter accepted");
});

test("missing, bad or odd fields fall back safely", () => {
  assert.deepEqual(describe("bid", {}), {title: "Bid update", body: "a listing"});
  assert.equal(describe("bid", {action: "constructor"}).title, TEXT.en.bid.fallback);
  assert.equal(describe("bid", {action: "fallback"}).title, TEXT.en.bid.fallback);
  assert.equal(describe("bid", {amount: "500"}).body, "a listing");
  assert.equal(describe("unknown", {}).title, "AgriKonek");
  assert.equal(describe("admin", {}).title, "AgriKonek announcement");
  assert.equal(describe("msg", {preview: "  "}).body, "You have a new message.");
});

test("both languages have the same entries", () => {
  const keys = (o) => JSON.stringify(Object.keys(o).sort());
  assert.equal(keys(TEXT.en), keys(TEXT.ceb));
  assert.equal(keys(TEXT.en.bid), keys(TEXT.ceb.bid));
  assert.equal(keys(TEXT.en.barter), keys(TEXT.ceb.barter));
});

// The app's inbox (Dart) and the push (this file) must say the same thing.
test("every wording here also appears in the Dart notification_text.dart", () => {
  const dartPath = path.join(__dirname, "..", "..", "lib", "features", "notifications",
    "notification_text.dart");
  if (!fs.existsSync(dartPath)) return; // e.g. when only functions/ is deployed
  const dart = fs.readFileSync(dartPath, "utf8");
  for (const language of LANGUAGES) {
    const t = TEXT[language];
    const strings = [
      ...Object.values(t.bid),
      ...Object.values(t.barter),
      t.listingFallback, t.msgTitle, t.msgBody,
      t.adminTitle, t.adminBody, t.defaultTitle, t.defaultBody,
    ];
    for (const s of strings) {
      assert.ok(dart.includes(`'${s}'`), `Missing from notification_text.dart (${language}): ${s}`);
    }
  }
});
