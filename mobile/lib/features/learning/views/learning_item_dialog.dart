import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/database/app_database.dart';

class LearningItemDialog extends StatefulWidget {
  final LearningItemModel? initialItem;
  final List<LearningItemModel> existingItems;
  final Function(Map<String, dynamic> data) onSave;

  const LearningItemDialog({
    super.key,
    this.initialItem,
    this.existingItems = const [],
    required this.onSave,
  });

  @override
  State<LearningItemDialog> createState() => _LearningItemDialogState();
}

class _LearningItemDialogState extends State<LearningItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _durationController;
  late String _type;
  late String _category;
  late String _priority;
  late String _status;
  late double _progress;
  DateTime? _targetDate;
  String? _parentId;

  final List<String> _types = [
    'subject', 'course', 'certification', 'skill', 'topic', 'exam', 'assignment', 'project_task'
  ];
  final List<String> _categories = [
    'Academic', 'Work', 'Skill', 'Personal', 'Research', 'Project'
  ];
  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];
  final List<String> _statuses = ['Not Started', 'In Progress', 'Completed', 'Paused'];

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
    _durationController = TextEditingController(text: (item?.estimatedDurationMinutes ?? 60).toString());
    _type = item?.type ?? 'subject';
    _category = item?.category ?? 'Academic';
    _priority = item?.priority ?? 'Medium';
    _status = item?.status ?? 'Not Started';
    _progress = item?.progress ?? 0.0;
    _targetDate = item?.targetDate;
    _parentId = item?.parentId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final duration = int.tryParse(_durationController.text.trim()) ?? 60;
    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      'type': _type,
      'category': _category,
      'priority': _priority,
      'status': _status,
      'progress': _progress,
      'target_date': _targetDate?.toIso8601String(),
      'estimated_duration_minutes': duration,
      'parent_id': _parentId,
    };

    widget.onSave(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEditing = widget.initialItem != null;

    // Potential parent items (exclude self)
    final parentCandidates = widget.existingItems
        .where((i) => i.id != widget.initialItem?.id && i.parentId == null)
        .toList();

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
                      isEditing ? 'Edit Learning Item' : 'New Learning Item',
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
                    labelText: 'Title *',
                    hintText: 'e.g. Data Structures, React Native, Machine Learning',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter title';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category & Type Row
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
                        value: _type,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _type = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Priority & Status Row
                Row(
                  children: [
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Parent item dropdown (Hierarchical organization)
                if (parentCandidates.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    value: _parentId,
                    decoration: InputDecoration(
                      labelText: 'Parent Subject / Course (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('None (Top Level)')),
                      ...parentCandidates.map((p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.title))),
                    ],
                    onChanged: (val) => setState(() => _parentId = val),
                  ),
                  const SizedBox(height: 16),
                ],

                // Target Deadline
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(
                    _targetDate == null
                        ? 'Set Target Deadline'
                        : 'Deadline: ${_targetDate!.toIso8601String().substring(0, 10)}',
                    style: AppTypography.body,
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _targetDate = picked);
                    },
                    child: Text(_targetDate == null ? 'Select' : 'Change'),
                  ),
                ),
                const SizedBox(height: 8),

                // Progress Slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progress', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
                        Text('${_progress.toInt()}%', style: AppTypography.label.copyWith(color: colors.primary)),
                      ],
                    ),
                    Slider(
                      value: _progress,
                      min: 0.0,
                      max: 100.0,
                      divisions: 20,
                      label: '${_progress.toInt()}%',
                      onChanged: (v) => setState(() => _progress = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Notes / Scope',
                    hintText: 'Syllabus, key topics, or assignment instructions',
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
                    isEditing ? 'Save Learning Item' : 'Add Learning Item',
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
