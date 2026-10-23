// Builds the push title and body from a notification document.
// Keep this in sync with lib/features/notifications/notification_text.dart,
// so the phone's push and the in-app inbox say the same thing.
// test/notification_text.test.js fails if the two files drift apart.
//
// Wording is "English / Cebuano", like the rest of the app. The Cebuano
// is listed for review in docs/NOTIFICATION_TEXT_CEBUANO.md.
//
// The text is built here, on the server, from the stored payload instead
// of being written by the sending phone. That way a user cannot make
// another user's phone show arbitrary text.

"use strict";

const TEXT = {
  bid: {
    bid: "New cash offer / Bag-ong tanyag",
    accept: "Offer accepted / Gidawat ang tanyag",
    reject: "Offer rejected / Wala gidawat ang tanyag",
    counter: "Counter offer / Counter nga tanyag",
    fallback: "Bid update / Update sa tanyag",
  },
  barter: {
    propose: "New barter proposal / Bag-ong tanyag sa baylo",
    accept: "Barter accepted / Gidawat ang baylo",
    reject: "Barter rejected / Wala gidawat ang baylo",
    counter: "Barter counter-proposal / Gi-counter ang baylo",
    fallback: "Barter update / Update sa baylo",
  },
  listingFallback: "a listing / usa ka baligya",
  msgTitle: "New message / Bag-ong mensahe",
  msgBody: "You have a new message. / Naa kay bag-ong mensahe.",
  adminTitle: "AgriKonek announcement / Pahibalo sa AgriKonek",
  adminBody: "Open the app to read it. / Ablihi ang app aron mabasa.",
  defaultTitle: "AgriKonek",
  defaultBody: "You have a new notification. / Naa kay bag-ong pahibalo.",
};

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

/**
 * @param {string} type bid | barter | msg | admin
 * @param {Record<string, unknown>} payload
 * @returns {{title: string, body: string}}
 */
function describe(type, payload = {}) {
  const listing = str(payload.listingTitle, TEXT.listingFallback);
  const action = str(payload.action, "");

  switch (type) {
    case "bid":
      return {
        title: pick(TEXT.bid, action),
        body: `${listing}${peso(payload.amount)}`,
      };
    case "barter":
      return {
        title: pick(TEXT.barter, action),
        body: listing,
      };
    case "msg":
      return {
        title: str(payload.senderName, TEXT.msgTitle),
        body: str(payload.preview, TEXT.msgBody),
      };
    case "admin":
      return {
        title: str(payload.title, TEXT.adminTitle),
        body: str(payload.body, TEXT.adminBody),
      };
    default:
      return {title: TEXT.defaultTitle, body: TEXT.defaultBody};
  }
}

module.exports = {describe, TEXT};
