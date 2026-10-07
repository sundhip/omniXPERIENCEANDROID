import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/database/app_database.dart';
import 'learning_repository.dart';

// --- Events ---
abstract class LearningEvent extends Equatable {
  const LearningEvent();
  @override
  List<Object?> get props => [];
}

class LoadLearningData extends LearningEvent {
  final bool forceRefresh;
  const LoadLearningData({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class AddLearningItemEvent extends LearningEvent {
  final Map<String, dynamic> data;
  const AddLearningItemEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateLearningItemEvent extends LearningEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateLearningItemEvent(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteLearningItemEvent extends LearningEvent {
  final String id;
  const DeleteLearningItemEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class AddGoalEvent extends LearningEvent {
  final Map<String, dynamic> data;
  const AddGoalEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateGoalEvent extends LearningEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateGoalEvent(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteGoalEvent extends LearningEvent {
  final String id;
  const DeleteGoalEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleMilestoneEvent extends LearningEvent {
  final String goalId;
  final String milestoneId;
  const ToggleMilestoneEvent(this.goalId, this.milestoneId);
  @override
  List<Object?> get props => [goalId, milestoneId];
}

class RequestGoalPlanEvent extends LearningEvent {
  final String goalId;
  const RequestGoalPlanEvent(this.goalId);
  @override
  List<Object?> get props => [goalId];
}

class ClearGoalPlanEvent extends LearningEvent {
  const ClearGoalPlanEvent();
}

class AddStudySessionEvent extends LearningEvent {
  final Map<String, dynamic> data;
  const AddStudySessionEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class AddKnowledgeNoteEvent extends LearningEvent {
  final Map<String, dynamic> data;
  const AddKnowledgeNoteEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class DeleteKnowledgeNoteEvent extends LearningEvent {
  final String id;
  const DeleteKnowledgeNoteEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class AddProjectEvent extends LearningEvent {
  final Map<String, dynamic> data;
  const AddProjectEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class FilterCategoryChanged extends LearningEvent {
  final String category;
  const FilterCategoryChanged(this.category);
  @override
  List<Object?> get props => [category];
}


// --- States ---
abstract class LearningState extends Equatable {
  const LearningState();
  @override
  List<Object?> get props => [];
}

class LearningInitial extends LearningState {}

class LearningLoading extends LearningState {}

class LearningLoaded extends LearningState {
  final LearnDashboardModel dashboard;
  final List<LearningItemModel> learningItems;
  final List<GoalModel> goals;
  final List<StudySessionModel> sessions;
  final List<KnowledgeNoteModel> notes;
  final List<ProjectModel> projects;
  final String selectedCategory;
  final GoalPlanRecommendationModel? activeGoalPlan;
  final bool isPlanning;

  const LearningLoaded({
    required this.dashboard,
    this.learningItems = const [],
    this.goals = const [],
    this.sessions = const [],
    this.notes = const [],
    this.projects = const [],
    this.selectedCategory = 'All',
    this.activeGoalPlan,
    this.isPlanning = false,
  });

  List<LearningItemModel> get filteredItems {
    if (selectedCategory == 'All') return learningItems;
    return learningItems.where((i) => i.category == selectedCategory).toList();
  }

  List<String> get availableCategories {
    final set = {'All', 'Academic', 'Work', 'Skill', 'Personal', 'Research', 'Project'};
    for (final item in learningItems) {
      set.add(item.category);
    }
    return set.toList();
  }

  LearningLoaded copyWith({
    LearnDashboardModel? dashboard,
    List<LearningItemModel>? learningItems,
    List<GoalModel>? goals,
    List<StudySessionModel>? sessions,
    List<KnowledgeNoteModel>? notes,
    List<ProjectModel>? projects,
    String? selectedCategory,
    GoalPlanRecommendationModel? activeGoalPlan,
    bool? isPlanning,
  }) {
    return LearningLoaded(
      dashboard: dashboard ?? this.dashboard,
      learningItems: learningItems ?? this.learningItems,
      goals: goals ?? this.goals,
      sessions: sessions ?? this.sessions,
      notes: notes ?? this.notes,
      projects: projects ?? this.projects,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      activeGoalPlan: activeGoalPlan ?? this.activeGoalPlan,
      isPlanning: isPlanning ?? this.isPlanning,
    );
  }

  @override
  List<Object?> get props => [
    dashboard, learningItems, goals, sessions, notes, projects,
    selectedCategory, activeGoalPlan, isPlanning
  ];
}

class LearningError extends LearningState {
  final String message;
  const LearningError(this.message);
  @override
  List<Object?> get props => [message];
}


// --- BLoC ---
class LearningBloc extends Bloc<LearningEvent, LearningState> {
  final LearningRepository repository;

  LearningBloc({required this.repository}) : super(LearningInitial()) {
    on<LoadLearningData>(_onLoadLearningData);
    on<AddLearningItemEvent>(_onAddLearningItem);
    on<UpdateLearningItemEvent>(_onUpdateLearningItem);
    on<DeleteLearningItemEvent>(_onDeleteLearningItem);
    on<AddGoalEvent>(_onAddGoal);
    on<UpdateGoalEvent>(_onUpdateGoal);
    on<DeleteGoalEvent>(_onDeleteGoal);
    on<ToggleMilestoneEvent>(_onToggleMilestone);
    on<RequestGoalPlanEvent>(_onRequestGoalPlan);
    on<ClearGoalPlanEvent>(_onClearGoalPlan);
    on<AddStudySessionEvent>(_onAddStudySession);
    on<AddKnowledgeNoteEvent>(_onAddKnowledgeNote);
    on<DeleteKnowledgeNoteEvent>(_onDeleteKnowledgeNote);
    on<AddProjectEvent>(_onAddProjectEvent);
    on<FilterCategoryChanged>(_onFilterCategoryChanged);
  }

  Future<void> _onLoadLearningData(LoadLearningData event, Emitter<LearningState> emit) async {
    if (state is! LearningLoaded) emit(LearningLoading());

    try {
      final dashboard = await repository.getDashboard(forceRefresh: event.forceRefresh);
      final items = await repository.getLearningItems();
      final goals = await repository.getGoals();
      final sessions = await repository.getStudySessions();
      final notes = await repository.getKnowledgeNotes();
      final projects = await repository.getProjects();

      emit(LearningLoaded(
        dashboard: dashboard,
        learningItems: items,
        goals: goals,
        sessions: sessions,
        notes: notes,
        projects: projects,
      ));
    } catch (e) {
      emit(LearningError('Failed to load learning data: $e'));
    }
  }

  Future<void> _onAddLearningItem(AddLearningItemEvent event, Emitter<LearningState> emit) async {
    try {
      await repository.createLearningItem(event.data);
      add(const LoadLearningData(forceRefresh: true));
    } catch (e) {
      emit(LearningError('Failed to add learning item: $e'));
    }
  }

  Future<void> _onUpdateLearningItem(UpdateLearningItemEvent event, Emitter<LearningState> emit) async {
    try {
      await repository.updateLearningItem(event.id, event.data);
      add(const LoadLearningData(forceRefresh: true));
    } catch (e) {
      emit(LearningError('Failed to update learning item: $e'));
    }
  }

  Future<void> _onDeleteLearningItem(DeleteLearningItemEvent event, Emitter<LearningState> emit) async {
    try {
      await repository.deleteLearningItem(event.id);
      add(const LoadLearningData(forceRefresh: true));
    } catch (e) {
      emit(LearningError('Failed to delete learning item: $e'));
    }
  }

  Future<void> _onAddGoal(AddGoalEvent event, Emitter<LearningState> emit) async {
    try {
      await repository.createGoal(event.data);
      add(const LoadLearningData(forceRefresh: true));
    } catch (e) {
      emit(LearningError('Failed to create goal: $e'));
    }
  }

  Future<void> _onUpdateGoal(UpdateGoalEvent event, Emitter<LearningState> emit) async {
    try {
      await repository.updateGoal(event.id, event.data);
      add(const LoadLearningData(forceRefresh: true));
    } catch (e) {
      emit(LearningError('Failed to update goal: $e'));
    }
  }

  Future<void> _onDeleteGoal(DeleteGoalEvent event, Emitter<LearningState> emit) async {
    try {
      await repository.deleteGoal(event.id);
      add(const LoadLearningData(forceRefresh: true));
    } catch (e) {
      emit(LearningError('Failed to delete goal: $e'));
    }
  }

  Future<void> _onToggleMilestone(ToggleMilestoneEvent event, Emitter<LearningState> emit) async {
    try {
      await repository.toggleGoalMilestone(event.goalId, event.milestoneId);
      add(const LoadLearningData(forceRefresh: true));
    } catch (e) {
      emit(LearningError('Failed to toggle milestone: $e'));
    }
  }

  Future<void> _onRequestGoalPlan(RequestGoalPlanEvent event, Emitter<LearningState> emit) async {
    if (state is LearningLoaded) {
      final current = state as LearningLoaded;
      emit(current.copyWith(isPlanning: true));
      try {
        final plan = await repository.planGoal(event.goalId);
        emit(current.copyWith(activeGoalPlan: plan, isPlanning: false));
      } catch (e) {
        emit(current.copyWith(isPlanning: false));
        emit(LearningError('Failed to generate goal plan: $e'));
      }
    }
  }

  void _onClearGoalPlan(ClearGoalPlanEvent event, Emitter<LearningState> emit) {
    if (state is LearningLoaded) {
      final current = state as LearningLoaded;
      emit(current.copyWith(activeGoalPlan: null));
    }
  }

  Future<void> _onAddStudySession(AddStudySessionEvent event, Emitter<LearningState> emit) async {
    try {
      await repository.createStudySession(event.data);
      add(const LoadLearningData(forceRefresh: true));
    } catch (e) {
      emit(LearningError('Failed to log study session: $e'));
    }
  }

  Future<void> _onAddKnowledgeNote(AddKnowledgeNoteEvent event, Emitter<LearningState> emit) async {
    try {
      await repository.createKnowledgeNote(event.data);
      add(const LoadLearningData(forceRefresh: true));
    } catch (e) {
      emit(LearningError('Failed to save knowledge note: $e'));
    }
  }

  Future<void> _onDeleteKnowledgeNote(DeleteKnowledgeNoteEvent event, Emitter<LearningState> emit) async {
    try {
      await repository.deleteKnowledgeNote(event.id);
      add(const LoadLearningData(forceRefresh: true));
    } catch (e) {
      emit(LearningError('Failed to delete note: $e'));
    }
  }

  Future<void> _onAddProjectEvent(AddProjectEvent event, Emitter<LearningState> emit) async {
    try {
      await repository.createProject(event.data);
      add(const LoadLearningData(forceRefresh: true));
    } catch (e) {
      emit(LearningError('Failed to create project: $e'));
    }
  }

  void _onFilterCategoryChanged(FilterCategoryChanged event, Emitter<LearningState> emit) {
    if (state is LearningLoaded) {
      emit((state as LearningLoaded).copyWith(selectedCategory: event.category));
    }
  }
}
