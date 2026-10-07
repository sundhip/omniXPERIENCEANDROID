import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/database/app_database.dart';
import 'productivity_repository.dart';
import 'productivity_priority_engine.dart';
import 'productivity_notification_service.dart';

// --- EVENTS ---

abstract class ProductivityEvent extends Equatable {
  const ProductivityEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductivityData extends ProductivityEvent {
  final bool forceRefresh;
  const LoadProductivityData({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class SelectDateEvent extends ProductivityEvent {
  final DateTime date;
  const SelectDateEvent(this.date);

  @override
  List<Object?> get props => [date];
}

class CreateEventAction extends ProductivityEvent {
  final EventModel event;
  const CreateEventAction(this.event);

  @override
  List<Object?> get props => [event];
}

class UpdateEventAction extends ProductivityEvent {
  final EventModel event;
  const UpdateEventAction(this.event);

  @override
  List<Object?> get props => [event];
}

class DeleteEventAction extends ProductivityEvent {
  final String eventId;
  const DeleteEventAction(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class CreateTaskAction extends ProductivityEvent {
  final TaskModel task;
  const CreateTaskAction(this.task);

  @override
  List<Object?> get props => [task];
}

class UpdateTaskAction extends ProductivityEvent {
  final TaskModel task;
  const UpdateTaskAction(this.task);

  @override
  List<Object?> get props => [task];
}

class ToggleTaskCompletionAction extends ProductivityEvent {
  final String taskId;
  const ToggleTaskCompletionAction(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class DeleteTaskAction extends ProductivityEvent {
  final String taskId;
  const DeleteTaskAction(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class SetFilterCategoryAction extends ProductivityEvent {
  final String? category;
  const SetFilterCategoryAction(this.category);

  @override
  List<Object?> get props => [category];
}

class SetTaskTabAction extends ProductivityEvent {
  final String tab; // 'Today', 'Upcoming', 'Overdue', 'Completed'
  const SetTaskTabAction(this.tab);

  @override
  List<Object?> get props => [tab];
}

// --- STATES ---

abstract class ProductivityState extends Equatable {
  const ProductivityState();

  @override
  List<Object?> get props => [];
}

class ProductivityInitial extends ProductivityState {}

class ProductivityLoading extends ProductivityState {}

class ProductivityLoaded extends ProductivityState {
  final List<EventModel> allEvents;
  final List<TaskModel> allTasks;
  final DateTime selectedDate;
  final String? selectedCategory;
  final String activeTaskTab;

  final List<EventModel> selectedDayEvents;
  final List<EventModel> todayEvents;
  final List<TaskModel> todayTasks;
  final List<TaskModel> overdueTasks;
  final List<TaskModel> upcomingDeadlines;
  final List<TaskModel> completedTasks;
  final List<TaskModel> filteredTasks;

  final List<ClientScheduleConflict> conflicts;
  final List<ClientTimeBlock> freeBlocks;
  final List<ClientTaskSlotSuggestion> suggestedSlots;
  final Map<String, ClientPriorityAssessment> priorityAssessments;
  final String summaryMessage;

  const ProductivityLoaded({
    required this.allEvents,
    required this.allTasks,
    required this.selectedDate,
    this.selectedCategory,
    this.activeTaskTab = 'Today',
    required this.selectedDayEvents,
    required this.todayEvents,
    required this.todayTasks,
    required this.overdueTasks,
    required this.upcomingDeadlines,
    required this.completedTasks,
    required this.filteredTasks,
    required this.conflicts,
    required this.freeBlocks,
    required this.suggestedSlots,
    required this.priorityAssessments,
    required this.summaryMessage,
  });

  ProductivityLoaded copyWith({
    List<EventModel>? allEvents,
    List<TaskModel>? allTasks,
    DateTime? selectedDate,
    String? selectedCategory,
    String? activeTaskTab,
    List<EventModel>? selectedDayEvents,
    List<EventModel>? todayEvents,
    List<TaskModel>? todayTasks,
    List<TaskModel>? overdueTasks,
    List<TaskModel>? upcomingDeadlines,
    List<TaskModel>? completedTasks,
    List<TaskModel>? filteredTasks,
    List<ClientScheduleConflict>? conflicts,
    List<ClientTimeBlock>? freeBlocks,
    List<ClientTaskSlotSuggestion>? suggestedSlots,
    Map<String, ClientPriorityAssessment>? priorityAssessments,
    String? summaryMessage,
  }) {
    return ProductivityLoaded(
      allEvents: allEvents ?? this.allEvents,
      allTasks: allTasks ?? this.allTasks,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      activeTaskTab: activeTaskTab ?? this.activeTaskTab,
      selectedDayEvents: selectedDayEvents ?? this.selectedDayEvents,
      todayEvents: todayEvents ?? this.todayEvents,
      todayTasks: todayTasks ?? this.todayTasks,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      upcomingDeadlines: upcomingDeadlines ?? this.upcomingDeadlines,
      completedTasks: completedTasks ?? this.completedTasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      conflicts: conflicts ?? this.conflicts,
      freeBlocks: freeBlocks ?? this.freeBlocks,
      suggestedSlots: suggestedSlots ?? this.suggestedSlots,
      priorityAssessments: priorityAssessments ?? this.priorityAssessments,
      summaryMessage: summaryMessage ?? this.summaryMessage,
    );
  }

  @override
  List<Object?> get props => [
    allEvents, allTasks, selectedDate, selectedCategory, activeTaskTab,
    selectedDayEvents, todayEvents, todayTasks, overdueTasks, conflicts, suggestedSlots
  ];
}

class ProductivityError extends ProductivityState {
  final String message;
  const ProductivityError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLOC ---

class ProductivityBloc extends Bloc<ProductivityEvent, ProductivityState> {
  final ProductivityRepository repository;
  final ProductivityNotificationService notificationService;

  ProductivityBloc({
    required this.repository,
    required this.notificationService,
  }) : super(ProductivityInitial()) {
    on<LoadProductivityData>(_onLoadData);
    on<SelectDateEvent>(_onSelectDate);
    on<CreateEventAction>(_onCreateEvent);
    on<UpdateEventAction>(_onUpdateEvent);
    on<DeleteEventAction>(_onDeleteEvent);
    on<CreateTaskAction>(_onCreateTask);
    on<UpdateTaskAction>(_onUpdateTask);
    on<ToggleTaskCompletionAction>(_onToggleTaskCompletion);
    on<DeleteTaskAction>(_onDeleteTask);
    on<SetFilterCategoryAction>(_onSetFilterCategory);
    on<SetTaskTabAction>(_onSetTaskTab);
  }

  Future<void> _onLoadData(
    LoadProductivityData event,
    Emitter<ProductivityState> emit,
  ) async {
    if (state is ProductivityInitial || event.forceRefresh) {
      emit(ProductivityLoading());
    }

    try {
      final events = await repository.getEvents();
      final tasks = await repository.getTasks();

      final now = DateTime.now();
      final currentDate = state is ProductivityLoaded
          ? (state as ProductivityLoaded).selectedDate
          : DateTime(now.year, now.month, now.day);
      final category = state is ProductivityLoaded
          ? (state as ProductivityLoaded).selectedCategory
          : null;
      final tab = state is ProductivityLoaded
          ? (state as ProductivityLoaded).activeTaskTab
          : 'Today';

      emit(_buildLoadedState(
        allEvents: events,
        allTasks: tasks,
        selectedDate: currentDate,
        category: category,
        tab: tab,
      ));
    } catch (e) {
      emit(ProductivityError('Unable to load schedule: $e'));
    }
  }

  void _onSelectDate(SelectDateEvent event, Emitter<ProductivityState> emit) {
    if (state is ProductivityLoaded) {
      final s = state as ProductivityLoaded;
      emit(_buildLoadedState(
        allEvents: s.allEvents,
        allTasks: s.allTasks,
        selectedDate: event.date,
        category: s.selectedCategory,
        tab: s.activeTaskTab,
      ));
    }
  }

  Future<void> _onCreateEvent(CreateEventAction event, Emitter<ProductivityState> emit) async {
    try {
      final created = await repository.createEvent(event.event);
      await notificationService.scheduleEventReminders(created);
      add(const LoadProductivityData(forceRefresh: false));
    } catch (e) {
      emit(ProductivityError('Failed to create event: $e'));
    }
  }

  Future<void> _onUpdateEvent(UpdateEventAction event, Emitter<ProductivityState> emit) async {
    try {
      final updated = await repository.updateEvent(event.event);
      await notificationService.scheduleEventReminders(updated);
      add(const LoadProductivityData(forceRefresh: false));
    } catch (e) {
      emit(ProductivityError('Failed to update event: $e'));
    }
  }

  Future<void> _onDeleteEvent(DeleteEventAction event, Emitter<ProductivityState> emit) async {
    try {
      await repository.deleteEvent(event.eventId);
      await notificationService.cancelRemindersForEntity(event.eventId);
      add(const LoadProductivityData(forceRefresh: false));
    } catch (e) {
      emit(ProductivityError('Failed to delete event: $e'));
    }
  }

  Future<void> _onCreateTask(CreateTaskAction event, Emitter<ProductivityState> emit) async {
    try {
      final created = await repository.createTask(event.task);
      await notificationService.scheduleTaskReminders(created);
      add(const LoadProductivityData(forceRefresh: false));
    } catch (e) {
      emit(ProductivityError('Failed to create task: $e'));
    }
  }

  Future<void> _onUpdateTask(UpdateTaskAction event, Emitter<ProductivityState> emit) async {
    try {
      final updated = await repository.updateTask(event.task);
      await notificationService.scheduleTaskReminders(updated);
      add(const LoadProductivityData(forceRefresh: false));
    } catch (e) {
      emit(ProductivityError('Failed to update task: $e'));
    }
  }

  Future<void> _onToggleTaskCompletion(ToggleTaskCompletionAction event, Emitter<ProductivityState> emit) async {
    if (state is ProductivityLoaded) {
      // Optimistic update
      final s = state as ProductivityLoaded;
      final updatedTasks = s.allTasks.map((t) {
        if (t.id == event.taskId) {
          final isDone = t.status == 'Completed';
          return t.copyWith(
            status: isDone ? 'Todo' : 'Completed',
            completedAt: isDone ? null : DateTime.now(),
          );
        }
        return t;
      }).toList();

      emit(_buildLoadedState(
        allEvents: s.allEvents,
        allTasks: updatedTasks,
        selectedDate: s.selectedDate,
        category: s.selectedCategory,
        tab: s.activeTaskTab,
      ));
    }

    try {
      await repository.toggleTaskCompletion(event.taskId);
    } catch (_) {}
  }

  Future<void> _onDeleteTask(DeleteTaskAction event, Emitter<ProductivityState> emit) async {
    try {
      await repository.deleteTask(event.taskId);
      await notificationService.cancelRemindersForEntity(event.taskId);
      add(const LoadProductivityData(forceRefresh: false));
    } catch (e) {
      emit(ProductivityError('Failed to delete task: $e'));
    }
  }

  void _onSetFilterCategory(SetFilterCategoryAction event, Emitter<ProductivityState> emit) {
    if (state is ProductivityLoaded) {
      final s = state as ProductivityLoaded;
      emit(_buildLoadedState(
        allEvents: s.allEvents,
        allTasks: s.allTasks,
        selectedDate: s.selectedDate,
        category: event.category,
        tab: s.activeTaskTab,
      ));
    }
  }

  void _onSetTaskTab(SetTaskTabAction event, Emitter<ProductivityState> emit) {
    if (state is ProductivityLoaded) {
      final s = state as ProductivityLoaded;
      emit(_buildLoadedState(
        allEvents: s.allEvents,
        allTasks: s.allTasks,
        selectedDate: s.selectedDate,
        category: s.selectedCategory,
        tab: event.tab,
      ));
    }
  }

  ProductivityLoaded _buildLoadedState({
    required List<EventModel> allEvents,
    required List<TaskModel> allTasks,
    required DateTime selectedDate,
    String? category,
    required String tab,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final nextDay = targetDay.add(const Duration(days: 1));

    // Category filter
    var filteredEvents = allEvents;
    var filteredTasksList = allTasks;
    if (category != null && category.isNotEmpty && category != 'All') {
      filteredEvents = filteredEvents.where((e) => e.category == category).toList();
      filteredTasksList = filteredTasksList.where((t) => t.category == category).toList();
    }

    // Selected day events
    final selectedDayEvents = filteredEvents.where((e) {
      return (e.startTime.isBefore(nextDay) && e.endTime.isAfter(targetDay));
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Today events
    final todayEvents = filteredEvents.where((e) {
      final endOfToday = today.add(const Duration(days: 1));
      return (e.startTime.isBefore(endOfToday) && e.endTime.isAfter(today));
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Tasks categorization
    final todayTasks = <TaskModel>[];
    final overdueTasks = <TaskModel>[];
    final upcomingDeadlines = <TaskModel>[];
    final completedTasks = <TaskModel>[];

    for (final t in filteredTasksList) {
      if (t.status == 'Completed') {
        completedTasks.add(t);
        if (t.completedAt != null &&
            t.completedAt!.year == today.year &&
            t.completedAt!.month == today.month &&
            t.completedAt!.day == today.day) {
          todayTasks.add(t);
        }
        continue;
      }

      if (t.dueDate != null) {
        final dDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        if (t.dueDate!.isBefore(now) && dDate.isBefore(today)) {
          overdueTasks.add(t);
        } else if (dDate.isAtSameMomentAs(today)) {
          todayTasks.add(t);
        } else if (t.dueDate!.isAfter(now) && t.dueDate!.difference(now).inHours <= 48) {
          upcomingDeadlines.add(t);
        }
      }

      if (t.priority == 'Urgent' || t.priority == 'High') {
        if (!todayTasks.contains(t) && !overdueTasks.contains(t)) {
          todayTasks.add(t);
        }
      }
    }

    // Filter tasks by active tab
    List<TaskModel> tabTasks;
    switch (tab) {
      case 'Upcoming':
        tabTasks = filteredTasksList.where((t) => t.status != 'Completed' && (t.dueDate?.isAfter(now) ?? false)).toList();
        break;
      case 'Overdue':
        tabTasks = overdueTasks;
        break;
      case 'Completed':
        tabTasks = completedTasks;
        break;
      case 'Today':
      default:
        tabTasks = todayTasks;
        break;
    }

    // Schedule conflicts on today
    final conflicts = ProductivityPriorityEngine.detectConflicts(todayEvents);

    // Free time blocks today (08:00 to 21:00)
    final workStart = DateTime(today.year, today.month, today.day, 8, 0);
    final workEnd = DateTime(today.year, today.month, today.day, 21, 0);
    final freeBlocks = ProductivityPriorityEngine.identifyFreeBlocks(todayEvents, workStart, workEnd);

    // Smart task slot suggestions
    final suggestedSlots = ProductivityPriorityEngine.suggestTaskSlots(
      freeBlocks,
      todayTasks + overdueTasks,
    );

    // Priority assessments
    final assessments = <String, ClientPriorityAssessment>{};
    for (final t in filteredTasksList) {
      if (t.status != 'Completed') {
        assessments[t.id] = ProductivityPriorityEngine.calculate(t, filteredTasksList, now: now);
      }
    }

    // Natural summary message
    final summaryParts = <String>[];
    if (todayEvents.isNotEmpty) {
      summaryParts.add("${todayEvents.length} event${todayEvents.length > 1 ? 's' : ''}");
    }
    if (todayTasks.isNotEmpty) {
      summaryParts.add("${todayTasks.length} task${todayTasks.length > 1 ? 's' : ''}");
    }
    if (overdueTasks.isNotEmpty) {
      summaryParts.add("${overdueTasks.length} overdue");
    }
    if (conflicts.isNotEmpty) {
      summaryParts.add("${conflicts.length} conflict");
    }

    final summary = summaryParts.isNotEmpty
        ? "Today's schedule: ${summaryParts.join(', ')}."
        : "Your day is clear. You have no scheduled events or pending tasks.";

    return ProductivityLoaded(
      allEvents: allEvents,
      allTasks: allTasks,
      selectedDate: selectedDate,
      selectedCategory: category,
      activeTaskTab: tab,
      selectedDayEvents: selectedDayEvents,
      todayEvents: todayEvents,
      todayTasks: todayTasks,
      overdueTasks: overdueTasks,
      upcomingDeadlines: upcomingDeadlines,
      completedTasks: completedTasks,
      filteredTasks: tabTasks,
      conflicts: conflicts,
      freeBlocks: freeBlocks,
      suggestedSlots: suggestedSlots,
      priorityAssessments: assessments,
      summaryMessage: summary,
    );
  }
}
