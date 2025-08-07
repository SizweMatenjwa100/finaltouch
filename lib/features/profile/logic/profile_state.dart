// lib/features/profile/logic/profile_state.dart
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> profileData;
  final int bookingCount;

  ProfileLoaded({
    required this.profileData,
    required this.bookingCount,
  });

  String get displayName => profileData['displayName'] as String? ?? '';
  String get email => profileData['email'] as String? ?? '';
  String get phoneNumber => profileData['phoneNumber'] as String? ?? '';
  String get address => profileData['address'] as String? ?? '';
  String get photoURL => profileData['photoURL'] as String? ?? '';
  bool get emailVerified => profileData['emailVerified'] as bool? ?? false;
  String get uid => profileData['uid'] as String? ?? '';
}

class ProfileUpdating extends ProfileState {}

class ProfileUpdateSuccess extends ProfileState {
  final String message;
  ProfileUpdateSuccess({required this.message});
}

class ProfileError extends ProfileState {
  final String error;
  ProfileError({required this.error});
}

class ProfileSignedOut extends ProfileState {}

class ProfileDeleted extends ProfileState {}