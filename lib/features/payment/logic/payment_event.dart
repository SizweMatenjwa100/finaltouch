
abstract class PaymentEvent {}

class InitiatePayment extends PaymentEvent {
  final String bookingId;
  final String locationId;
  final double amount;
  final String itemName;
  final String itemDescription;
  final Map<String, dynamic> bookingData;

  InitiatePayment({
    required this.bookingId,
    required this.locationId,
    required this.amount,
    required this.itemName,
    required this.itemDescription,
    required this.bookingData,
  });
}

class ProcessPaymentCallback extends PaymentEvent {
  final String merchantOrderId;
  final String paymentStatus;
  final Map<String, dynamic> callbackData;

  ProcessPaymentCallback({
    required this.merchantOrderId,
    required this.paymentStatus,
    required this.callbackData,
  });
}

class CheckPaymentStatus extends PaymentEvent {
  final String merchantOrderId;

  CheckPaymentStatus({required this.merchantOrderId});
}

class LoadPaymentHistory extends PaymentEvent {}

class ResetPayment extends PaymentEvent {}