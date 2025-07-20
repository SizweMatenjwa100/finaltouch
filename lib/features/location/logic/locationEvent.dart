import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object> get props => [];
}

class SaveLocationEvent extends LocationEvent {
  final LatLng latLng;
  final String address;

  const SaveLocationEvent({required this.latLng, required this.address});

  @override
  List<Object> get props => [latLng, address];
}
class CheckLocationEvent extends LocationEvent{}
