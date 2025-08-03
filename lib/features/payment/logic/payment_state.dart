
abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentInitiated extends PaymentState {
  final String merchantOrderId;
  final String paymentUrl;
  final Map<String, String> paymentData;

  PaymentInitiated({
    required this.merchantOrderId,
    required this.paymentUrl,
    required this.paymentData,
  });
}

class PaymentSuccess extends PaymentState {
  final String merchantOrderId;
  final String message;

  PaymentSuccess({
    required this.merchantOrderId,
    required this.message,
  });
}

class PaymentFailed extends PaymentState {
  final String error;
  final String? merchantOrderId;

  PaymentFailed({
    required this.error,
    this.merchantOrderId,
  });
}

class PaymentCancelled extends PaymentState {
  final String merchantOrderId;

  PaymentCancelled({required this.merchantOrderId});
}

class PaymentPending extends PaymentState {
  final String merchantOrderId;
  final String message;

  PaymentPending({
    required this.merchantOrderId,
    required this.message,
  });
}

class PaymentHistoryLoaded extends PaymentState {
  final List<Map<String, dynamic>> payments;

  PaymentHistoryLoaded({required this.payments});
}

class PaymentError extends PaymentState {
  final String error;

  PaymentError({required this.error});
}
