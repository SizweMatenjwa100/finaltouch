// lib/features/profile/logic/profile_event.dart
abstract class ProfileEvent {}

class LoadProfile extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final String? displayName;
  final String? phoneNumber;
  final String? address;

  UpdateProfile({
    this.displayName,
    this.phoneNumber,
    this.address,
  });
}

class UpdateAvatar extends ProfileEvent {
  final String photoURL;
  UpdateAvatar({required this.photoURL});
}

class SignOutRequested extends ProfileEvent {}

class DeleteAccountRequested extends ProfileEvent {}

class RefreshProfile extends ProfileEvent {}