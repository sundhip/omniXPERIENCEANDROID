import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/database/app_database.dart';
import 'money_repository.dart';

// --- Events ---
abstract class MoneyEvent extends Equatable {
  const MoneyEvent();
  @override
  List<Object?> get props => [];
}

class LoadMoneyData extends MoneyEvent {
  final bool forceRefresh;
  const LoadMoneyData({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class AddExpenseEvent extends MoneyEvent {
  final Map<String, dynamic> data;
  const AddExpenseEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateExpenseEvent extends MoneyEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateExpenseEvent(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteExpenseEvent extends MoneyEvent {
  final String id;
  const DeleteExpenseEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class SetBudgetEvent extends MoneyEvent {
  final Map<String, dynamic> data;
  const SetBudgetEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class DeleteBudgetEvent extends MoneyEvent {
  final String id;
  const DeleteBudgetEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class FilterExpensesEvent extends MoneyEvent {
  final String? category;
  final String? search;
  const FilterExpensesEvent({this.category, this.search});
  @override
  List<Object?> get props => [category, search];
}

// --- States ---
abstract class MoneyState extends Equatable {
  const MoneyState();
  @override
  List<Object?> get props => [];
}

class MoneyInitial extends MoneyState {}

class MoneyLoading extends MoneyState {}

class MoneyLoaded extends MoneyState {
  final List<ExpenseModel> allExpenses;
  final List<ExpenseModel> filteredExpenses;
  final List<BudgetModel> budgets;
  final FinancialSummaryModel summary;
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;

  const MoneyLoaded({
    required this.allExpenses,
    required this.filteredExpenses,
    required this.budgets,
    required this.summary,
    required this.categories,
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  MoneyLoaded copyWith({
    List<ExpenseModel>? allExpenses,
    List<ExpenseModel>? filteredExpenses,
    List<BudgetModel>? budgets,
    FinancialSummaryModel? summary,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return MoneyLoaded(
      allExpenses: allExpenses ?? this.allExpenses,
      filteredExpenses: filteredExpenses ?? this.filteredExpenses,
      budgets: budgets ?? this.budgets,
      summary: summary ?? this.summary,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    allExpenses, filteredExpenses, budgets, summary,
    categories, selectedCategory, searchQuery
  ];
}

class MoneyError extends MoneyState {
  final String message;
  const MoneyError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class MoneyBloc extends Bloc<MoneyEvent, MoneyState> {
  final MoneyRepository repository;

  MoneyBloc({required this.repository}) : super(MoneyInitial()) {
    on<LoadMoneyData>(_onLoadMoneyData);
    on<AddExpenseEvent>(_onAddExpense);
    on<UpdateExpenseEvent>(_onUpdateExpense);
    on<DeleteExpenseEvent>(_onDeleteExpense);
    on<SetBudgetEvent>(_onSetBudget);
    on<DeleteBudgetEvent>(_onDeleteBudget);
    on<FilterExpensesEvent>(_onFilterExpenses);
  }

  Future<void> _onLoadMoneyData(LoadMoneyData event, Emitter<MoneyState> emit) async {
    if (state is! MoneyLoaded || event.forceRefresh) {
      emit(MoneyLoading());
    }

    try {
      final expenses = await repository.getExpenses();
      final budgets = await repository.getBudgets();
      final summary = await repository.getSummary(expenses: expenses, budgets: budgets);
      final categories = await repository.getCategories();

      emit(MoneyLoaded(
        allExpenses: expenses,
        filteredExpenses: expenses,
        budgets: budgets,
        summary: summary,
        categories: ['All', ...categories],
      ));
    } catch (e) {
      emit(MoneyError(e.toString()));
    }
  }

  Future<void> _onAddExpense(AddExpenseEvent event, Emitter<MoneyState> emit) async {
    try {
      await repository.createExpense(event.data);
      add(const LoadMoneyData(forceRefresh: true));
    } catch (e) {
      emit(MoneyError('Failed to add expense: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateExpense(UpdateExpenseEvent event, Emitter<MoneyState> emit) async {
    try {
      await repository.updateExpense(event.id, event.data);
      add(const LoadMoneyData(forceRefresh: true));
    } catch (e) {
      emit(MoneyError('Failed to update expense: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteExpense(DeleteExpenseEvent event, Emitter<MoneyState> emit) async {
    try {
      await repository.deleteExpense(event.id);
      add(const LoadMoneyData(forceRefresh: true));
    } catch (e) {
      emit(MoneyError('Failed to delete expense: ${e.toString()}'));
    }
  }

  Future<void> _onSetBudget(SetBudgetEvent event, Emitter<MoneyState> emit) async {
    try {
      await repository.createOrUpdateBudget(event.data);
      add(const LoadMoneyData(forceRefresh: true));
    } catch (e) {
      emit(MoneyError('Failed to set budget: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteBudget(DeleteBudgetEvent event, Emitter<MoneyState> emit) async {
    try {
      await repository.deleteBudget(event.id);
      add(const LoadMoneyData(forceRefresh: true));
    } catch (e) {
      emit(MoneyError('Failed to delete budget: ${e.toString()}'));
    }
  }

  void _onFilterExpenses(FilterExpensesEvent event, Emitter<MoneyState> emit) {
    if (state is! MoneyLoaded) return;
    final current = state as MoneyLoaded;

    final cat = event.category ?? current.selectedCategory;
    final search = (event.search ?? current.searchQuery).toLowerCase().trim();

    final filtered = current.allExpenses.where((exp) {
      final matchesCategory = (cat == 'All' || exp.category == cat);
      final matchesSearch = search.isEmpty ||
          (exp.description?.toLowerCase().contains(search) ?? false) ||
          (exp.merchant?.toLowerCase().contains(search) ?? false) ||
          (exp.category.toLowerCase().contains(search)) ||
          (exp.notes?.toLowerCase().contains(search) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();

    emit(current.copyWith(
      selectedCategory: cat,
      searchQuery: event.search ?? current.searchQuery,
      filteredExpenses: filtered,
    ));
  }
}
