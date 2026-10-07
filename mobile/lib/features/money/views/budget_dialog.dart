import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/database/app_database.dart';

class BudgetDialog extends StatefulWidget {
  final BudgetModel? initialBudget;
  final List<String> categories;
  final Function(Map<String, dynamic> data) onSave;

  const BudgetDialog({
    super.key,
    this.initialBudget,
    required this.categories,
    required this.onSave,
  });

  @override
  State<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<BudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    final bgt = widget.initialBudget;
    _amountController = TextEditingController(text: bgt != null ? bgt.amount.toStringAsFixed(0) : '');
    _selectedCategory = bgt?.category ?? 'Total';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amt = double.tryParse(_amountController.text.trim());
    if (amt == null || amt <= 0) return;

    final data = <String, dynamic>{
      'amount': amt.toStringAsFixed(2),
      'category': _selectedCategory == 'Total' ? null : _selectedCategory,
      'period': 'monthly',
      'currency': 'INR',
    };

    widget.onSave(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEditing = widget.initialBudget != null;

    final catOptions = ['Total', ...widget.categories.where((c) => c != 'All')];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colors.surface,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Monthly Budget' : 'Set Monthly Budget',
                    style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Scope / Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: catOptions.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c == 'Total' ? 'Overall Monthly Budget' : c),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'Monthly Limit *',
                  hintText: '15000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter budget amount';
                  final num = double.tryParse(val.trim());
                  if (num == null || num <= 0) return 'Must be a positive amount';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isEditing ? 'Update Budget' : 'Save Budget',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
