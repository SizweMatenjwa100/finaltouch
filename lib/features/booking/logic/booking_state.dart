abstract class BookingState{}

class BookingInitial extends BookingState{}
class BookingSubmitting extends BookingState{}
class BookingSuccess extends BookingState{}
class BookingFailure extends BookingState{
  final String  error;
  BookingFailure({required this.error});
}

