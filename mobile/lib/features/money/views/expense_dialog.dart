import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/database/app_database.dart';

class ExpenseDialog extends StatefulWidget {
  final ExpenseModel? initialExpense;
  final List<String> categories;
  final Function(Map<String, dynamic> data) onSave;

  const ExpenseDialog({
    super.key,
    this.initialExpense,
    required this.categories,
    required this.onSave,
  });

  @override
  State<ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<ExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _merchantController;
  late String _selectedCategory;
  late String _selectedPaymentMethod;
  late DateTime _selectedDate;

  final List<String> _paymentMethods = ['UPI', 'Cash', 'Credit Card', 'Debit Card', 'Net Banking', 'Other'];

  @override
  void initState() {
    super.initState();
    final exp = widget.initialExpense;
    _amountController = TextEditingController(text: exp != null ? exp.amount.toStringAsFixed(2) : '');
    _descriptionController = TextEditingController(text: exp?.description ?? '');
    _merchantController = TextEditingController(text: exp?.merchant ?? '');
    
    final validCats = widget.categories.where((c) => c != 'All').toList();
    _selectedCategory = (exp != null && validCats.contains(exp.category))
        ? exp.category
        : (validCats.isNotEmpty ? validCats.first : 'Food');
    _selectedPaymentMethod = exp?.paymentMethod ?? 'UPI';
    _selectedDate = exp?.expenseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amt = double.tryParse(_amountController.text.trim());
    if (amt == null || amt <= 0) return;

    final data = <String, dynamic>{
      'amount': amt.toStringAsFixed(2),
      'currency': 'INR',
      'category': _selectedCategory,
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'merchant': _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim(),
      'expense_date': _selectedDate.toIso8601String(),
      'payment_method': _selectedPaymentMethod,
    };

    widget.onSave(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEditing = widget.initialExpense != null;
    final validCats = widget.categories.where((c) => c != 'All').toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colors.surface,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
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
                      isEditing ? 'Edit Expense' : 'Add Expense',
                      style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: !isEditing,
                  style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    labelText: 'Amount *',
                    hintText: '0.00',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter amount';
                    final num = double.tryParse(val.trim());
                    if (num == null || num <= 0) return 'Enter a valid positive amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: validCats.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker row
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: colors.textSecondary),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                          style: AppTypography.body,
                        ),
                        const Spacer(),
                        Text('Change', style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _paymentMethods.map((m) {
                    return DropdownMenuItem(value: m, child: Text(m));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPaymentMethod = val);
                  },
                ),
                const SizedBox(height: 16),

                // Description (optional)
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'e.g. Lunch with team, Groceries',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Merchant (optional)
                TextFormField(
                  controller: _merchantController,
                  decoration: InputDecoration(
                    labelText: 'Merchant / Store (optional)',
                    hintText: 'e.g. Starbucks, Amazon, Metro',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add Expense',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
