abstract class BookingDisplayState {}

class BookingDisplayInitial extends BookingDisplayState {}

class BookingDisplayLoading extends BookingDisplayState {}

class BookingDisplayLoaded extends BookingDisplayState {
  final List<Map<String, dynamic>> bookings;
  BookingDisplayLoaded({required this.bookings});
}

class BookingDisplayError extends BookingDisplayState {
  final String error;
  BookingDisplayError({required this.error});
}