// lib/features/payment/logic/payment_bloc.dart
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

    // Handle successful payment processing
    on<ProcessPaymentSuccess>((event, emit) async {
      emit(PaymentProcessing(
        paymentId: event.paymentId,
        message: "Confirming payment and creating booking...",
      ));

      try {
        print("🔄 Processing successful payment: ${event.paymentId}");

        final bookingId = await paymentRepository.processSuccessfulPayment(
          paymentId: event.paymentId,
          paymentToken: event.paymentToken,
          paymentDetails: event.paymentDetails,
        );

        print("✅ Payment processed and booking created: $bookingId");

        emit(PaymentSuccess(
          paymentId: event.paymentId,
          bookingId: bookingId,
          paymentDetails: event.paymentDetails,
          message: "Payment successful! Your booking has been confirmed.",
        ));

      } catch (e) {
        print("❌ Payment processing failed: $e");
        emit(PaymentFailed(
          error: "Payment succeeded but booking failed: ${e.toString()}",
          paymentId: event.paymentId,
          canRetry: false, // Don't retry if payment already went through
        ));
      }
    });

    // Handle failed payment
    on<ProcessPaymentFailure>((event, emit) async {
      try {
        if (event.paymentId != null) {
          await paymentRepository.processFailedPayment(
            paymentId: event.paymentId!,
            error: event.error,
          );
        }

        print("💥 Payment failed: ${event.error}");

        emit(PaymentFailed(
          error: event.error,
          paymentId: event.paymentId,
          canRetry: true,
        ));

      } catch (e) {
        print("❌ Error handling payment failure: $e");
        emit(PaymentFailed(
          error: "Payment failed: ${event.error}",
          paymentId: event.paymentId,
          canRetry: true,
        ));
      }
    });

    // Handle payment retry
    on<RetryPayment>((event, emit) async {
      emit(PaymentInitiating(message: "Retrying payment..."));

      try {
        final paymentData = await paymentRepository.initializePayment(
          bookingData: event.bookingData,
          amount: event.amount,
          currency: 'ZAR',
        );

        emit(PaymentReady(
          paymentUrl: paymentData['paymentUrl'],
          paymentId: paymentData['paymentId'],
          paymentData: paymentData['paymentData'],
        ));

      } catch (e) {
        emit(PaymentFailed(
          error: "Retry failed: ${e.toString()}",
          canRetry: true,
        ));
      }
    });

    // Handle payment reset
    on<ResetPayment>((event, emit) {
      emit(PaymentInitial());
    });
  }
}