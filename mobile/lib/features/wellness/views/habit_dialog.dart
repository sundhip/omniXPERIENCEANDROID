import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/database/app_database.dart';

class HabitDialog extends StatefulWidget {
  final HabitModel? initialHabit;
  final Function(Map<String, dynamic> data) onSave;

  const HabitDialog({
    super.key,
    this.initialHabit,
    required this.onSave,
  });

  @override
  State<HabitDialog> createState() => _HabitDialogState();
}

class _HabitDialogState extends State<HabitDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetController;
  late TextEditingController _unitController;
  late String _frequency;
  late String _category;

  final List<String> _frequencies = ['Daily', 'Weekly', 'Custom'];
  final List<String> _categories = [
    'General', 'Hydration', 'Fitness', 'Skincare', 'Mindfulness', 'Sleep', 'Study'
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.initialHabit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _descriptionController = TextEditingController(text: h?.description ?? '');
    _targetController = TextEditingController(text: h != null ? h.target.toString() : '1');
    _unitController = TextEditingController(text: h?.unit ?? 'times');
    _frequency = h?.frequency ?? 'Daily';
    _category = h?.category ?? 'General';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final targetVal = int.tryParse(_targetController.text.trim()) ?? 1;
    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'frequency': _frequency,
      'target': targetVal,
      'unit': _unitController.text.trim().isEmpty ? 'times' : _unitController.text.trim(),
      'category': _category,
    };

    widget.onSave(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEditing = widget.initialHabit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colors.surface,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 460),
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
                      isEditing ? 'Edit Habit' : 'New Habit',
                      style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameController,
                  autofocus: !isEditing,
                  decoration: InputDecoration(
                    labelText: 'Habit Name *',
                    hintText: 'e.g. Drink water, 30 min walk, Read',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter habit name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category & Frequency row
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
                        value: _frequency,
                        decoration: InputDecoration(
                          labelText: 'Frequency',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _frequency = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Target and Unit row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _targetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Daily Target',
                          hintText: '1',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          hintText: 'glasses, mins',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description (optional)
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
                    isEditing ? 'Save Habit' : 'Create Habit',
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
