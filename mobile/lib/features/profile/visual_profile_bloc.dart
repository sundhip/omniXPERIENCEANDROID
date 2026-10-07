import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'models/visual_profile_model.dart';
import 'visual_profile_repository.dart';

// EVENTS
abstract class VisualProfileEvent extends Equatable {
  const VisualProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadVisualProfileEvent extends VisualProfileEvent {}

class AnalyzeVisualProfileEvent extends VisualProfileEvent {
  final String imagePath;
  const AnalyzeVisualProfileEvent({required this.imagePath});
  @override
  List<Object?> get props => [imagePath];
}

class ConfirmVisualProfileEvent extends VisualProfileEvent {
  final String? faceShape;
  final String? skinTone;
  final String? undertone;
  final String? hairType;
  final String? hairColor;

  const ConfirmVisualProfileEvent({
    this.faceShape,
    this.skinTone,
    this.undertone,
    this.hairType,
    this.hairColor,
  });

  @override
  List<Object?> get props => [faceShape, skinTone, undertone, hairType, hairColor];
}

class DeleteVisualProfileEvent extends VisualProfileEvent {}

class ResetVisualProfileEvent extends VisualProfileEvent {}

// STATES
abstract class VisualProfileState extends Equatable {
  const VisualProfileState();
  @override
  List<Object?> get props => [];
}

class VisualProfileInitial extends VisualProfileState {}

class VisualProfileLoading extends VisualProfileState {}

class VisualProfileAnalyzing extends VisualProfileState {
  final String imagePath;
  final String stageMessage;

  const VisualProfileAnalyzing({
    required this.imagePath,
    this.stageMessage = 'Running computer vision inference...',
  });

  @override
  List<Object?> get props => [imagePath, stageMessage];
}

class VisualProfileReviewing extends VisualProfileState {
  final VisualProfileModel analyzedProfile;
  final String localImagePath;

  const VisualProfileReviewing({
    required this.analyzedProfile,
    required this.localImagePath,
  });

  @override
  List<Object?> get props => [analyzedProfile, localImagePath];
}

class VisualProfileLoaded extends VisualProfileState {
  final VisualProfileModel profile;
  final String? statusMessage;

  const VisualProfileLoaded({
    required this.profile,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [profile, statusMessage];
}

class VisualProfileFailure extends VisualProfileState {
  final String message;
  final VisualProfileModel? previousProfile;

  const VisualProfileFailure({
    required this.message,
    this.previousProfile,
  });

  @override
  List<Object?> get props => [message, previousProfile];
}

// BLOC
class VisualProfileBloc extends Bloc<VisualProfileEvent, VisualProfileState> {
  final VisualProfileRepository repository;

  VisualProfileBloc({required this.repository}) : super(VisualProfileInitial()) {
    on<LoadVisualProfileEvent>((event, emit) async {
      emit(VisualProfileLoading());
      try {
        final profile = await repository.getVisualProfile();
        if (profile != null) {
          emit(VisualProfileLoaded(profile: profile));
        } else {
          emit(VisualProfileInitial());
        }
      } catch (e) {
        emit(VisualProfileFailure(message: e.toString().replaceAll('Exception: ', '')));
      }
    });

    on<AnalyzeVisualProfileEvent>((event, emit) async {
      emit(VisualProfileAnalyzing(
        imagePath: event.imagePath,
        stageMessage: 'Analyzing image quality, face geometry & skin tone...',
      ));
      try {
        final analyzed = await repository.analyzeImage(event.imagePath);
        emit(VisualProfileReviewing(
          analyzedProfile: analyzed,
          localImagePath: event.imagePath,
        ));
      } catch (e) {
        emit(VisualProfileFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ));
      }
    });

    on<ConfirmVisualProfileEvent>((event, emit) async {
      emit(VisualProfileLoading());
      try {
        final confirmed = await repository.confirmVisualProfile(
          confirmedFaceShape: event.faceShape,
          confirmedSkinTone: event.skinTone,
          confirmedUndertone: event.undertone,
          confirmedHairType: event.hairType,
          hairColor: event.hairColor,
        );
        emit(VisualProfileLoaded(
          profile: confirmed,
          statusMessage: 'Visual profile saved and confirmed!',
        ));
      } catch (e) {
        emit(VisualProfileFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ));
      }
    });

    on<DeleteVisualProfileEvent>((event, emit) async {
      emit(VisualProfileLoading());
      try {
        await repository.deleteVisualProfile();
        emit(VisualProfileInitial());
      } catch (e) {
        emit(VisualProfileFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ));
      }
    });

    on<ResetVisualProfileEvent>((event, emit) {
      emit(VisualProfileInitial());
    });
  }
}
