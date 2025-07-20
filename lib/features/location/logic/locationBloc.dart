import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/location_repository.dart';
import 'locationEvent.dart';
import 'locationState.dart';


class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository locationRepository;

  LocationBloc({required this.locationRepository}) : super(LocationInitial()) {
    on<SaveLocationEvent>(_onSaveLocation);
    on<CheckLocationEvent>(_onCheckLocation);
  }

  Future<void> _onSaveLocation(
      SaveLocationEvent event,
      Emitter<LocationState> emit,
      ) async {
    emit(LocationSaving());

    try {
      await locationRepository.saveLocation(event.latLng, event.address);
      emit(LocationSaved());
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }
  Future<void> _onCheckLocation(
      CheckLocationEvent event,
      Emitter<LocationState> emit,
      ) async{
    emit(LocationSaving());
    try{
      final hasLocation= await locationRepository.userHasLocation();
      if(hasLocation){
        emit(LocationExists());
      } else{
        emit (LocationNotFound());

      }
    } catch (e){
      emit (LocationError(e.toString()));
    }

  }
}
