// Builds the push title and body from a notification document.
// Keep this in sync with lib/features/notifications/notification_text.dart,
// so the phone's push and the in-app inbox say the same thing.
// test/notification_text.test.js fails if the two files drift apart.
//
// Each phone saves its language ('en' or 'ceb') with its push token, and
// the push is written in that language. The Cebuano is listed for review
// in docs/NOTIFICATION_TEXT_CEBUANO.md.
//
// The text is built here, on the server, from the stored payload instead
// of being written by the sending phone. That way a user cannot make
// another user's phone show arbitrary text.

"use strict";

const TEXT = {
  en: {
    bid: {
      bid: "New cash offer",
      accept: "Offer accepted",
      reject: "Offer rejected",
      counter: "Counter offer",
      withdraw: "Offer withdrawn",
      fallback: "Bid update",
    },
    barter: {
      propose: "New barter proposal",
      accept: "Barter accepted",
      reject: "Barter declined",
      counter: "Barter counter-proposal",
      withdraw: "Barter withdrawn",
      fallback: "Barter update",
    },
    listingFallback: "a listing",
    msgTitle: "New message",
    msgBody: "You have a new message.",
    adminTitle: "AgriKonek announcement",
    adminBody: "Open the app to read it.",
    defaultTitle: "AgriKonek",
    defaultBody: "You have a new notification.",
  },
  ceb: {
    bid: {
      bid: "Bag-ong tanyag",
      accept: "Gidawat ang tanyag",
      reject: "Wala gidawat ang tanyag",
      counter: "Counter nga tanyag",
      withdraw: "Gibawi ang tanyag",
      fallback: "Update sa tanyag",
    },
    barter: {
      propose: "Bag-ong tanyag sa baylo",
      accept: "Gidawat ang baylo",
      reject: "Wala gidawat ang baylo",
      counter: "Gi-counter ang baylo",
      withdraw: "Gibawi ang baylo",
      fallback: "Update sa baylo",
    },
    listingFallback: "usa ka baligya",
    msgTitle: "Bag-ong mensahe",
    msgBody: "Naa kay bag-ong mensahe.",
    adminTitle: "Pahibalo sa AgriKonek",
    adminBody: "Ablihi ang app aron mabasa.",
    defaultTitle: "AgriKonek",
    defaultBody: "Naa kay bag-ong pahibalo.",
  },
};

const LANGUAGES = Object.keys(TEXT);

function peso(amount) {
  if (typeof amount !== "number" || !Number.isFinite(amount)) return "";
  return ` (₱${amount.toFixed(2)})`;
}

// Only real entries of the table, never inherited keys like "constructor".
function pick(table, action) {
  return action !== "fallback" && Object.hasOwn(table, action) ? table[action] : table.fallback;
}

function str(value, fallback) {
  return typeof value === "string" && value.trim() !== "" ? value.trim() : fallback;
}

/** 'ceb' stays 'ceb'; anything else is English. */
function normalizeLanguage(language) {
  return language === "ceb" ? "ceb" : "en";
}

/**
 * @param {string} type bid | barter | msg | admin
 * @param {Record<string, unknown>} payload
 * @param {string} [language] 'en' or 'ceb'
 * @returns {{title: string, body: string}}
 */
function describe(type, payload = {}, language = "en") {
  const t = TEXT[normalizeLanguage(language)];
  const listing = str(payload.listingTitle, t.listingFallback);
  const action = str(payload.action, "");

  switch (type) {
    case "bid":
      return {
        title: pick(t.bid, action),
        body: `${listing}${peso(payload.amount)}`,
      };
    case "barter":
      return {
        title: pick(t.barter, action),
        body: listing,
      };
    case "msg":
      return {
        title: str(payload.senderName, t.msgTitle),
        body: str(payload.preview, t.msgBody),
      };
    case "admin":
      return {
        title: str(payload.title, t.adminTitle),
        body: str(payload.body, t.adminBody),
      };
    default:
      return {title: t.defaultTitle, body: t.defaultBody};
  }
}

module.exports = {describe, normalizeLanguage, TEXT, LANGUAGES};
