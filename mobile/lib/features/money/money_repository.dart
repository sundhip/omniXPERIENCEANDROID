import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/database/app_database.dart';
import 'financial_calculation_engine.dart';

class MoneyRepository {
  final ApiClient apiClient;

  MoneyRepository({required this.apiClient});

  Future<List<ExpenseModel>> getExpenses({
    String? category,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty && category != 'All') {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final res = await apiClient.dio.get('/expenses', queryParameters: queryParams);
      if (res.statusCode == 200 && res.data is List) {
        final list = (res.data as List).map((x) => ExpenseModel.fromJson(x)).toList();
        await SecureStorage.saveExpensesCache(jsonEncode(res.data));
        return list;
      }
    } catch (_) {
      // Fallback to offline cache
      final cached = await SecureStorage.getExpensesCache();
      if (cached != null) {
        final list = (jsonDecode(cached) as List).map((x) => ExpenseModel.fromJson(x)).toList();
        if (category != null && category.isNotEmpty && category != 'All') {
          return list.where((e) => e.category == category).toList();
        }
        return list;
      }
    }
    return [];
  }

  Future<ExpenseModel> createExpense(Map<String, dynamic> data) async {
    final res = await apiClient.dio.post('/expenses', data: data);
    return ExpenseModel.fromJson(res.data);
  }

  Future<ExpenseModel> updateExpense(String id, Map<String, dynamic> data) async {
    final res = await apiClient.dio.put('/expenses/$id', data: data);
    return ExpenseModel.fromJson(res.data);
  }

  Future<void> deleteExpense(String id) async {
    await apiClient.dio.delete('/expenses/$id');
  }

  Future<List<BudgetModel>> getBudgets() async {
    try {
      final res = await apiClient.dio.get('/budgets');
      if (res.statusCode == 200 && res.data is List) {
        final list = (res.data as List).map((x) => BudgetModel.fromJson(x)).toList();
        await SecureStorage.saveBudgetsCache(jsonEncode(res.data));
        return list;
      }
    } catch (_) {
      final cached = await SecureStorage.getBudgetsCache();
      if (cached != null) {
        return (jsonDecode(cached) as List).map((x) => BudgetModel.fromJson(x)).toList();
      }
    }
    return [];
  }

  Future<BudgetModel> createOrUpdateBudget(Map<String, dynamic> data) async {
    final res = await apiClient.dio.post('/budgets', data: data);
    return BudgetModel.fromJson(res.data);
  }

  Future<void> deleteBudget(String id) async {
    await apiClient.dio.delete('/budgets/$id');
  }

  Future<FinancialSummaryModel> getSummary({
    List<ExpenseModel>? expenses,
    List<BudgetModel>? budgets,
  }) async {
    try {
      final res = await apiClient.dio.get('/finance/summary');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return FinancialSummaryModel.fromJson(res.data);
      }
    } catch (_) {
      // Offline fallback: compute deterministically on client!
      if (expenses != null && budgets != null) {
        return FinancialCalculationEngine.computeSummary(
          expenses: expenses,
          budgets: budgets,
        );
      }
    }

    return FinancialCalculationEngine.computeSummary(
      expenses: expenses ?? [],
      budgets: budgets ?? [],
    );
  }

  Future<List<String>> getCategories() async {
    try {
      final res = await apiClient.dio.get('/finance/categories');
      if (res.statusCode == 200 && res.data is List) {
        return List<String>.from(res.data);
      }
    } catch (_) {}
    return [
      'Food', 'Transport', 'Shopping', 'Education', 'Health',
      'Fitness', 'Entertainment', 'Bills', 'Subscriptions',
      'Travel', 'Personal Care', 'Clothing', 'Technology', 'Other'
    ];
  }
}
