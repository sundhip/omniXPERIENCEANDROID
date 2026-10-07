import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_geometry.dart';
import '../../../shared/components/app_button.dart';
import '../../../shared/components/app_text_field.dart';

class EventDialog extends StatefulWidget {
  final EventModel? initialEvent;
  final DateTime? initialDate;
  final Function(EventModel) onSave;

  const EventDialog({
    super.key,
    this.initialEvent,
    this.initialDate,
    required this.onSave,
  });

  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _locationController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _category;
  late String _priority;
  late String _occasion;
  late List<int> _reminderMinutes;

  final List<String> _categories = [
    'College', 'Work', 'Personal', 'Health', 'Fitness', 'Finance', 'Errands', 'Projects', 'Other'
  ];
  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];
  final List<String> _occasions = [
    'Lecture', 'Presentation', 'Exam', 'Meeting', 'Workout', 'Dinner', 'Party', 'Casual'
  ];

  @override
  void initState() {
    super.initState();
    final ev = widget.initialEvent;
    _titleController = TextEditingController(text: ev?.title ?? '');
    _descController = TextEditingController(text: ev?.description ?? '');
    _locationController = TextEditingController(text: ev?.location ?? '');

    final baseDate = ev?.startTime ?? widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(baseDate.year, baseDate.month, baseDate.day);

    _startTime = ev != null
        ? TimeOfDay(hour: ev.startTime.hour, minute: ev.startTime.minute)
        : const TimeOfDay(hour: 10, minute: 0);

    _endTime = ev != null
        ? TimeOfDay(hour: ev.endTime.hour, minute: ev.endTime.minute)
        : const TimeOfDay(hour: 11, minute: 0);

    _category = ev?.category ?? 'Personal';
    _priority = ev?.priority ?? 'Medium';
    _occasion = ev?.occasion ?? 'Casual';
    _reminderMinutes = ev != null ? List<int>.from(ev.reminderSettings) : [15, 60];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event title')),
      );
      return;
    }

    final startDt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDt.isBefore(startDt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time cannot be earlier than start time')),
      );
      return;
    }

    final ev = widget.initialEvent;
    final now = DateTime.now();
    final eventModel = EventModel(
      id: ev?.id ?? 'evt_${DateTime.now().millisecondsSinceEpoch}',
      userId: ev?.userId ?? 'current_user',
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      startTime: startDt,
      endTime: endDt,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      category: _category,
      priority: _priority,
      status: ev?.status ?? 'scheduled',
      occasion: _occasion,
      reminderSettings: _reminderMinutes,
      createdAt: ev?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(eventModel);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

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
                  widget.initialEvent != null ? 'Edit Event' : 'Add Event',
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
              label: 'Title',
              hintText: 'e.g. DBMS Lecture or Team Standup',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _descController,
              label: 'Description (Optional)',
              hintText: 'Details, agenda, notes...',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            // Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppGeometry.radiusInput),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 20, color: colors.primary),
                    const SizedBox(width: 10),
                    Text(
                      dateFormat.format(_selectedDate),
                      style: AppTypography.body.copyWith(color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Time Pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (picked != null) setState(() => _startTime = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppGeometry.radiusInput),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Starts', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(_startTime.format(context), style: AppTypography.body.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                      );
                      if (picked != null) setState(() => _endTime = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppGeometry.radiusInput),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ends', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(_endTime.format(context), style: AppTypography.body.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _locationController,
              label: 'Location (Optional)',
              hintText: 'e.g. Hall 401 or Zoom Link',
            ),
            const SizedBox(height: 12),
            // Category & Priority
            Row(
              children: [
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
                const SizedBox(width: 12),
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
              ],
            ),
            const SizedBox(height: 12),
            // Occasion for future Wardrobe AI
            DropdownButtonFormField<String>(
              value: _occasion,
              dropdownColor: colors.surface,
              decoration: InputDecoration(
                labelText: 'Occasion (Wardrobe Context)',
                labelStyle: TextStyle(color: colors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppGeometry.radiusInput)),
              ),
              items: _occasions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _occasion = v);
              },
            ),
            const SizedBox(height: 20),
            AppButton(
              label: widget.initialEvent != null ? 'Update Event' : 'Create Event',
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
