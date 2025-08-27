// functions/index.js - COMPLETE FIXED VERSION WITH ENHANCED LOGGING
const { onRequest, onCall } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const crypto = require("crypto");
const https = require("https");
const querystring = require("querystring");

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();

// PayFast Configuration - Your Sandbox Credentials
const PAYFAST_CONFIG = {
  merchant_id: "10041473",
  merchant_key: "qrs8b5w5uroiq",
  passphrase: "", // Empty - no passphrase configured
  sandbox: true,
  host: "sandbox.payfast.co.za",
};

/**
 * PayFast ITN (Instant Transaction Notification) Handler
 * ENHANCED with comprehensive logging and error handling
 */
exports.payfastITN = onRequest({ cors: true }, async (req, res) => {
  const startTime = Date.now();
  console.log("🚀 ITN REQUEST START:", {
    method: req.method,
    url: req.url,
    headers: req.headers,
    timestamp: new Date().toISOString()
  });

  if (req.method !== "POST") {
    console.log("❌ Invalid method:", req.method);
    return res.status(405).send("Method Not Allowed");
  }

  try {
    // Parse ITN data - handle both JSON and form-encoded
    let itnData = req.body;

    console.log("📥 Raw body type:", typeof req.body);
    console.log("📥 Raw body:", req.body);

    // If body is empty or not an object, try parsing raw body
    if (!itnData || Object.keys(itnData).length === 0) {
      console.log("📝 Attempting to parse raw body...");
      const rawBody = req.rawBody?.toString("utf8") || "";
      console.log("📄 Raw body string:", rawBody);

      if (rawBody) {
        itnData = querystring.parse(rawBody);
        console.log("✅ Parsed from raw body:", itnData);
      } else {
        console.log("❌ No data in request body or raw body");
        return res.status(400).send("No ITN data received");
      }
    }

    console.log("📊 Final ITN Data:", JSON.stringify(itnData, null, 2));

    // Log all received fields
    console.log("🔍 ITN Fields received:", Object.keys(itnData));

    // Validate ITN structure
    if (!validateITNStructure(itnData)) {
      console.log("❌ ITN structure validation failed");
      await logError("ITN_STRUCTURE_INVALID", { itnData });
      return res.status(400).send("Invalid ITN data structure");
    }

    // Verify signature
    if (!verifySignature(itnData)) {
      console.log("❌ Signature verification failed");
      await logError("SIGNATURE_MISMATCH", { itnData });
      return res.status(400).send("Invalid signature");
    }

    // Respond to PayFast immediately
    console.log("✅ Sending OK response to PayFast");
    res.status(200).send("OK");

    // Continue processing asynchronously
    console.log("🔄 Starting async payment processing...");

    // Validate with PayFast (optional but recommended)
    const isValidWithPayFast = await validateWithPayFast(itnData);
    if (!isValidWithPayFast) {
      console.log("⚠️ PayFast validation failed - continuing anyway for sandbox");
      // Don't return here - continue processing for sandbox testing
    }

    await processPayment(itnData);

    const processingTime = Date.now() - startTime;
    console.log(`✅ ITN processing completed in ${processingTime}ms`);

  } catch (error) {
    console.error("💥 ITN processing error:", error);
    console.error("📋 Error stack:", error.stack);

    await logError("ITN_PROCESSING_ERROR", {
      error: error.message,
      stack: error.stack,
      itnData: req.body
    });

    if (!res.headersSent) {
      return res.status(500).send("Internal Server Error");
    }
  }
});

function validateITNStructure(data) {
  console.log("🔍 Validating ITN structure...");

  const requiredFields = [
    "m_payment_id",
    "pf_payment_id",
    "payment_status",
    "item_name",
    "amount_gross",
  ];

  const missingFields = [];

  for (const field of requiredFields) {
    if (!Object.prototype.hasOwnProperty.call(data, field) ||
        data[field] === "" ||
        data[field] === null ||
        data[field] === undefined) {
      missingFields.push(field);
    }
  }

  if (missingFields.length > 0) {
    console.log(`❌ Missing required fields: ${missingFields.join(", ")}`);
    console.log("📋 Available fields:", Object.keys(data));
    return false;
  }

  console.log("✅ ITN structure validation passed");
  return true;
}

function verifySignature(data) {
  console.log("🔐 Starting signature verification...");

  // Create parameter string for signature verification
  const pfParamString = Object.keys(data)
    .filter((key) => key !== "signature")
    .sort()
    .map((key) => {
      const value = String(data[key]);
      const encoded = encodeURIComponent(value).replace(/%20/g, "+");
      return `${key}=${encoded}`;
    })
    .join("&");

  console.log("📝 Parameter string for signature:", pfParamString);

  let stringToHash = pfParamString;

  // Add passphrase if configured
  if (PAYFAST_CONFIG.sandbox && PAYFAST_CONFIG.passphrase) {
    stringToHash += `&passphrase=${encodeURIComponent(PAYFAST_CONFIG.passphrase)}`;
    console.log("🔑 Added passphrase to signature string");
  }

  console.log("🔤 String to hash:", stringToHash);

  const calculatedSignature = crypto
    .createHash("md5")
    .update(stringToHash)
    .digest("hex")
    .toLowerCase();

  const receivedSignature = (data.signature || "").toLowerCase();

  console.log("🔍 Signature verification result:", {
    received: receivedSignature,
    calculated: calculatedSignature,
    match: calculatedSignature === receivedSignature,
  });

  return calculatedSignature === receivedSignature;
}

async function validateWithPayFast(data) {
  console.log("🌐 Validating with PayFast server...");

  return new Promise((resolve) => {
    const postData = querystring.stringify(data);

    console.log("📤 Validation data to send:", postData);

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

    console.log("🔗 Validation request options:", options);

    const request = https.request(options, (response) => {
      let responseData = "";

      response.on("data", (chunk) => {
        responseData += chunk;
      });

      response.on("end", () => {
        const trimmedResponse = responseData.trim();
        console.log("📥 PayFast validation response:", {
          statusCode: response.statusCode,
          response: trimmedResponse,
          isValid: trimmedResponse === "VALID"
        });
        resolve(trimmedResponse === "VALID");
      });
    });

    request.on("error", (error) => {
      console.error("❌ PayFast validation error:", error);
      resolve(false);
    });

    request.write(postData);
    request.end();
  });
}

async function processPayment(itnData) {
  const paymentId = itnData.m_payment_id;
  const paymentStatus = String(itnData.payment_status || "").toUpperCase();
  const pfPaymentId = itnData.pf_payment_id;
  const amountGross = parseFloat(itnData.amount_gross || 0);

  console.log(`💰 Processing payment: ${paymentId}`);
  console.log(`📊 Payment details:`, {
    paymentId,
    pfPaymentId,
    paymentStatus,
    amountGross,
    itemName: itnData.item_name
  });

  try {
    // Get payment document
    const paymentRef = db.collection("payments").doc(paymentId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      throw new Error(`Payment document ${paymentId} not found in Firestore`);
    }

    const paymentData = paymentDoc.data();
    console.log("📋 Existing payment data:", {
      status: paymentData.status,
      amount: paymentData.amount,
      userId: paymentData.userId,
      createdAt: paymentData.createdAt
    });

    // Check if already processed
    if (paymentData.status === "completed") {
      console.log("⚠️ Payment already processed, skipping");
      return;
    }

    // Validate amount
    const expectedAmount = parseFloat(paymentData.amount);
    if (isNaN(expectedAmount) || isNaN(amountGross)) {
      throw new Error(`Invalid amount values: expected=${expectedAmount}, received=${amountGross}`);
    }

    if (Math.abs(expectedAmount - amountGross) > 0.01) {
      throw new Error(`Amount mismatch: expected ${expectedAmount}, received ${amountGross}`);
    }

    console.log("✅ Amount validation passed");

    // Process based on status
    if (paymentStatus === "COMPLETE") {
      console.log("🎉 Processing successful payment");
      await handleSuccessfulPayment(paymentRef, itnData, paymentData);
    } else {
      console.log(`❌ Processing failed payment with status: ${paymentStatus}`);
      await handleFailedPayment(paymentRef, itnData, paymentStatus);
    }

  } catch (error) {
    console.error("💥 Payment processing error:", error);
    console.error("📋 Error details:", {
      paymentId,
      error: error.message,
      stack: error.stack
    });

    // Log error to Firestore
    await logError("PAYMENT_PROCESSING_ERROR", {
      paymentId,
      error: error.message,
      stack: error.stack,
      itnData,
      timestamp: new Date()
    });

    throw error;
  }
}

async function handleSuccessfulPayment(paymentRef, itnData, paymentData) {
  console.log("🎯 Handling successful payment...");

  try {
    const batch = db.batch();
    const now = new Date();

    // Update payment document
    console.log("📝 Updating payment document...");
    batch.update(paymentRef, {
      status: "completed",
      pfPaymentId: itnData.pf_payment_id,
      paymentDetails: {
        amountGross: parseFloat(itnData.amount_gross),
        amountFee: parseFloat(itnData.amount_fee || 0),
        amountNet: parseFloat(itnData.amount_net || 0),
        paymentStatus: itnData.payment_status,
        paymentDate: itnData.payment_date ? new Date(itnData.payment_date) : now,
        itemName: itnData.item_name,
      },
      completedAt: now,
      processedVia: "itn_webhook",
      updatedAt: now,
    });

    // Extract user and booking data
    const userId = paymentData.userId;
    const bookingDataStr = paymentData.bookingData;

    console.log("👤 User ID:", userId);
    console.log("📋 Booking data string length:", bookingDataStr?.length || 0);

    if (!userId) {
      throw new Error("Missing userId in payment data");
    }

    if (!bookingDataStr) {
      throw new Error("Missing bookingData in payment data");
    }

    let bookingData;
    try {
      bookingData = JSON.parse(bookingDataStr);
      console.log("✅ Parsed booking data:", bookingData);
    } catch (parseError) {
      throw new Error(`Failed to parse booking data: ${parseError.message}`);
    }

    // Get or create user location
    console.log("📍 Getting/creating user location...");
    const locationId = await getOrCreateUserLocation(userId);
    console.log("📍 Location ID:", locationId);

    // Create booking
    console.log("🏠 Creating booking...");
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
      createdAt: now,
      confirmedAt: now,
      paidAt: now,
    };

    console.log("📋 Complete booking data:", completeBookingData);
    batch.set(bookingRef, completeBookingData);

    // Create notification
    console.log("🔔 Creating notification...");
    const notificationRef = db
      .collection("users")
      .doc(userId)
      .collection("notifications")
      .doc();

    batch.set(notificationRef, {
      type: "payment_success",
      title: "Payment Successful!",
      message: `Your booking for ${bookingData.cleaningType || "cleaning service"} has been confirmed.`,
      paymentId: paymentData.paymentId,
      bookingId: bookingRef.id,
      read: false,
      createdAt: now,
    });

    // Commit all changes
    console.log("💾 Committing batch operations...");
    await batch.commit();

    console.log(`🎉 SUCCESS: Payment and booking processed successfully!`);
    console.log(`📍 Booking path: users/${userId}/locations/${locationId}/bookings/${bookingRef.id}`);

    // Log success
    await logSuccess("PAYMENT_COMPLETED", {
      paymentId: paymentData.paymentId,
      userId,
      bookingId: bookingRef.id,
      amount: paymentData.amount
    });

  } catch (error) {
    console.error("💥 Error in handleSuccessfulPayment:", error);
    throw error;
  }
}

async function handleFailedPayment(paymentRef, itnData, paymentStatus) {
  console.log(`❌ Handling failed payment with status: ${paymentStatus}`);

  const now = new Date();

  await paymentRef.update({
    status: "failed",
    pfPaymentId: itnData.pf_payment_id,
    paymentDetails: {
      paymentStatus: paymentStatus,
      failureReason: getFailureReason(paymentStatus),
      amountGross: parseFloat(itnData.amount_gross || 0),
    },
    failedAt: now,
    processedVia: "itn_webhook",
    updatedAt: now,
  });

  console.log(`💥 Payment failed and marked as failed: ${paymentRef.id}`);
}

async function getOrCreateUserLocation(userId) {
  console.log(`📍 Getting/creating location for user: ${userId}`);

  const locationsRef = db.collection("users").doc(userId).collection("locations");
  const locationsSnapshot = await locationsRef.limit(1).get();

  if (!locationsSnapshot.empty) {
    const locationId = locationsSnapshot.docs[0].id;
    console.log(`✅ Found existing location: ${locationId}`);
    return locationId;
  }

  // Create default location
  const locationRef = locationsRef.doc();
  const defaultLocation = {
    lat: -33.918861,
    lng: 18.4233,
    address: "Cape Town, South Africa",
    autoCreated: true,
    createdAt: new Date(),
  };

  await locationRef.set(defaultLocation);

  console.log(`✅ Created default location: ${locationRef.id}`);
  return locationRef.id;
}

function getFailureReason(status) {
  const reasons = {
    CANCELLED: "Payment was cancelled by user",
    FAILED: "Payment failed - insufficient funds or card declined",
    PENDING: "Payment is still being processed",
    EXPIRED: "Payment session expired",
  };
  return reasons[status] || `Payment failed with status: ${status}`;
}

// Utility functions for logging
async function logError(type, data) {
  try {
    await db.collection("payment_errors").add({
      type,
      data,
      timestamp: new Date(),
    });
  } catch (e) {
    console.error("Failed to log error:", e);
  }
}

async function logSuccess(type, data) {
  try {
    await db.collection("payment_logs").add({
      type,
      data,
      timestamp: new Date(),
    });
  } catch (e) {
    console.error("Failed to log success:", e);
  }
}

// Health check endpoint
exports.payfastHealthCheck = onRequest({ cors: true }, (req, res) => {
  const health = {
    status: "healthy",
    timestamp: new Date().toISOString(),
    config: {
      sandbox: PAYFAST_CONFIG.sandbox,
      merchant_id: PAYFAST_CONFIG.merchant_id,
      host: PAYFAST_CONFIG.host,
    },
    environment: {
      node_version: process.version,
      functions_emulator: process.env.FUNCTIONS_EMULATOR === "true",
    }
  };

  console.log("🏥 Health check requested:", health);
  res.json(health);
});

// Callable for client-side verification
exports.verifyPayment = onCall(async (req) => {
  const paymentId = req.data?.paymentId;

  console.log(`🔍 Verification requested for payment: ${paymentId}`);

  if (!paymentId) {
    throw new Error("Payment ID is required");
  }

  const snap = await db.collection("payments").doc(paymentId).get();
  if (!snap.exists) {
    throw new Error("Payment not found");
  }

  const data = snap.data();

  console.log(`✅ Verification result for ${paymentId}:`, {
    status: data.status,
    amount: data.amount
  });

  return {
    paymentId,
    status: data.status,
    amount: data.amount,
    createdAt: data.createdAt,
    completedAt: data.completedAt,
    processedVia: data.processedVia,
  };
});

// Test endpoint for simulating ITN (development only)
exports.simulateITN = onRequest({ cors: true }, async (req, res) => {
  if (!PAYFAST_CONFIG.sandbox) {
    return res.status(403).send("Only available in sandbox mode");
  }

  const { paymentId, status = "COMPLETE" } = req.query;

  if (!paymentId) {
    return res.status(400).send("paymentId query parameter required");
  }

  console.log(`🧪 Simulating ITN for payment: ${paymentId} with status: ${status}`);

  // Get payment to simulate proper ITN data
  const paymentDoc = await db.collection("payments").doc(paymentId).get();
  if (!paymentDoc.exists) {
    return res.status(404).send("Payment not found");
  }

  const paymentData = paymentDoc.data();

  const simulatedITN = {
    m_payment_id: paymentId,
    pf_payment_id: `PF_${Date.now()}`,
    payment_status: status,
    item_name: "Test Payment",
    amount_gross: paymentData.amount.toString(),
    amount_fee: "0.00",
    amount_net: paymentData.amount.toString(),
    signature: "test_signature_for_simulation"
  };

  try {
    await processPayment(simulatedITN);
    res.json({ success: true, message: `ITN simulated for ${paymentId}` });
  } catch (error) {
    console.error("Simulation error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});