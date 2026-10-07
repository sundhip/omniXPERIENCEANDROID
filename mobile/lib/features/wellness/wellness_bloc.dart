import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/database/app_database.dart';
import 'wellness_repository.dart';

// --- Events ---
abstract class WellnessEvent extends Equatable {
  const WellnessEvent();
  @override
  List<Object?> get props => [];
}

class LoadWellnessData extends WellnessEvent {
  final bool forceRefresh;
  const LoadWellnessData({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class AddHabitEvent extends WellnessEvent {
  final Map<String, dynamic> data;
  const AddHabitEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateHabitEvent extends WellnessEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateHabitEvent(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteHabitEvent extends WellnessEvent {
  final String id;
  const DeleteHabitEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class LogHabitEvent extends WellnessEvent {
  final String habitId;
  final String logDate;
  final String status;
  final int count;

  const LogHabitEvent({
    required this.habitId,
    required this.logDate,
    required this.status,
    this.count = 1,
  });

  @override
  List<Object?> get props => [habitId, logDate, status, count];
}

class SaveSkincareProfileEvent extends WellnessEvent {
  final Map<String, dynamic> data;
  const SaveSkincareProfileEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class AddRoutineStepEvent extends WellnessEvent {
  final Map<String, dynamic> data;
  const AddRoutineStepEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateRoutineStepEvent extends WellnessEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateRoutineStepEvent(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteRoutineStepEvent extends WellnessEvent {
  final String id;
  const DeleteRoutineStepEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleRoutineStepEvent extends WellnessEvent {
  final String id;
  const ToggleRoutineStepEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// --- States ---
abstract class WellnessState extends Equatable {
  const WellnessState();
  @override
  List<Object?> get props => [];
}

class WellnessInitial extends WellnessState {}

class WellnessLoading extends WellnessState {}

class WellnessLoaded extends WellnessState {
  final TodayWellnessModel todayWellness;
  final List<HabitModel> habits;
  final SkincareProfileModel? skincareProfile;
  final List<RoutineProductModel> routines;

  const WellnessLoaded({
    required this.todayWellness,
    required this.habits,
    this.skincareProfile,
    this.routines = const [],
  });

  WellnessLoaded copyWith({
    TodayWellnessModel? todayWellness,
    List<HabitModel>? habits,
    SkincareProfileModel? skincareProfile,
    List<RoutineProductModel>? routines,
  }) {
    return WellnessLoaded(
      todayWellness: todayWellness ?? this.todayWellness,
      habits: habits ?? this.habits,
      skincareProfile: skincareProfile ?? this.skincareProfile,
      routines: routines ?? this.routines,
    );
  }

  @override
  List<Object?> get props => [todayWellness, habits, skincareProfile, routines];
}

class WellnessError extends WellnessState {
  final String message;
  const WellnessError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class WellnessBloc extends Bloc<WellnessEvent, WellnessState> {
  final WellnessRepository repository;

  WellnessBloc({required this.repository}) : super(WellnessInitial()) {
    on<LoadWellnessData>(_onLoadWellnessData);
    on<AddHabitEvent>(_onAddHabit);
    on<UpdateHabitEvent>(_onUpdateHabit);
    on<DeleteHabitEvent>(_onDeleteHabit);
    on<LogHabitEvent>(_onLogHabit);
    on<SaveSkincareProfileEvent>(_onSaveSkincareProfile);
    on<AddRoutineStepEvent>(_onAddRoutineStep);
    on<UpdateRoutineStepEvent>(_onUpdateRoutineStep);
    on<DeleteRoutineStepEvent>(_onDeleteRoutineStep);
    on<ToggleRoutineStepEvent>(_onToggleRoutineStep);
  }

  Future<void> _onLoadWellnessData(LoadWellnessData event, Emitter<WellnessState> emit) async {
    if (state is! WellnessLoaded || event.forceRefresh) {
      emit(WellnessLoading());
    }

    try {
      final today = await repository.getTodayWellness();
      final habits = await repository.getHabits();
      final profile = await repository.getSkincareProfile();
      final routines = await repository.getRoutines();

      emit(WellnessLoaded(
        todayWellness: today,
        habits: habits,
        skincareProfile: profile,
        routines: routines,
      ));
    } catch (e) {
      emit(WellnessError(e.toString()));
    }
  }

  Future<void> _onAddHabit(AddHabitEvent event, Emitter<WellnessState> emit) async {
    try {
      await repository.createHabit(event.data);
      add(const LoadWellnessData(forceRefresh: true));
    } catch (e) {
      emit(WellnessError('Failed to create habit: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateHabit(UpdateHabitEvent event, Emitter<WellnessState> emit) async {
    try {
      await repository.updateHabit(event.id, event.data);
      add(const LoadWellnessData(forceRefresh: true));
    } catch (e) {
      emit(WellnessError('Failed to update habit: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteHabit(DeleteHabitEvent event, Emitter<WellnessState> emit) async {
    try {
      await repository.deleteHabit(event.id);
      add(const LoadWellnessData(forceRefresh: true));
    } catch (e) {
      emit(WellnessError('Failed to delete habit: ${e.toString()}'));
    }
  }

  Future<void> _onLogHabit(LogHabitEvent event, Emitter<WellnessState> emit) async {
    try {
      await repository.logHabit(
        habitId: event.habitId,
        logDate: event.logDate,
        status: event.status,
        count: event.count,
      );
      add(const LoadWellnessData(forceRefresh: true));
    } catch (e) {
      emit(WellnessError('Failed to log habit: ${e.toString()}'));
    }
  }

  Future<void> _onSaveSkincareProfile(SaveSkincareProfileEvent event, Emitter<WellnessState> emit) async {
    try {
      await repository.saveSkincareProfile(event.data);
      add(const LoadWellnessData(forceRefresh: true));
    } catch (e) {
      emit(WellnessError('Failed to save profile: ${e.toString()}'));
    }
  }

  Future<void> _onAddRoutineStep(AddRoutineStepEvent event, Emitter<WellnessState> emit) async {
    try {
      await repository.createRoutineProduct(event.data);
      add(const LoadWellnessData(forceRefresh: true));
    } catch (e) {
      emit(WellnessError('Failed to add routine step: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateRoutineStep(UpdateRoutineStepEvent event, Emitter<WellnessState> emit) async {
    try {
      await repository.updateRoutineProduct(event.id, event.data);
      add(const LoadWellnessData(forceRefresh: true));
    } catch (e) {
      emit(WellnessError('Failed to update routine step: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteRoutineStep(DeleteRoutineStepEvent event, Emitter<WellnessState> emit) async {
    try {
      await repository.deleteRoutineProduct(event.id);
      add(const LoadWellnessData(forceRefresh: true));
    } catch (e) {
      emit(WellnessError('Failed to delete routine step: ${e.toString()}'));
    }
  }

  Future<void> _onToggleRoutineStep(ToggleRoutineStepEvent event, Emitter<WellnessState> emit) async {
    try {
      await repository.toggleRoutineProduct(event.id);
      add(const LoadWellnessData(forceRefresh: true));
    } catch (e) {
      emit(WellnessError('Failed to toggle routine step: ${e.toString()}'));
    }
  }
}
