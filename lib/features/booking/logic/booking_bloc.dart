// lib/features/booking/logic/booking_bloc.dart - FIXED VERSION
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/booking_Repository.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository bookingRepository;
  final Map<String, dynamic> _bookingData = {};

  BookingBloc({required this.bookingRepository}) : super(BookingInitial()) {

    on<SetPropertyInfo>((event, emit) {
      _bookingData.addAll({
        'propertyType': event.propertyType,
        'bedrooms': event.bedrooms,
        'bathrooms': event.bathrooms,
      });
      print("🏠 Property Info Set: $_bookingData"); // Debug log
      emit(BookingDataUpdated(bookingData: Map.from(_bookingData)));
    });

    on<SetCleaningType>((event, emit) {
      _bookingData['cleaningType'] = event.cleaningType;
      print("🧹 Cleaning Type Set: ${event.cleaningType}"); // Debug log
      emit(BookingDataUpdated(bookingData: Map.from(_bookingData)));
    });

    on<SetAddOns>((event, emit) {
      _bookingData['addOns'] = event.addOns;
      print("🔧 Add-ons Set: ${event.addOns}"); // Debug log
      emit(BookingDataUpdated(bookingData: Map.from(_bookingData)));
    });

    on<SetSchedule>((event, emit) {
      _bookingData.addAll({
        'selectedDate': event.selectedDate.toIso8601String(),
        'selectedTime': event.selectedTime,
        'sameCleaner': event.sameCleaner,
      });
      print("📅 Schedule Set: ${event.selectedDate}, ${event.selectedTime}"); // Debug log
      emit(BookingDataUpdated(bookingData: Map.from(_bookingData)));
    });

    on<GetUserLocation>((event, emit) async {
      emit(LocationLoading());
      try {
        final locationId = await bookingRepository.getUserLocationId();
        if (locationId != null) {
          emit(LocationFound(locationId: locationId));
        } else {
          emit(LocationNotFound(message: "No location found. Please set your location first."));
        }
      } catch (e) {
        emit(BookingError(error: "Error getting location: ${e.toString()}"));
      }
    });

    on<SubmitBooking>((event, emit) async {
      emit(BookingLoading());

      // Ensure we have the complete booking data
      final completeBookingData = Map<String, dynamic>.from(_bookingData);
      completeBookingData.addAll(event.bookingData);

      print("📋 Complete booking data before submission: $completeBookingData"); // Debug log

      // Validate required fields
      if (completeBookingData['propertyType'] == null || completeBookingData['propertyType'].toString().isEmpty) {
        emit(BookingError(error: "Please select a property type"));
        return;
      }

      if (completeBookingData['cleaningType'] == null || completeBookingData['cleaningType'].toString().isEmpty) {
        emit(BookingError(error: "Please select a cleaning type"));
        return;
      }

      try {
        await bookingRepository.saveBooking(completeBookingData);
        emit(BookingSuccess(message: "Booking submitted successfully!"));
        _bookingData.clear();
      } catch (e) {
        print("❌ Booking submission error: $e");
        emit(BookingError(error: e.toString()));
      }
    });

    on<ResetBooking>((event, emit) {
      _bookingData.clear();
      emit(BookingInitial());
    });
  }

  Map<String, dynamic> get currentBookingData => Map.from(_bookingData);
}