// lib/features/payment/logic/payment_bloc.dart - ITN-DRIVEN VERSION
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/payment_repository.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository paymentRepository;

  PaymentBloc({required this.paymentRepository}) : super(PaymentInitial()) {

    // Handle payment initiation
    on<InitiatePayment>((event, emit) async {
      emit(PaymentInitiating(message: "Setting up payment..."));

      try {
        print("🔄 Initiating payment for amount: ${event.amount}");

        final paymentData = await paymentRepository.initializePayment(
          bookingData: event.bookingData,
          amount: event.amount,
          currency: event.currency,
        );

        print("✅ Payment initialized: ${paymentData['paymentId']}");
        print("🔗 Payment URL: ${paymentData['paymentUrl']}");

        emit(PaymentReady(
          paymentUrl: paymentData['paymentUrl'],
          paymentId: paymentData['paymentId'],
          paymentData: paymentData['paymentData'],
        ));

      } catch (e) {
        print("❌ Payment initiation failed: $e");
        emit(PaymentFailed(
          error: "Failed to initialize payment: ${e.toString()}",
          canRetry: true,
        ));
      }
    });

    // Handle payment retry
    on<RetryPayment>((event, emit) async {
      emit(PaymentInitiating(message: "Retrying payment..."));

      try {
        print("🔄 Retrying payment for amount: ${event.amount}");

        final paymentData = await paymentRepository.initializePayment(
          bookingData: event.bookingData,
          amount: event.amount,
          currency: 'ZAR',
        );

        print("✅ Payment retry successful: ${paymentData['paymentId']}");

        emit(PaymentReady(
          paymentUrl: paymentData['paymentUrl'],
          paymentId: paymentData['paymentId'],
          paymentData: paymentData['paymentData'],
        ));

      } catch (e) {
        print("❌ Payment retry failed: $e");
        emit(PaymentFailed(
          error: "Retry failed: ${e.toString()}",
          canRetry: true,
        ));
      }
    });

    // Handle payment reset
    on<ResetPayment>((event, emit) {
      print("🔄 Resetting payment state");
      emit(PaymentInitial());
    });

    // REMOVED: ProcessPaymentSuccess and ProcessPaymentFailure handlers
    // These are now handled automatically by the ITN webhook
    // The UI monitors Firestore directly for status changes

    // Handle manual verification request (optional)
    on<VerifyPayment>((event, emit) async {
      emit(PaymentProcessing(
        paymentId: event.paymentId,
        message: "Verifying payment status...",
      ));

      try {
        print("🔍 Manually verifying payment: ${event.paymentId}");

        final result = await paymentRepository.verifyPayment(event.paymentId);

        if (result.verified) {
          print("✅ Payment verification successful");
          // Don't emit success here - let the Firestore listener handle it
          // Just emit processing state and let the UI handle the rest
          emit(PaymentProcessing(
            paymentId: event.paymentId,
            message: "Payment verified! Processing...",
          ));
        } else {
          print("❌ Payment verification failed");
          emit(PaymentFailed(
            error: result.message,
            paymentId: event.paymentId,
            canRetry: true,
          ));
        }
      } catch (e) {
        print("❌ Payment verification error: $e");
        emit(PaymentFailed(
          error: "Verification failed: ${e.toString()}",
          paymentId: event.paymentId,
          canRetry: true,
        ));
      }
    });
  }
}