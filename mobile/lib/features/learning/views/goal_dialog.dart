import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/database/app_database.dart';

class GoalDialog extends StatefulWidget {
  final GoalModel? initialGoal;
  final Function(Map<String, dynamic> data) onSave;

  const GoalDialog({
    super.key,
    this.initialGoal,
    required this.onSave,
  });

  @override
  State<GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<GoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _financialTargetController;
  late String _category;
  late String _priority;
  late String _status;
  DateTime? _targetDate;
  final List<Map<String, dynamic>> _milestones = [];
  final TextEditingController _newMilestoneController = TextEditingController();

  final List<String> _categories = [
    'Academic', 'Career', 'Financial', 'Fitness', 'Personal', 'Project', 'Learning'
  ];
  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  @override
  void initState() {
    super.initState();
    final g = widget.initialGoal;
    _titleController = TextEditingController(text: g?.title ?? '');
    _descController = TextEditingController(text: g?.description ?? '');
    _financialTargetController = TextEditingController(
      text: g?.financialTargetAmount != null ? g!.financialTargetAmount.toString() : ''
    );
    _category = g?.category ?? 'Personal';
    _priority = g?.priority ?? 'Medium';
    _status = g?.status ?? 'Active';
    _targetDate = g?.targetDate;

    if (g != null && g.milestones.isNotEmpty) {
      for (final m in g.milestones) {
        _milestones.add({
          'id': m.id,
          'title': m.title,
          'completed': m.completed,
          'target_date': m.targetDate,
          'order': m.order,
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _financialTargetController.dispose();
    _newMilestoneController.dispose();
    super.dispose();
  }

  void _addMilestone() {
    final text = _newMilestoneController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _milestones.add({
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'title': text,
        'completed': false,
        'order': _milestones.length + 1,
      });
      _newMilestoneController.clear();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final finTarget = double.tryParse(_financialTargetController.text.trim());
    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      'category': _category,
      'priority': _priority,
      'status': _status,
      'target_date': _targetDate?.toIso8601String(),
      'milestones': _milestones,
      'financial_target_amount': finTarget,
    };

    widget.onSave(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEditing = widget.initialGoal != null;

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
                      isEditing ? 'Edit Goal' : 'Create New Goal',
                      style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleController,
                  autofocus: !isEditing,
                  decoration: InputDecoration(
                    labelText: 'Goal Title *',
                    hintText: 'e.g. Master Flutter, Run Half Marathon, Save ₹50,000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter goal title';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category & Priority Row
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
                        value: _priority,
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _priority = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Target Deadline
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(
                    _targetDate == null
                        ? 'Set Target Date'
                        : 'Target: ${_targetDate!.toIso8601String().substring(0, 10)}',
                    style: AppTypography.body,
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) setState(() => _targetDate = picked);
                    },
                    child: Text(_targetDate == null ? 'Select' : 'Change'),
                  ),
                ),
                const SizedBox(height: 12),

                // Financial Target (Phase 6 link)
                if (_category == 'Financial') ...[
                  TextFormField(
                    controller: _financialTargetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      labelText: 'Savings Target Amount',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Milestones Section
                Text('Milestones', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_milestones.isNotEmpty)
                  ..._milestones.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final m = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            m['completed'] == true ? Icons.check_circle : Icons.circle_outlined,
                            size: 18,
                            color: m['completed'] == true ? colors.primary : colors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(m['title'] ?? '', style: AppTypography.body)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => setState(() => _milestones.removeAt(idx)),
                          ),
                        ],
                      ),
                    );
                  }),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newMilestoneController,
                        decoration: InputDecoration(
                          hintText: 'Add a milestone step...',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onSubmitted: (_) => _addMilestone(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: _addMilestone,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Why this goal matters (Motivation / Plan)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
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
                    isEditing ? 'Save Goal' : 'Create Goal',
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
