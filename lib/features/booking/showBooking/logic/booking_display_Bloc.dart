import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/booking_display_repository.dart';
import 'booking_display_event.dart';
import 'booking_display_state.dart';

class BookingDisplayBloc extends Bloc<BookingDisplayEvent, BookingDisplayState> {
  final BookingDisplayRepository bookingDisplayRepository;

  BookingDisplayBloc({required this.bookingDisplayRepository}) : super(BookingDisplayInitial()) {

    on<LoadBookings>((event, emit) async {
      emit(BookingDisplayLoading());
      try {
        final bookings = await bookingDisplayRepository.getUserBookings();
        emit(BookingDisplayLoaded(bookings: bookings));
      } catch (e) {
        emit(BookingDisplayError(error: e.toString()));
      }
    });

    on<RefreshBookings>((event, emit) async {
      emit(BookingDisplayLoading());
      try {
        final bookings = await bookingDisplayRepository.getUserBookings();
        emit(BookingDisplayLoaded(bookings: bookings));
      } catch (e) {
        emit(BookingDisplayError(error: e.toString()));
      }
    });
  }
}