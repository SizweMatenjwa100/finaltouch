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
      emit(BookingDataUpdated(bookingData: Map.from(_bookingData)));
    });

    on<SetCleaningType>((event, emit) {
      _bookingData['cleaningType'] = event.cleaningType;
      emit(BookingDataUpdated(bookingData: Map.from(_bookingData)));
    });

    on<SetAddOns>((event, emit) {
      _bookingData['addOns'] = event.addOns;
      emit(BookingDataUpdated(bookingData: Map.from(_bookingData)));
    });

    on<SetSchedule>((event, emit) {
      _bookingData.addAll({
        'selectedDate': event.selectedDate.toIso8601String(),
        'selectedTime': event.selectedTime,
        'sameCleaner': event.sameCleaner,
      });
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
      try {
        await bookingRepository.saveBooking(event.bookingData);
        emit(BookingSuccess(message: "Booking submitted successfully!"));
        _bookingData.clear();
      } catch (e) {
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