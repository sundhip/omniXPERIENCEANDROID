import 'package:flutter_test/flutter_test.dart';
import 'package:omnipresence/core/database/app_database.dart';
import 'package:omnipresence/features/money/financial_calculation_engine.dart';
import 'package:omnipresence/features/wellness/wellness_routine_engine.dart';

void main() {
  group('Phase 6 — Money Calculations & Financial Engine', () {
    test('Calculates exact spending totals: ₹100 + ₹250 = ₹350', () {
      final now = DateTime(2026, 10, 7, 14, 0);
      final expenses = [
        ExpenseModel(
          id: 'exp1',
          userId: 'u1',
          amount: 100.0,
          expenseDate: now,
          category: 'Food',
          createdAt: now,
          updatedAt: now,
        ),
        ExpenseModel(
          id: 'exp2',
          userId: 'u1',
          amount: 250.0,
          expenseDate: now,
          category: 'Transport',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final summary = FinancialCalculationEngine.computeSummary(
        expenses: expenses,
        budgets: [],
        referenceDate: now,
      );

      expect(summary.todaySpent, 350.0);
      expect(summary.monthSpent, 350.0);
      expect(summary.totalBudget, isNull);
      expect(summary.remainingBudget, isNull);
    });

    test('Accurately computes budget metrics: ₹10,000 budget, ₹2,500 spent', () {
      final now = DateTime(2026, 10, 15, 12, 0);
      final expenses = [
        ExpenseModel(
          id: 'exp1',
          userId: 'u1',
          amount: 2500.0,
          expenseDate: now,
          category: 'Shopping',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final budgets = [
        BudgetModel(
          id: 'bgt1',
          userId: 'u1',
          amount: 10000.0,
          category: 'Total',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final summary = FinancialCalculationEngine.computeSummary(
        expenses: expenses,
        budgets: budgets,
        referenceDate: now,
      );

      // Prompt checks: Budget = 10,000, Spent = 2,500, Remaining = 7,500, 25%
      expect(summary.monthSpent, 2500.0);
      expect(summary.totalBudget, 10000.0);
      expect(summary.remainingBudget, 7500.0);
      expect(summary.budgetUsedPercentage, 25.0);
    });

    test('Zero budget protection prevents NaN or Infinite calculations', () {
      final now = DateTime(2026, 10, 7);
      final expenses = [
        ExpenseModel(
          id: 'exp1',
          userId: 'u1',
          amount: 500.0,
          expenseDate: now,
          category: 'Food',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final zeroBudgets = [
        BudgetModel(
          id: 'bgt_zero',
          userId: 'u1',
          amount: 0.0,
          category: 'Total',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final summary = FinancialCalculationEngine.computeSummary(
        expenses: expenses,
        budgets: zeroBudgets,
        referenceDate: now,
      );

      expect(summary.monthSpent, 500.0);
      expect(summary.totalBudget, isNull);
      expect(summary.remainingBudget, isNull);
      expect(summary.budgetUsedPercentage, isNull);
    });

    test('Currency formatting handles positive, negative, and commas properly', () {
      expect(FinancialCalculationEngine.formatCurrency(350.0), '₹350.00');
      expect(FinancialCalculationEngine.formatCurrency(15000.0), '₹15,000.00');
      expect(FinancialCalculationEngine.formatCurrency(-75.50), '-₹75.50');
    });
  });

  group('Phase 6 — Wellness & Truthful Streak Engine', () {
    test('Calculates truthful streak: consecutive completions vs missed day', () {
      final refDate = DateTime(2026, 10, 7);
      final habit = HabitModel(
        id: 'hbt_water',
        userId: 'u1',
        name: 'Drink water',
        target: 8,
        unit: 'glasses',
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      // Case 1: 3 consecutive days completed (Oct 5, Oct 6, Oct 7)
      final consecutiveLogs = [
        {'habit_id': 'hbt_water', 'log_date': '2026-10-07', 'status': 'Completed'},
        {'habit_id': 'hbt_water', 'log_date': '2026-10-06', 'status': 'Completed'},
        {'habit_id': 'hbt_water', 'log_date': '2026-10-05', 'status': 'Completed'},
      ];

      final res1 = WellnessRoutineEngine.calculateStreak(
        habit: habit,
        logs: consecutiveLogs,
        referenceDate: refDate,
      );

      expect(res1['currentStreak'], 3);
      expect(res1['completedToday'], true);

      // Case 2: Yesterday (Oct 6) was missed -> streak resets to 1 (only Oct 7)
      final brokenLogs = [
        {'habit_id': 'hbt_water', 'log_date': '2026-10-07', 'status': 'Completed'},
        {'habit_id': 'hbt_water', 'log_date': '2026-10-06', 'status': 'Missed'},
        {'habit_id': 'hbt_water', 'log_date': '2026-10-05', 'status': 'Completed'},
        {'habit_id': 'hbt_water', 'log_date': '2026-10-04', 'status': 'Completed'},
      ];

      final res2 = WellnessRoutineEngine.calculateStreak(
        habit: habit,
        logs: brokenLogs,
        referenceDate: refDate,
      );

      expect(res2['currentStreak'], 1);
      expect(res2['longestStreak'], 2); // Oct 4 and Oct 5
    });
  });

  group('Phase 6 — Models Serialization', () {
    test('ExpenseModel serializes and deserializes accurately', () {
      final now = DateTime(2026, 10, 7, 10, 30);
      final json = {
        'id': 'exp_123',
        'user_id': 'user_abc',
        'amount': '450.50',
        'currency': 'INR',
        'category': 'Shopping',
        'description': 'Books',
        'expense_date': now.toIso8601String(),
        'payment_method': 'UPI',
        'merchant': 'Amazon',
        'tags': ['education', 'reading'],
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final model = ExpenseModel.fromJson(json);
      expect(model.id, 'exp_123');
      expect(model.amount, 450.50);
      expect(model.category, 'Shopping');
      expect(model.merchant, 'Amazon');

      final serialized = model.toJson();
      expect(serialized['amount'], '450.50');
      expect(serialized['category'], 'Shopping');
    });

    test('RoutineProductModel and HabitModel serialize accurately', () {
      final pJson = {
        'id': 'rtn_1',
        'user_id': 'user_1',
        'product_name': 'Hydrating Cleanser',
        'category': 'Cleanser',
        'routine_step': 1,
        'time_of_day': 'morning',
        'frequency': 'Daily',
        'enabled': true,
      };

      final product = RoutineProductModel.fromJson(pJson);
      expect(product.productName, 'Hydrating Cleanser');
      expect(product.routineStep, 1);
      expect(product.timeOfDay, 'morning');

      final hJson = {
        'id': 'hbt_1',
        'user_id': 'user_1',
        'name': 'Exercise',
        'frequency': 'Daily',
        'target': 30,
        'unit': 'minutes',
        'current_streak': 5,
        'completion_rate': 85.0,
      };

      final habit = HabitModel.fromJson(hJson);
      expect(habit.name, 'Exercise');
      expect(habit.target, 30);
      expect(habit.currentStreak, 5);
      expect(habit.completionRate, 85.0);
    });
  });
}
