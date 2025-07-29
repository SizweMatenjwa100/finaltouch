abstract class BookingEvent {}

class SetPropertyInfo extends BookingEvent {
  final String propertyType;
  final int bedrooms;
  final int bathrooms;

  SetPropertyInfo({
    required this.propertyType,
    required this.bedrooms,
    required this.bathrooms,
  });
}

class SetCleaningType extends BookingEvent {
  final String cleaningType;
  SetCleaningType({required this.cleaningType});
}

class SetAddOns extends BookingEvent {
  final Map<String, bool> addOns;
  SetAddOns({required this.addOns});
}

class SetSchedule extends BookingEvent {
  final DateTime selectedDate;
  final String selectedTime;
  final bool sameCleaner;

  SetSchedule({
    required this.selectedDate,
    required this.selectedTime,
    required this.sameCleaner,
  });
}

class SubmitBooking extends BookingEvent {
  final Map<String, dynamic> bookingData;
  SubmitBooking(this.bookingData);
}

class GetUserLocation extends BookingEvent {}

class ResetBooking extends BookingEvent {}