// lib/features/profile/data/profile_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProfileRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth, _firestore = firestore;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Get user document from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();

      // Get user's saved address from locations collection
      String savedAddress = '';
      try {
        final locationsSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('locations')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (locationsSnapshot.docs.isNotEmpty) {
          savedAddress = locationsSnapshot.docs.first.data()['address'] ?? '';
          print("📍 Found saved address: $savedAddress");
        }
      } catch (e) {
        print("⚠️ Error getting saved address: $e");
      }

      if (doc.exists) {
        final data = doc.data()!;
        // Merge Firebase Auth data with Firestore data, prioritizing location address
        return {
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName ?? data['displayName'] ?? '',
          'photoURL': user.photoURL ?? data['photoURL'] ?? '',
          'phoneNumber': data['phoneNumber'] ?? '',
          'address': savedAddress.isNotEmpty ? savedAddress : (data['address'] ?? ''),
          'savedLocationAddress': savedAddress, // Keep original location address
          'createdAt': data['createdAt'] ?? user.metadata.creationTime?.toIso8601String(),
          'lastSignIn': user.metadata.lastSignInTime?.toIso8601String(),
          'emailVerified': user.emailVerified,
        };
      } else {
        // Create basic profile from Firebase Auth data
        final profileData = {
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'phoneNumber': '',
          'address': savedAddress, // Use saved address from locations
          'savedLocationAddress': savedAddress,
          'createdAt': user.metadata.creationTime?.toIso8601String(),
          'lastSignIn': user.metadata.lastSignInTime?.toIso8601String(),
          'emailVerified': user.emailVerified,
        };

        // Save to Firestore for future use
        await _firestore.collection('users').doc(user.uid).set({
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'phoneNumber': '',
          'address': savedAddress, // Save the location address
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return profileData;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  /// Get all user locations/addresses
  Future<List<Map<String, dynamic>>> getUserAddresses() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final locationsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .orderBy('timestamp', descending: true)
          .get();

      return locationsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'address': data['address'] ?? '',
          'lat': data['lat'] ?? 0.0,
          'lng': data['lng'] ?? 0.0,
          'timestamp': data['timestamp'],
          'autoCreated': data['autoCreated'] ?? false,
        };
      }).toList();
    } catch (e) {
      print('Error getting user addresses: $e');
      return [];
    }
  }

  /// Get primary user address (most recent)
  Future<String> getPrimaryAddress() async {
    final addresses = await getUserAddresses();
    if (addresses.isNotEmpty) {
      return addresses.first['address'] as String;
    }
    return '';
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? address,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update Firebase Auth profile if display name changed
      if (displayName != null && displayName != user.displayName) {
        await user.updateDisplayName(displayName);
        updateData['displayName'] = displayName;
      }

      // Update other fields
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (address != null) {
        updateData['address'] = address;

        // Also update the address in the most recent location document if it exists
        try {
          final locationsSnapshot = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('locations')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          if (locationsSnapshot.docs.isNotEmpty) {
            await locationsSnapshot.docs.first.reference.update({
              'address': address,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print("✅ Updated address in location document");
          }
        } catch (e) {
          print("⚠️ Could not update location address: $e");
          // Continue with profile update even if location update fails
        }
      }

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update(updateData);

    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  /// Update user avatar/photo
  Future<void> updatePhotoURL(String photoURL) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await user.updatePhotoURL(photoURL);
      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating photo: $e');
      rethrow;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  /// Get user booking count
  Future<int> getUserBookingCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      // Check all locations for bookings
      final locationsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .get();

      int totalBookings = 0;
      for (final locationDoc in locationsSnapshot.docs) {
        final bookingsSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('locations')
            .doc(locationDoc.id)
            .collection('bookings')
            .get();
        totalBookings += bookingsSnapshot.docs.length;
      }

      // Also check payments collection for completed bookings
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      return totalBookings + paymentsSnapshot.docs.length;
    } catch (e) {
      print('Error getting booking count: $e');
      return 0;
    }
  }
}