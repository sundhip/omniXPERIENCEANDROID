import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import 'models/user_profile_model.dart';
import 'profile_repository.dart';

// Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfileRequested extends ProfileEvent {}

class UpdateProfileRequested extends ProfileEvent {
  final UserProfileModel profile;
  const UpdateProfileRequested(this.profile);
  @override
  List<Object?> get props => [profile];
}

class SaveOnboardingProfileRequested extends ProfileEvent {
  final UserProfileModel profile;
  const SaveOnboardingProfileRequested(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ResetProfileRequested extends ProfileEvent {}

// States
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfileModel profile;
  final String? successMessage;

  const ProfileLoaded({required this.profile, this.successMessage});

  @override
  List<Object?> get props => [profile, successMessage];
}

class ProfileUpdating extends ProfileState {
  final UserProfileModel currentProfile;

  const ProfileUpdating(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

class ProfileFailure extends ProfileState {
  final String message;

  const ProfileFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    on<LoadProfileRequested>((event, emit) async {
      emit(ProfileLoading());
      try {
        final profile = await repository.getFullProfile();
        emit(ProfileLoaded(profile: profile));
      } catch (e) {
        final message = ApiClient.getErrorMessage(e);
        emit(ProfileFailure(message));
      }
    });

    on<UpdateProfileRequested>((event, emit) async {
      final current = state is ProfileLoaded
          ? (state as ProfileLoaded).profile
          : event.profile;
      emit(ProfileUpdating(current));
      try {
        final updated = await repository.updateFullProfile(event.profile);
        emit(ProfileLoaded(profile: updated, successMessage: 'Profile updated successfully'));
      } catch (e) {
        final message = ApiClient.getErrorMessage(e);
        emit(ProfileFailure(message));
      }
    });

    on<SaveOnboardingProfileRequested>((event, emit) async {
      final updatedProfile = event.profile.copyWith(onboardingCompleted: true);
      emit(ProfileUpdating(updatedProfile));
      try {
        final saved = await repository.updateFullProfile(updatedProfile);
        await SecureStorage.clearOnboardingDraft();
        await SecureStorage.setOnboardingCompleted(true);
        emit(ProfileLoaded(profile: saved, successMessage: 'Onboarding completed'));
      } catch (e) {
        final message = ApiClient.getErrorMessage(e);
        // Ensure local persistence succeeded even if network failed
        await repository.saveCachedProfile(updatedProfile);
        await SecureStorage.setOnboardingCompleted(true);
        emit(ProfileLoaded(profile: updatedProfile, successMessage: 'Saved locally ($message)'));
      }
    });

    on<ResetProfileRequested>((event, emit) {
      emit(ProfileInitial());
    });
  }
}
