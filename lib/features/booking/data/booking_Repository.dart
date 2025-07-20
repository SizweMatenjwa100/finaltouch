import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingRepository{
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  BookingRepository({required this.auth, required this.firestore});

  Future<void> saveBooking(Map<String, dynamic> bookingData) async{
    final uid = auth.currentUser?.uid;
    if(uid==null) throw Exception("User not authenticated");

    await firestore
    .collection('bookings')
    .doc(uid)
    .collection('user_bookings')
    .add({
      ...bookingData,
      'timestamp':FieldValue.serverTimestamp(),
    });
  }
}
