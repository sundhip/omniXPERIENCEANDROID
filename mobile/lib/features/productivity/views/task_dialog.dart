import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_geometry.dart';
import '../../../shared/components/app_button.dart';
import '../../../shared/components/app_text_field.dart';

class TaskDialog extends StatefulWidget {
  final TaskModel? initialTask;
  final List<TaskModel> allTasks;
  final Function(TaskModel) onSave;

  const TaskDialog({
    super.key,
    this.initialTask,
    this.allTasks = const [],
    required this.onSave,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  late String _priority;
  late String _category;
  late int _estimatedDurationMinutes;
  late List<String> _selectedDependencies;
  late List<int> _reminderMinutes;

  final List<String> _categories = [
    'College', 'Work', 'Personal', 'Health', 'Fitness', 'Finance', 'Errands', 'Projects', 'Other'
  ];
  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];
  final List<int> _durations = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    final t = widget.initialTask;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _dueDate = t?.dueDate;
    if (t?.dueTime != null && t!.dueTime!.contains(':')) {
      final parts = t.dueTime!.split(':');
      _dueTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 12, minute: int.tryParse(parts[1]) ?? 0);
    }
    _priority = t?.priority ?? 'Medium';
    _category = t?.category ?? 'Personal';
    _estimatedDurationMinutes = t?.estimatedDurationMinutes ?? 30;
    _selectedDependencies = t != null ? List<String>.from(t.dependencyTaskIds) : [];
    _reminderMinutes = t != null ? List<int>.from(t.reminderSettings) : [30, 1440];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    final t = widget.initialTask;
    final now = DateTime.now();

    DateTime? combinedDue;
    if (_dueDate != null) {
      combinedDue = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime?.hour ?? 23,
        _dueTime?.minute ?? 59,
      );
    }

    final taskModel = TaskModel(
      id: t?.id ?? 'tsk_${DateTime.now().millisecondsSinceEpoch}',
      userId: t?.userId ?? 'current_user',
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      status: t?.status ?? 'Todo',
      priority: _priority,
      dueDate: combinedDue,
      dueTime: _dueTime != null ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}' : null,
      estimatedDurationMinutes: _estimatedDurationMinutes,
      category: _category,
      dependencyTaskIds: _selectedDependencies,
      reminderSettings: _reminderMinutes,
      completedAt: t?.completedAt,
      createdAt: t?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(taskModel);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    // Filter available dependencies (exclude self)
    final eligibleDeps = widget.allTasks.where((task) => task.id != widget.initialTask?.id).toList();

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppGeometry.radiusCard)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialTask != null ? 'Edit Task' : 'Add Task',
                  style: AppTypography.h3.copyWith(color: colors.textPrimary),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _titleController,
              label: 'Task Title',
              hintText: 'e.g. Finish DBMS Assignment',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _descController,
              label: 'Notes / Description (Optional)',
              hintText: 'Key steps, links, details...',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            // Due Date & Time
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppGeometry.radiusInput),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_outlined, size: 18, color: colors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _dueDate != null ? dateFormat.format(_dueDate!) : 'Set Due Date',
                              style: AppTypography.caption.copyWith(
                                color: _dueDate != null ? colors.textPrimary : colors.textMuted,
                                fontWeight: _dueDate != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _dueTime ?? const TimeOfDay(hour: 17, minute: 0),
                      );
                      if (picked != null) setState(() => _dueTime = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppGeometry.radiusInput),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: colors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _dueTime != null ? _dueTime!.format(context) : 'Time',
                              style: AppTypography.caption.copyWith(
                                color: _dueTime != null ? colors.textPrimary : colors.textMuted,
                                fontWeight: _dueTime != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Priority & Category
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _priority,
                    dropdownColor: colors.surface,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      labelStyle: TextStyle(color: colors.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppGeometry.radiusInput)),
                    ),
                    items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _priority = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    dropdownColor: colors.surface,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: colors.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppGeometry.radiusInput)),
                    ),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Estimated Duration
            DropdownButtonFormField<int>(
              value: _estimatedDurationMinutes,
              dropdownColor: colors.surface,
              decoration: InputDecoration(
                labelText: 'Estimated Duration',
                labelStyle: TextStyle(color: colors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppGeometry.radiusInput)),
              ),
              items: _durations.map((d) => DropdownMenuItem(value: d, child: Text('$d minutes'))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _estimatedDurationMinutes = v);
              },
            ),
            if (eligibleDeps.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Prerequisite Dependency',
                style: AppTypography.caption.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppGeometry.radiusInput),
                  border: Border.all(color: colors.border),
                ),
                child: DropdownButton<String?>(
                  value: _selectedDependencies.isNotEmpty ? _selectedDependencies.first : null,
                  dropdownColor: colors.surface,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: Text('None (Independent task)', style: AppTypography.body.copyWith(color: colors.textMuted)),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None (Independent task)', style: AppTypography.body.copyWith(color: colors.textSecondary)),
                    ),
                    ...eligibleDeps.map((d) => DropdownMenuItem<String?>(
                      value: d.id,
                      child: Text(d.title, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedDependencies.clear();
                      if (val != null) _selectedDependencies.add(val);
                    });
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            AppButton(
              label: widget.initialTask != null ? 'Update Task' : 'Create Task',
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
