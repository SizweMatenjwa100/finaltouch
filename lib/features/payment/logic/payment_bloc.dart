// lib/features/payment/logic/payment_bloc.dart - FIXED VERSION WITH DEBUG
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/payment_repository.dart';
import '../../../services/payfast_service.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository paymentRepository;

  PaymentBloc({required this.paymentRepository}) : super(PaymentInitial()) {

    on<InitiatePayment>((event, emit) async {
      print("🎯 InitiatePayment event received");
      print("📊 Booking data: ${event.bookingData}");
      print("💰 Amount: ${event.amount}");

      emit(PaymentLoading());

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          print("❌ User not authenticated");
          emit(PaymentFailed(error: "User not authenticated"));
          return;
        }

        print("✅ User authenticated: ${user.uid}");

        // Generate unique order ID
        final merchantOrderId = PayFastService.generateOrderId();
        print("🆔 Generated Order ID: $merchantOrderId");

        // Validate amount
        if (!PayFastService.isValidAmount(event.amount)) {
          print("❌ Invalid amount: ${event.amount}");
          emit(PaymentFailed(error: "Minimum payment amount is R5.00"));
          return;
        }

        print("✅ Amount validated: ${event.amount}");

        // Get user names safely
        final displayName = user.displayName ?? 'Customer User';
        final nameParts = displayName.split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : 'Customer';
        final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : 'User';

        print("👤 User details - First: $firstName, Last: $lastName, Email: ${user.email}");

        // Generate PayFast payment data
        final paymentData = PayFastService.generatePaymentData(
          merchantOrderId: merchantOrderId,
          amount: event.amount,
          itemName: event.itemName,
          itemDescription: event.itemDescription,
          buyerFirstName: firstName,
          buyerLastName: lastName,
          buyerEmail: user.email ?? 'customer@example.com',
          returnUrl: 'https://yourapp.com/payment/success',
          cancelUrl: 'https://yourapp.com/payment/cancel',
          notifyUrl: 'https://yourapp.com/payment/notify',
        );

        print("💳 Payment data generated: $paymentData");

        // Save payment record
        final paymentRecord = {
          ...event.bookingData,
          'locationId': event.locationId,
          'paymentData': paymentData,
          'userInfo': {
            'firstName': firstName,
            'lastName': lastName,
            'email': user.email,
          }
        };

        await paymentRepository.savePaymentRecord(
          bookingId: event.bookingId,
          merchantOrderId: merchantOrderId,
          amount: event.amount,
          status: 'initiated',
          paymentData: paymentRecord,
        );

        print("💾 Payment record saved successfully");
        print("🚀 Emitting PaymentInitiated state");

        emit(PaymentInitiated(
          merchantOrderId: merchantOrderId,
          paymentUrl: PayFastService.paymentUrl,
          paymentData: paymentData,
        ));

      } catch (e) {
        print("❌ Payment initiation error: $e");
        print("📍 Stack trace: ${StackTrace.current}");
        emit(PaymentFailed(error: e.toString()));
      }
    });

    on<ProcessPaymentCallback>((event, emit) async {
      print("🔄 Processing payment callback: ${event.merchantOrderId} - ${event.paymentStatus}");
      emit(PaymentLoading());

      try {
        await paymentRepository.processPaymentCallback(
          merchantOrderId: event.merchantOrderId,
          paymentStatus: event.paymentStatus,
          callbackData: event.callbackData,
        );

        switch (event.paymentStatus.toLowerCase()) {
          case 'complete':
            print("✅ Payment completed successfully");
            emit(PaymentSuccess(
              merchantOrderId: event.merchantOrderId,
              message: "Payment completed successfully!",
            ));
            break;
          case 'failed':
            print("❌ Payment failed");
            emit(PaymentFailed(
              error: "Payment failed. Please try again.",
              merchantOrderId: event.merchantOrderId,
            ));
            break;
          case 'cancelled':
            print("🚫 Payment cancelled");
            emit(PaymentCancelled(merchantOrderId: event.merchantOrderId));
            break;
          default:
            print("⏳ Payment pending: ${event.paymentStatus}");
            emit(PaymentPending(
              merchantOrderId: event.merchantOrderId,
              message: "Payment is being processed...",
            ));
        }

      } catch (e) {
        print("❌ Payment callback processing error: $e");
        emit(PaymentError(error: e.toString()));
      }
    });

    on<CheckPaymentStatus>((event, emit) async {
      print("🔍 Checking payment status for: ${event.merchantOrderId}");
      try {
        final paymentRecord = await paymentRepository.getPaymentByOrderId(
          event.merchantOrderId,
        );

        if (paymentRecord == null) {
          print("❌ Payment record not found");
          emit(PaymentError(error: "Payment record not found"));
          return;
        }

        final status = paymentRecord['status'] as String;
        print("📊 Payment status: $status");

        switch (status.toLowerCase()) {
          case 'complete':
            emit(PaymentSuccess(
              merchantOrderId: event.merchantOrderId,
              message: "Payment completed successfully!",
            ));
            break;
          case 'failed':
            emit(PaymentFailed(
              error: "Payment failed",
              merchantOrderId: event.merchantOrderId,
            ));
            break;
          case 'cancelled':
            emit(PaymentCancelled(merchantOrderId: event.merchantOrderId));
            break;
          default:
            emit(PaymentPending(
              merchantOrderId: event.merchantOrderId,
              message: "Payment is being processed...",
            ));
        }

      } catch (e) {
        print("❌ Error checking payment status: $e");
        emit(PaymentError(error: e.toString()));
      }
    });

    on<LoadPaymentHistory>((event, emit) async {
      print("📋 Loading payment history");
      emit(PaymentLoading());

      try {
        final payments = await paymentRepository.getUserPayments();
        print("📊 Found ${payments.length} payments");
        emit(PaymentHistoryLoaded(payments: payments));
      } catch (e) {
        print("❌ Error loading payment history: $e");
        emit(PaymentError(error: e.toString()));
      }
    });

    on<ResetPayment>((event, emit) {
      print("🔄 Resetting payment state");
      emit(PaymentInitial());
    });
  }
}