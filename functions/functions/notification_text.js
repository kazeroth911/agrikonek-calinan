// Builds the push title and body from a notification document.
// Keep this in sync with lib/features/notifications/notification_text.dart,
// so the phone's push and the in-app inbox say the same thing.
//
// The text is built here, on the server, from the stored payload instead
// of being written by the sending phone. That way a user cannot make
// another user's phone show arbitrary text.

"use strict";

const BID_TITLES = {
  bid: "New cash offer",
  accept: "Offer accepted",
  reject: "Offer rejected",
  counter: "Counter offer",
};

const BARTER_TITLES = {
  propose: "New barter proposal",
  accept: "Barter accepted",
  reject: "Barter rejected",
  counter: "Barter counter-proposal",
};

function peso(amount) {
  if (typeof amount !== "number" || !Number.isFinite(amount)) return "";
  return ` (₱${amount.toFixed(2)})`;
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
  const listing = str(payload.listingTitle, "a listing");
  const action = str(payload.action, "");

  switch (type) {
    case "bid":
      return {
        title: BID_TITLES[action] || "Bid update",
        body: `${listing}${peso(payload.amount)}`,
      };
    case "barter":
      return {
        title: BARTER_TITLES[action] || "Barter update",
        body: listing,
      };
    case "msg":
      return {
        title: str(payload.senderName, "New message"),
        body: str(payload.preview, "You have a new message."),
      };
    case "admin":
      return {
        title: str(payload.title, "AgriKonek announcement"),
        body: str(payload.body, "Open the app to read it."),
      };
    default:
      return {title: "AgriKonek", body: "You have a new notification."};
  }
}

module.exports = {describe};
