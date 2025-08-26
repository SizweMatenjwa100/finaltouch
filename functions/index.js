// functions/index.js - Clean PayFast ITN Handler with Sandbox Credentials
const {onRequest} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const crypto = require("crypto");
const https = require("https");
const querystring = require("querystring");

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();

// PayFast Configuration - Updated with Your Sandbox Credentials
const PAYFAST_CONFIG = {
  merchant_id: "10041473",
  merchant_key: "qrs8b5w5uroiq",
  passphrase: "", // Empty - no passphrase configured
  sandbox: true,
  host: "sandbox.payfast.co.za"
};

/**
 * PayFast ITN (Instant Transaction Notification) Handler
 */
exports.payfastITN = onRequest({cors: true}, async (req, res) => {
  console.log("ITN Received:", req.method, req.url);

  if (req.method !== "POST") {
    console.log("Invalid method:", req.method);
    return res.status(405).send("Method Not Allowed");
  }

  try {
    const itnData = req.body;
    console.log("ITN Data:", JSON.stringify(itnData, null, 2));

    // Validate ITN data structure
    if (!validateITNStructure(itnData)) {
      console.log("Invalid ITN structure");
      return res.status(400).send("Invalid ITN data structure");
    }

    // Verify signature
    if (!verifySignature(itnData)) {
      console.log("Invalid signature");
      return res.status(400).send("Invalid signature");
    }

    // Validate with PayFast
    const isValidWithPayFast = await validateWithPayFast(itnData);
    if (!isValidWithPayFast) {
      console.log("PayFast validation failed");
      return res.status(400).send("PayFast validation failed");
    }

    // Process the payment
    await processPayment(itnData);

    console.log("ITN processed successfully");
    res.status(200).send("OK");

  } catch (error) {
    console.error("ITN processing error:", error);
    res.status(500).send("Internal Server Error");
  }
});

function validateITNStructure(data) {
  const requiredFields = [
    "m_payment_id", "pf_payment_id", "payment_status",
    "item_name", "amount_gross", "amount_fee", "amount_net"
  ];

  for (const field of requiredFields) {
    if (!Object.prototype.hasOwnProperty.call(data, field) ||
        data[field] === "") {
      console.log(`Missing required field: ${field}`);
      return false;
    }
  }

  return true;
}

function verifySignature(data) {
  const pfParamString = Object.keys(data)
      .filter((key) => key !== "signature")
      .sort()
      .map((key) =>
        `${key}=${encodeURIComponent(data[key]).replace(/%20/g, "+")}`)
      .join("&");

  let stringToHash = pfParamString;
  if (PAYFAST_CONFIG.sandbox && PAYFAST_CONFIG.passphrase) {
    stringToHash += `&passphrase=${
      encodeURIComponent(PAYFAST_CONFIG.passphrase)}`;
  }

  const calculatedSignature = crypto
      .createHash("md5")
      .update(stringToHash)
      .digest("hex");

  console.log("Signature verification:", {
    received: data.signature,
    calculated: calculatedSignature,
    match: calculatedSignature === data.signature,
  });

  return calculatedSignature === data.signature;
}

async function validateWithPayFast(data) {
  return new Promise((resolve) => {
    const postData = querystring.stringify(data);

    const options = {
      hostname: PAYFAST_CONFIG.host,
      port: 443,
      path: "/eng/query/validate",
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Content-Length": Buffer.byteLength(postData),
      },
    };

    const request = https.request(options, (response) => {
      let responseData = "";

      response.on("data", (chunk) => {
        responseData += chunk;
      });

      response.on("end", () => {
        console.log("PayFast validation response:",
            responseData.trim());
        resolve(responseData.trim() === "VALID");
      });
    });

    request.on("error", (error) => {
      console.error("PayFast validation error:", error);
      resolve(false);
    });

    request.write(postData);
    request.end();
  });
}

async function processPayment(itnData) {
  const paymentId = itnData.m_payment_id;
  const paymentStatus = itnData.payment_status;

  console.log(`Processing payment ${paymentId} with status ${paymentStatus}`);

  try {
    const paymentRef = db.collection("payments").doc(paymentId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      throw new Error(`Payment document ${paymentId} not found`);
    }

    const paymentData = paymentDoc.data();
    console.log("Payment data loaded:", paymentData.status);

    if (paymentData.status === "completed") {
      console.log("Payment already processed, skipping");
      return;
    }

    const expectedAmount = parseFloat(paymentData.amount);
    const receivedAmount = parseFloat(itnData.amount_gross);

    if (Math.abs(expectedAmount - receivedAmount) > 0.01) {
      throw new Error(`Amount mismatch: expected ${expectedAmount},
        received ${receivedAmount}`);
    }

    if (paymentStatus === "COMPLETE") {
      await handleSuccessfulPayment(paymentRef, itnData, paymentData);
    } else {
      await handleFailedPayment(paymentRef, itnData, paymentStatus);
    }
  } catch (error) {
    console.error("Payment processing error:", error);

    await db.collection("payment_errors").add({
      paymentId: paymentId,
      error: error.message,
      itnData: itnData,
      timestamp: new Date(),
    });

    throw error;
  }
}

async function handleSuccessfulPayment(paymentRef, itnData, paymentData) {
  const batch = db.batch();

  batch.update(paymentRef, {
    status: "completed",
    pfPaymentId: itnData.pf_payment_id,
    paymentDetails: {
      amountGross: parseFloat(itnData.amount_gross),
      amountFee: parseFloat(itnData.amount_fee),
      amountNet: parseFloat(itnData.amount_net),
      paymentStatus: itnData.payment_status,
      paymentDate: new Date(itnData.payment_date || new Date()),
      itemName: itnData.item_name,
    },
    completedAt: new Date(),
    processedVia: "itn_webhook",
  });

  const userId = paymentData.userId;
  const bookingData = JSON.parse(paymentData.bookingData);

  const locationId = await getOrCreateUserLocation(userId);

  const bookingRef = db
      .collection("users")
      .doc(userId)
      .collection("locations")
      .doc(locationId)
      .collection("bookings")
      .doc();

  const completeBookingData = {
    ...bookingData,
    id: bookingRef.id,
    userId: userId,
    locationId: locationId,
    paymentId: paymentData.paymentId,
    paymentStatus: "paid",
    pfPaymentId: itnData.pf_payment_id,
    status: "confirmed",
    totalAmount: paymentData.amount,
    currency: paymentData.currency || "ZAR",
    createdAt: new Date(),
    confirmedAt: new Date(),
    paidAt: new Date(),
  };

  batch.set(bookingRef, completeBookingData);

  const notificationRef = db
      .collection("users")
      .doc(userId)
      .collection("notifications")
      .doc();

  batch.set(notificationRef, {
    type: "payment_success",
    title: "Payment Successful!",
    message: `Your booking for ${bookingData.cleaningType ||
      "cleaning service"} has been confirmed.`,
    paymentId: paymentData.paymentId,
    bookingId: bookingRef.id,
    read: false,
    createdAt: new Date(),
  });

  await batch.commit();

  console.log("Payment and booking processed successfully");
  console.log(`Booking created: users/${userId}/locations/
    ${locationId}/bookings/${bookingRef.id}`);
}

async function handleFailedPayment(paymentRef, itnData, paymentStatus) {
  await paymentRef.update({
    status: "failed",
    pfPaymentId: itnData.pf_payment_id,
    paymentDetails: {
      paymentStatus: paymentStatus,
      failureReason: getFailureReason(paymentStatus),
      amountGross: parseFloat(itnData.amount_gross || 0),
    },
    failedAt: new Date(),
    processedVia: "itn_webhook",
  });

  console.log(`Payment failed with status: ${paymentStatus}`);
}

async function getOrCreateUserLocation(userId) {
  const locationsRef = db.collection("users").doc(userId)
      .collection("locations");
  const locationsSnapshot = await locationsRef.limit(1).get();

  if (!locationsSnapshot.empty) {
    return locationsSnapshot.docs[0].id;
  }

  const locationRef = locationsRef.doc();
  await locationRef.set({
    lat: -33.918861,
    lng: 18.4233,
    address: "Cape Town, South Africa",
    autoCreated: true,
    createdAt: new Date(),
  });

  console.log(`Created default location: ${locationRef.id}`);
  return locationRef.id;
}

function getFailureReason(status) {
  const reasons = {
    "CANCELLED": "Payment was cancelled by user",
    "FAILED": "Payment failed - insufficient funds or card declined",
    "PENDING": "Payment is still being processed",
    "EXPIRED": "Payment session expired",
  };
  return reasons[status] || `Payment failed with status: ${status}`;
}

exports.payfastHealthCheck = onRequest({cors: true}, (req, res) => {
  res.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    config: {
      sandbox: PAYFAST_CONFIG.sandbox,
      merchant_id: PAYFAST_CONFIG.merchant_id,
      host: PAYFAST_CONFIG.host,
    },
  });
});

exports.verifyPayment = onRequest({cors: true}, async (req, res) => {
  const {paymentId} = req.body;

  if (!paymentId) {
    return res.status(400).json({error: "Payment ID is required"});
  }

  try {
    const paymentDoc = await db.collection("payments").doc(paymentId).get();

    if (!paymentDoc.exists) {
      return res.status(404).json({error: "Payment not found"});
    }

    const paymentData = paymentDoc.data();

    return res.json({
      paymentId: paymentId,
      status: paymentData.status,
      amount: paymentData.amount,
      createdAt: paymentData.createdAt,
      completedAt: paymentData.completedAt,
      processedVia: paymentData.processedVia,
    });
  } catch (error) {
    console.error("Payment verification error:", error);
    return res.status(500).json({error: "Payment verification failed"});
  }
});