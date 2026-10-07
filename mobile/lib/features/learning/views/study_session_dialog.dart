import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/database/app_database.dart';

class StudySessionDialog extends StatefulWidget {
  final List<LearningItemModel> learningItems;
  final List<GoalModel> goals;
  final Function(Map<String, dynamic> data) onSave;

  const StudySessionDialog({
    super.key,
    this.learningItems = const [],
    this.goals = const [],
    required this.onSave,
  });

  @override
  State<StudySessionDialog> createState() => _StudySessionDialogState();
}

class _StudySessionDialogState extends State<StudySessionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _plannedDurationController;
  late TextEditingController _actualDurationController;
  late TextEditingController _notesController;
  late String _sessionType;
  String? _selectedLearningItemId;
  String? _selectedGoalId;
  final String _status = 'Completed';

  final List<String> _sessionTypes = [
    'Study', 'Coding', 'Project', 'Reading', 'Assignment', 'Research', 'Work', 'Skill'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _plannedDurationController = TextEditingController(text: '45');
    _actualDurationController = TextEditingController(text: '45');
    _notesController = TextEditingController();
    _sessionType = 'Study';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _plannedDurationController.dispose();
    _actualDurationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final planned = int.tryParse(_plannedDurationController.text.trim()) ?? 45;
    final actual = int.tryParse(_actualDurationController.text.trim()) ?? planned;

    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'session_type': _sessionType,
      'planned_duration_minutes': planned,
      'actual_duration_minutes': actual,
      'learning_item_id': _selectedLearningItemId,
      'goal_id': _selectedGoalId,
      'status': _status,
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      'start_time': DateTime.now().toIso8601String(),
    };

    widget.onSave(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
                      'Log Study / Work Session',
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
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Session Focus / Topic *',
                    hintText: 'e.g. Tree Traversal, LeetCode, Research Paper',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter session topic';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Session Type
                DropdownButtonFormField<String>(
                  value: _sessionType,
                  decoration: InputDecoration(
                    labelText: 'Session Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _sessionTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _sessionType = val);
                  },
                ),
                const SizedBox(height: 16),

                // Link to Learning Item (optional)
                if (widget.learningItems.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    value: _selectedLearningItemId,
                    decoration: InputDecoration(
                      labelText: 'Linked Learning Item (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('None')),
                      ...widget.learningItems.map((i) => DropdownMenuItem<String?>(value: i.id, child: Text(i.title))),
                    ],
                    onChanged: (val) => setState(() => _selectedLearningItemId = val),
                  ),
                  const SizedBox(height: 16),
                ],

                // Duration row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _plannedDurationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Planned (min)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _actualDurationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Actual (min)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes / Key Takeaways',
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
                  child: const Text('Log Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
