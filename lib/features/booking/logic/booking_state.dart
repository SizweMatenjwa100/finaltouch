abstract class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingSuccess extends BookingState {
  final String message;
  BookingSuccess({required this.message});
}

class BookingError extends BookingState {
  final String error;
  BookingError({required this.error});
}

class BookingDataUpdated extends BookingState {
  final Map<String, dynamic> bookingData;
  BookingDataUpdated({required this.bookingData});
}

class LocationLoading extends BookingState {}

class LocationFound extends BookingState {
  final String locationId;
  LocationFound({required this.locationId});
}

class LocationNotFound extends BookingState {
  final String message;
  LocationNotFound({required this.message});
}