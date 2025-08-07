// lib/features/profile/logic/profile_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;

  ProfileBloc({required this.profileRepository}) : super(ProfileInitial()) {

    on<LoadProfile>((event, emit) async {
      emit(ProfileLoading());
      try {
        if (!profileRepository.isAuthenticated) {
          emit(ProfileError(error: "User not authenticated"));
          return;
        }

        final profileData = await profileRepository.getUserProfile();
        if (profileData == null) {
          emit(ProfileError(error: "Failed to load profile data"));
          return;
        }

        final bookingCount = await profileRepository.getUserBookingCount();

        emit(ProfileLoaded(
          profileData: profileData,
          bookingCount: bookingCount,
        ));
      } catch (e) {
        emit(ProfileError(error: "Failed to load profile: ${e.toString()}"));
      }
    });

    on<RefreshProfile>((event, emit) async {
      // Don't show loading for refresh, just update data
      try {
        if (!profileRepository.isAuthenticated) {
          emit(ProfileError(error: "User not authenticated"));
          return;
        }

        final profileData = await profileRepository.getUserProfile();
        if (profileData == null) {
          emit(ProfileError(error: "Failed to refresh profile data"));
          return;
        }

        final bookingCount = await profileRepository.getUserBookingCount();

        emit(ProfileLoaded(
          profileData: profileData,
          bookingCount: bookingCount,
        ));
      } catch (e) {
        emit(ProfileError(error: "Failed to refresh profile: ${e.toString()}"));
      }
    });

    on<UpdateProfile>((event, emit) async {
      emit(ProfileUpdating());
      try {
        await profileRepository.updateProfile(
          displayName: event.displayName,
          phoneNumber: event.phoneNumber,
          address: event.address,
        );

        emit(ProfileUpdateSuccess(message: "Profile updated successfully!"));

        // Reload profile data
        add(RefreshProfile());
      } catch (e) {
        emit(ProfileError(error: "Failed to update profile: ${e.toString()}"));
      }
    });

    on<UpdateAvatar>((event, emit) async {
      emit(ProfileUpdating());
      try {
        await profileRepository.updatePhotoURL(event.photoURL);

        emit(ProfileUpdateSuccess(message: "Avatar updated successfully!"));

        // Reload profile data
        add(RefreshProfile());
      } catch (e) {
        emit(ProfileError(error: "Failed to update avatar: ${e.toString()}"));
      }
    });

    on<SignOutRequested>((event, emit) async {
      try {
        await profileRepository.signOut();
        emit(ProfileSignedOut());
      } catch (e) {
        emit(ProfileError(error: "Failed to sign out: ${e.toString()}"));
      }
    });

    on<DeleteAccountRequested>((event, emit) async {
      emit(ProfileUpdating());
      try {
        await profileRepository.deleteAccount();
        emit(ProfileDeleted());
      } catch (e) {
        emit(ProfileError(error: "Failed to delete account: ${e.toString()}"));
      }
    });
  }
}