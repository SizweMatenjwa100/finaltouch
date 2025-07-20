import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  LocationRepository({
    required this.firestore,
    required this.auth,
  });

  Future<void> saveLocation(LatLng latLng, String address) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    // Save under: users/{uid}/locations
    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('locations')
        .add({
      'lat': latLng.latitude,
      'lng': latLng.longitude,
      'address': address,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  Future<bool> userHasLocation() async{
    final user= auth.currentUser;
    if(user==null) throw Exception(" User Not Logged");

    final snapshot = await firestore
    .collection('user')
    .doc(user.uid)
    .collection('locations')
    .limit(1)
    .get();

    return snapshot.docs.isEmpty;

  }
}
