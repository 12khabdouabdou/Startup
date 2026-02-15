/**
 * FillExchange Cloud Functions
 *
 * Handles server-side notification triggers:
 * 1. onJobStatusChange - Notifies parties when job status updates
 * 2. onNewListing      - Notifies nearby haulers when a new listing is posted
 * 3. onUserApproved    - Notifies user when admin approves their account
 */

const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// ─── 1. Job Status Change Notifications ────────────────

exports.onJobStatusChange = onDocumentUpdated("jobs/{jobId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (before.status === after.status) return; // No status change

  const jobId = event.params.jobId;
  const statusLabels = {
    pending: "Waiting for Hauler",
    accepted: "Hauler Accepted",
    enRoute: "Hauler En Route",
    atPickup: "Hauler at Pickup",
    loaded: "Material Loaded",
    inTransit: "In Transit",
    atDropoff: "At Dropoff",
    completed: "Job Completed! ✅",
    cancelled: "Job Cancelled ❌",
  };

  const title = `Job Update: ${after.material || "Material"}`;
  const body = statusLabels[after.status] || `Status: ${after.status}`;

  // Notify the host (excavator/developer)
  if (after.hostUid) {
    await sendNotificationToUser(after.hostUid, title, body, {
      type: "job_update",
      jobId: jobId,
      status: after.status,
    });
  }

  // Notify the hauler (if they aren't the one making the change)
  if (after.haulerUid && after.haulerUid !== after.hostUid) {
    await sendNotificationToUser(after.haulerUid, title, body, {
      type: "job_update",
      jobId: jobId,
      status: after.status,
    });
  }

  // Also send to topic subscribers
  try {
    await messaging.send({
      topic: `job_${jobId}`,
      notification: { title, body },
      data: { type: "job_update", jobId, status: after.status },
    });
  } catch (e) {
    console.log("Topic send failed (no subscribers?):", e.message);
  }
});

// ─── 2. New Listing Notifications ──────────────────────

exports.onNewListing = onDocumentCreated("listings/{listingId}", async (event) => {
  const listing = event.data.data();
  const listingId = event.params.listingId;

  if (!listing || listing.status !== "active") return;

  const materialLabel = (listing.material || "Material").charAt(0).toUpperCase()
    + (listing.material || "material").slice(1);

  const typeLabel = listing.type === "offering" ? "Available" : "Needed";
  const title = `${typeLabel}: ${materialLabel}`;
  const qty = listing.quantity ? `${listing.quantity}` : "?";
  const unit = listing.unit || "units";
  const body = `${qty} ${unit} — ${listing.address || "Location not specified"}`;

  // Send to "all_listings" topic (broad)
  try {
    await messaging.send({
      topic: "all_listings",
      notification: { title, body },
      data: {
        type: "new_listing",
        listingId: listingId,
        material: listing.material || "",
        listingType: listing.type || "",
      },
    });
  } catch (e) {
    console.log("Topic send failed:", e.message);
  }

  // If listing has a region tag, send to that region topic too
  if (listing.region) {
    try {
      await messaging.send({
        topic: `listings_${listing.region}`,
        notification: { title, body },
        data: {
          type: "new_listing",
          listingId: listingId,
        },
      });
    } catch (e) {
      console.log("Region topic send failed:", e.message);
    }
  }
});

// ─── 3. User Approved Notification ─────────────────────

exports.onUserApproved = onDocumentUpdated("users/{uid}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  // Only fire when status changes to 'approved'
  if (before.status === after.status || after.status !== "approved") return;

  const uid = event.params.uid;
  const title = "Account Approved! 🎉";
  const body = "Your FillExchange account has been verified. You can now start using the app.";

  await sendNotificationToUser(uid, title, body, {
    type: "account_approved",
    uid: uid,
  });
});

// ─── Helper: Send notification to a user by UID ────────

async function sendNotificationToUser(uid, title, body, data = {}) {
  try {
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) return;

    const userData = userDoc.data();

    // Check user notification preferences
    const settings = userData.notificationSettings || {};
    if (data.type === "new_listing" && settings.newListings === false) return;
    if (data.type === "job_update" && settings.jobUpdates === false) return;
    if (data.type === "message" && settings.messages === false) return;

    const tokens = userData.fcmTokens || [];
    if (tokens.length === 0) return;

    // Convert all data values to strings (FCM requirement)
    const stringData = {};
    for (const [key, value] of Object.entries(data)) {
      stringData[key] = String(value);
    }

    const response = await messaging.sendEachForMulticast({
      tokens: tokens,
      notification: { title, body },
      data: stringData,
      android: {
        priority: "high",
        notification: {
          channelId: "fill_exchange_default",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });

    // Clean up invalid tokens
    const tokensToRemove = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const errCode = resp.error?.code;
        if (
          errCode === "messaging/invalid-registration-token" ||
          errCode === "messaging/registration-token-not-registered"
        ) {
          tokensToRemove.push(tokens[idx]);
        }
      }
    });

    if (tokensToRemove.length > 0) {
      await db.collection("users").doc(uid).update({
        fcmTokens: require("firebase-admin/firestore").FieldValue.arrayRemove(tokensToRemove),
      });
      console.log(`Removed ${tokensToRemove.length} invalid tokens for ${uid}`);
    }
  } catch (error) {
    console.error(`Error sending notification to ${uid}:`, error);
  }
}
