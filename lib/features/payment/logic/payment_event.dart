// lib/features/payment/logic/payment_event.dart - UPDATED WITH VERIFY EVENT
abstract class PaymentEvent {}

class InitiatePayment extends PaymentEvent {
  final Map<String, dynamic> bookingData;
  final double amount;
  final String currency;

  InitiatePayment({
    required this.bookingData,
    required this.amount,
    this.currency = 'ZAR',
  });
}

class RetryPayment extends PaymentEvent {
  final Map<String, dynamic> bookingData;
  final double amount;

  RetryPayment({
    required this.bookingData,
    required this.amount,
  });
}

class ResetPayment extends PaymentEvent {}

// NEW: Manual verification event
class VerifyPayment extends PaymentEvent {
  final String paymentId;

  VerifyPayment({required this.paymentId});
}

// DEPRECATED: These events are no longer used with ITN webhook
@Deprecated('Payment processing is now handled by ITN webhook')
class ProcessPaymentSuccess extends PaymentEvent {
  final String paymentId;
  final String paymentToken;
  final Map<String, dynamic> paymentDetails;

  ProcessPaymentSuccess({
    required this.paymentId,
    required this.paymentToken,
    required this.paymentDetails,
  });
}

@Deprecated('Payment processing is now handled by ITN webhook')
class ProcessPaymentFailure extends PaymentEvent {
  final String error;
  final String? paymentId;

  ProcessPaymentFailure({
    required this.error,
    this.paymentId,
  });
}