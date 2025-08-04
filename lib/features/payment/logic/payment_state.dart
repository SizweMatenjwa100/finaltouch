// lib/features/payment/logic/payment_state.dart
abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentInitiating extends PaymentState {
  final String message;
  PaymentInitiating({this.message = "Initiating payment..."});
}

class PaymentReady extends PaymentState {
  final String paymentUrl;
  final String paymentId;
  final Map<String, dynamic> paymentData;

  PaymentReady({
    required this.paymentUrl,
    required this.paymentId,
    required this.paymentData,
  });
}

class PaymentProcessing extends PaymentState {
  final String paymentId;
  final String message;

  PaymentProcessing({
    required this.paymentId,
    this.message = "Processing payment...",
  });
}

class PaymentSuccess extends PaymentState {
  final String paymentId;
  final String bookingId;
  final Map<String, dynamic> paymentDetails;
  final String message;

  PaymentSuccess({
    required this.paymentId,
    required this.bookingId,
    required this.paymentDetails,
    this.message = "Payment successful! Booking confirmed.",
  });
}

class PaymentFailed extends PaymentState {
  final String error;
  final String? paymentId;
  final bool canRetry;

  PaymentFailed({
    required this.error,
    this.paymentId,
    this.canRetry = true,
  });
}

class PaymentCancelled extends PaymentState {
  final String? paymentId;
  final String message;

  PaymentCancelled({
    this.paymentId,
    this.message = "Payment was cancelled",
  });
}