

abstract class BookingEvent{}

class submitBooking extends  BookingEvent{
  final Map<String, dynamic> bookingData;
  submitBooking(this.bookingData);
}
class setPropertyInfo extends BookingEvent{
  final String propertyType;
  final int bedrooms;
  final int bathrooms;

  setPropertyInfo({required this.propertyType,required this.bedrooms, required this.bathrooms});
}