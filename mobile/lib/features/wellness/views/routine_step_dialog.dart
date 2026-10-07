import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/database/app_database.dart';

class RoutineStepDialog extends StatefulWidget {
  final RoutineProductModel? initialProduct;
  final String defaultTimeOfDay;
  final Function(Map<String, dynamic> data) onSave;

  const RoutineStepDialog({
    super.key,
    this.initialProduct,
    this.defaultTimeOfDay = 'morning',
    required this.onSave,
  });

  @override
  State<RoutineStepDialog> createState() => _RoutineStepDialogState();
}

class _RoutineStepDialogState extends State<RoutineStepDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _stepController;
  late String _category;
  late String _timeOfDay;

  final List<String> _categories = [
    'Cleanser', 'Toner', 'Serum', 'Moisturizer', 'Sunscreen', 'Treatment', 'Other'
  ];
  final List<String> _timeOptions = ['morning', 'evening', 'both'];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    _nameController = TextEditingController(text: p?.productName ?? '');
    _brandController = TextEditingController(text: p?.brand ?? '');
    _stepController = TextEditingController(text: p != null ? p.routineStep.toString() : '1');
    _category = p?.category ?? 'Cleanser';
    _timeOfDay = p?.timeOfDay ?? widget.defaultTimeOfDay;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final stepNum = int.tryParse(_stepController.text.trim()) ?? 1;
    final data = <String, dynamic>{
      'product_name': _nameController.text.trim(),
      'category': _category,
      'brand': _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      'routine_step': stepNum,
      'time_of_day': _timeOfDay,
      'frequency': 'Daily',
      'enabled': true,
    };

    widget.onSave(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEditing = widget.initialProduct != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colors.surface,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 440),
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
                      isEditing ? 'Edit Routine Step' : 'Add Routine Step',
                      style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Product Name
                TextFormField(
                  controller: _nameController,
                  autofocus: !isEditing,
                  decoration: InputDecoration(
                    labelText: 'Product / Step Name *',
                    hintText: 'e.g. Gentle Hydrating Cleanser, SPF 50',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter product name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category & Time of day
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _timeOfDay,
                        decoration: InputDecoration(
                          labelText: 'Routine',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _timeOptions.map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t[0].toUpperCase() + t.substring(1)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _timeOfDay = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Step sequence & Brand row
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _stepController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Step #',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _brandController,
                        decoration: InputDecoration(
                          labelText: 'Brand (optional)',
                          hintText: 'e.g. CeraVe, COSRX',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
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
                    isEditing ? 'Save Step' : 'Add to Routine',
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
