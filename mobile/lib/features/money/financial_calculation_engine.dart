import '../../core/database/app_database.dart';

class FinancialCalculationEngine {
  /// Deterministic financial calculations on the mobile client.
  /// Zero-budget protected, safeguards against NaN / Infinite.

  static double roundDec(double val, [int places = 2]) {
    final mod = (val * 100).round() / 100;
    return mod;
  }

  static String formatCurrency(double amount, {String symbol = '₹'}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Format with commas (Indian/standard thousands)
    final buffer = StringBuffer();
    final len = integerPart.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }

    final formatted = '$symbol${buffer.toString()}.$decimalPart';
    return isNegative ? '-$formatted' : formatted;
  }

  static FinancialSummaryModel computeSummary({
    required List<ExpenseModel> expenses,
    required List<BudgetModel> budgets,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));

    double todaySpent = 0.0;
    double weekSpent = 0.0;
    double monthSpent = 0.0;
    final Map<String, double> categoryTotals = {};
    final Map<String, int> categoryCounts = {};

    for (final exp in expenses) {
      final expDate = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);
      final amt = exp.amount;

      if (expDate.isAtSameMomentAs(todayStart)) {
        todaySpent += amt;
      }

      if (!expDate.isBefore(weekStart) && !expDate.isAfter(todayStart)) {
        weekSpent += amt;
      }

      if (exp.expenseDate.year == now.year && exp.expenseDate.month == now.month) {
        monthSpent += amt;
        final cat = exp.category.isEmpty ? 'Other' : exp.category;
        categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + amt;
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
      }
    }

    double? totalBudget;
    final Map<String, double> categoryBudgets = {};
    for (final b in budgets) {
      if (b.amount <= 0.0) continue;
      if (b.category == null ||
          b.category!.isEmpty ||
          b.category!.toLowerCase() == 'total' ||
          b.category!.toLowerCase() == 'overall') {
        totalBudget = b.amount;
      } else {
        categoryBudgets[b.category!] = b.amount;
      }
    }

    double? remainingBudget;
    double? budgetUsedPct;
    if (totalBudget != null && totalBudget > 0.0) {
      remainingBudget = roundDec(totalBudget - monthSpent);
      budgetUsedPct = roundDec((monthSpent / totalBudget) * 100.0);
    }

    // Days in month calculation
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.day > 0 ? now.day : 1;
    final daysRemaining = (daysInMonth - daysElapsed) > 0 ? (daysInMonth - daysElapsed) : 0;

    final dailyAvg = roundDec(monthSpent / daysElapsed);
    final projectedMonth = roundDec(dailyAvg * daysInMonth);

    // Category breakdown
    final allCats = <String>{...categoryTotals.keys, ...categoryBudgets.keys}.toList()..sort();
    final breakdowns = <CategorySpendingModel>[];
    for (final cat in allCats) {
      final spent = roundDec(categoryTotals[cat] ?? 0.0);
      final bAmt = categoryBudgets[cat];
      double? pct;
      if (bAmt != null && bAmt > 0.0) {
        pct = roundDec((spent / bAmt) * 100.0);
      }
      breakdowns.add(CategorySpendingModel(
        category: cat,
        spent: spent,
        budget: bAmt != null ? roundDec(bAmt) : null,
        percentageUsed: pct,
        transactionCount: categoryCounts[cat] ?? 0,
      ));
    }

    // Sort recent transactions
    final sortedRecent = List<ExpenseModel>.from(expenses)
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    return FinancialSummaryModel(
      currency: 'INR',
      todaySpent: roundDec(todaySpent),
      weekSpent: roundDec(weekSpent),
      monthSpent: roundDec(monthSpent),
      totalBudget: totalBudget != null ? roundDec(totalBudget) : null,
      remainingBudget: remainingBudget,
      budgetUsedPercentage: budgetUsedPct,
      dailyAverage: dailyAvg,
      projectedMonthSpent: projectedMonth,
      daysElapsed: daysElapsed,
      daysRemaining: daysRemaining,
      categoryBreakdown: breakdowns,
      recentTransactions: sortedRecent.take(10).toList(),
      insights: const [],
    );
  }
}
