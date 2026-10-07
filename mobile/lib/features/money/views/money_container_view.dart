import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../money_bloc.dart';
import '../financial_calculation_engine.dart';
import 'expense_dialog.dart';
import 'budget_dialog.dart';

class MoneyContainerView extends StatelessWidget {
  const MoneyContainerView({super.key});

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'education':
        return Icons.school;
      case 'health':
        return Icons.local_hospital;
      case 'fitness':
        return Icons.fitness_center;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt_long;
      case 'subscriptions':
        return Icons.subscriptions;
      case 'travel':
        return Icons.flight;
      case 'personal care':
        return Icons.spa;
      case 'clothing':
        return Icons.checkroom;
      case 'technology':
        return Icons.devices;
      default:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<MoneyBloc, MoneyState>(
      builder: (context, state) {
        if (state is MoneyLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is MoneyError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colors.error),
                  const SizedBox(height: 16),
                  const Text('Failed to load financial data', style: AppTypography.h3),
                  const SizedBox(height: 8),
                  Text(state.message, textAlign: TextAlign.center, style: AppTypography.body),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<MoneyBloc>().add(const LoadMoneyData(forceRefresh: true)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! MoneyLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = state.summary;
        final hasBudget = summary.totalBudget != null && summary.totalBudget! > 0.0;
        final remaining = summary.remainingBudget ?? 0.0;
        final pctUsed = summary.budgetUsedPercentage ?? 0.0;

        return Scaffold(
          backgroundColor: colors.background,
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<MoneyBloc>().add(const LoadMoneyData(forceRefresh: true));
            },
            child: CustomScrollView(
              slivers: [
                // Top Header & Summary
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (Navigator.canPop(context)) ...[
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('MONEY & EXPENSES', style: AppTypography.caption.copyWith(letterSpacing: 1.2, color: colors.primary, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text('Financial Overview', style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.account_balance_wallet, size: 20),
                                  tooltip: 'Set Budget',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => BudgetDialog(
                                        categories: state.categories,
                                        onSave: (data) => context.read<MoneyBloc>().add(SetBudgetEvent(data)),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  icon: const Icon(Icons.add, size: 20),
                                  tooltip: 'Add Expense',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => ExpenseDialog(
                                        categories: state.categories,
                                        onSave: (data) => context.read<MoneyBloc>().add(AddExpenseEvent(data)),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Spending Totals row (Today / Week / Month)
                        Row(
                          children: [
                            Expanded(
                              child: _metricCard(
                                context,
                                label: "Today's spending",
                                amount: FinancialCalculationEngine.formatCurrency(summary.todaySpent),
                                icon: Icons.today,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _metricCard(
                                context,
                                label: "This week",
                                amount: FinancialCalculationEngine.formatCurrency(summary.weekSpent),
                                icon: Icons.date_range,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _metricCard(
                                context,
                                label: "This month",
                                amount: FinancialCalculationEngine.formatCurrency(summary.monthSpent),
                                icon: Icons.calendar_month,
                                highlight: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Budget Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.pie_chart_outline, size: 20, color: colors.primary),
                                      const SizedBox(width: 8),
                                      Text('Monthly Budget', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => BudgetDialog(
                                          categories: state.categories,
                                          onSave: (data) => context.read<MoneyBloc>().add(SetBudgetEvent(data)),
                                        ),
                                      );
                                    },
                                    child: Text(hasBudget ? 'Edit Limit' : 'Set Budget'),
                                  ),
                                ],
                              ),
                              if (hasBudget) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Remaining: ${FinancialCalculationEngine.formatCurrency(remaining)}',
                                      style: AppTypography.body.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: remaining >= 0 ? colors.success : colors.error,
                                      ),
                                    ),
                                    Text(
                                      '${pctUsed.toStringAsFixed(1)}% of ${FinancialCalculationEngine.formatCurrency(summary.totalBudget!)}',
                                      style: AppTypography.label,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: (pctUsed / 100.0).clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: colors.background,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      pctUsed > 100 ? colors.error : (pctUsed > 80 ? colors.warning : colors.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Daily avg: ${FinancialCalculationEngine.formatCurrency(summary.dailyAverage)}', style: AppTypography.caption),
                                    Text('Projected: ${FinancialCalculationEngine.formatCurrency(summary.projectedMonthSpent)}', style: AppTypography.caption),
                                  ],
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Set a monthly limit to track spending against your goals.',
                                  style: AppTypography.body.copyWith(color: colors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Insights Card (if any)
                        if (summary.insights.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.primarySoft.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb_outline, size: 20, color: colors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        summary.insights.first.title,
                                        style: AppTypography.label.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        summary.insights.first.description,
                                        style: AppTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Category Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: state.categories.map((cat) {
                              final isSelected = state.selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    context.read<MoneyBloc>().add(FilterExpensesEvent(category: cat));
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Recent Transactions Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Transactions', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
                            Text('${state.filteredExpenses.length} entries', style: AppTypography.label),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Transactions List
                if (state.filteredExpenses.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 56, color: colors.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text('No expenses yet', style: AppTypography.h3),
                          const SizedBox(height: 4),
                          const Text('Tap + to log your first expense', style: AppTypography.caption),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Expense'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => ExpenseDialog(
                                  categories: state.categories,
                                  onSave: (data) => context.read<MoneyBloc>().add(AddExpenseEvent(data)),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final exp = state.filteredExpenses[index];
                        final dateStr = '${exp.expenseDate.year}-${exp.expenseDate.month.toString().padLeft(2, '0')}-${exp.expenseDate.day.toString().padLeft(2, '0')}';

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border.withOpacity(0.6)),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.primarySoft.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getCategoryIcon(exp.category), color: colors.primary, size: 20),
                            ),
                            title: Text(
                              exp.description?.isNotEmpty == true ? exp.description! : exp.category,
                              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${exp.category} • $dateStr ${exp.merchant != null ? '• ${exp.merchant}' : ''}',
                              style: AppTypography.caption,
                            ),
                            trailing: Text(
                              FinancialCalculationEngine.formatCurrency(exp.amount),
                              style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => ExpenseDialog(
                                  initialExpense: exp,
                                  categories: state.categories,
                                  onSave: (data) => context.read<MoneyBloc>().add(UpdateExpenseEvent(exp.id, data)),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: state.filteredExpenses.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required String label,
    required String amount,
    required IconData icon,
    bool highlight = false,
  }) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? colors.primary.withOpacity(0.08) : colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlight ? colors.primary.withOpacity(0.3) : colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: highlight ? colors.primary : colors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: colors.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: highlight ? colors.primary : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
