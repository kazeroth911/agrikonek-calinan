"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {describe} = require("../notification_text");

test("bid notifications show the action and peso amount", () => {
  assert.deepEqual(describe("bid", {action: "bid", listingTitle: "Durian", amount: 1250}), {
    title: "New cash offer",
    body: "Durian (₱1250.00)",
  });
  assert.equal(describe("bid", {action: "counter", amount: 90}).title, "Counter offer");
  assert.equal(describe("bid", {action: "accept"}).title, "Offer accepted");
});

test("barter notifications use barter wording", () => {
  assert.deepEqual(describe("barter", {action: "propose", listingTitle: "Cacao"}), {
    title: "New barter proposal",
    body: "Cacao",
  });
  assert.equal(describe("barter", {action: "accept"}).title, "Barter accepted");
});

test("missing or bad fields fall back safely", () => {
  assert.deepEqual(describe("bid", {}), {title: "Bid update", body: "a listing"});
  assert.equal(describe("bid", {amount: "500"}).body, "a listing");
  assert.equal(describe("unknown", {}).title, "AgriKonek");
  assert.equal(describe("admin", {}).title, "AgriKonek announcement");
  assert.equal(describe("msg", {preview: "  "}).body, "You have a new message.");
});
