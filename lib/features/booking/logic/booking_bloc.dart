import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/booking_Repository.dart';
import 'booking_event.dart';
import 'booking_state.dart';


class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository bookingRepository;

  BookingBloc({required this.bookingRepository}) : super(BookingInitial()) {
    on<submitBooking>((event, emit) async {
      emit(BookingSubmitting());
      try {
        await bookingRepository.saveBooking(event.bookingData);
        emit(BookingSuccess());
      } catch (e) {
        emit(BookingFailure(error: e.toString()));
      }
    });
  }
}
