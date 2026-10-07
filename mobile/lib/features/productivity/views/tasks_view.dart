import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_geometry.dart';
import '../../../shared/components/app_card.dart';
import '../productivity_bloc.dart';
import 'task_dialog.dart';

class TasksView extends StatelessWidget {
  const TasksView({super.key});

  final List<String> _tabs = const ['Today', 'Upcoming', 'Overdue', 'Completed'];
  final List<String> _categories = const [
    'All', 'College', 'Work', 'Personal', 'Health', 'Fitness', 'Finance', 'Errands', 'Projects', 'Other'
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<ProductivityBloc, ProductivityState>(
      builder: (context, state) {
        if (state is ProductivityLoading && state is! ProductivityLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is! ProductivityLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final loaded = state;

        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppGeometry.screenPadding, AppGeometry.screenPadding, AppGeometry.screenPadding, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tasks', style: AppTypography.h2.copyWith(color: colors.textPrimary)),
                      IconButton(
                        tooltip: 'Add Task',
                        icon: Icon(Icons.add_circle, color: colors.primary, size: 28),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => TaskDialog(
                              allTasks: loaded.allTasks,
                              onSave: (t) => context.read<ProductivityBloc>().add(CreateTaskAction(t)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Status Tabs (Today, Upcoming, Overdue, Completed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppGeometry.screenPadding),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceSoft,
                      borderRadius: BorderRadius.circular(AppGeometry.radiusInput),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: _tabs.map((tab) {
                        final isSelected = loaded.activeTaskTab == tab;
                        int count = 0;
                        if (tab == 'Today') count = loaded.todayTasks.length;
                        if (tab == 'Upcoming') count = loaded.allTasks.where((t) => t.status != 'Completed' && (t.dueDate?.isAfter(DateTime.now()) ?? false)).length;
                        if (tab == 'Overdue') count = loaded.overdueTasks.length;
                        if (tab == 'Completed') count = loaded.completedTasks.length;

                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              context.read<ProductivityBloc>().add(SetTaskTabAction(tab));
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? colors.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    tab,
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? colors.primary : colors.textSecondary,
                                    ),
                                  ),
                                  if (count > 0) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: tab == 'Overdue' ? colors.warning.withOpacity(0.2) : colors.surfaceSoft,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: tab == 'Overdue' ? colors.warning : colors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Category Filter Chips
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppGeometry.screenPadding),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final cat = _categories[idx];
                      final isSelected = (loaded.selectedCategory == null && cat == 'All') ||
                          (loaded.selectedCategory == cat);

                      return FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (val) {
                          context.read<ProductivityBloc>().add(
                            SetFilterCategoryAction(cat == 'All' ? null : cat),
                          );
                        },
                        selectedColor: colors.primarySoft,
                        checkmarkColor: colors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? colors.primary : colors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: colors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isSelected ? colors.primary : colors.border),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Tasks List
                Expanded(
                  child: loaded.filteredTasks.isEmpty
                      ? _buildEmptyState(loaded.activeTaskTab, colors, context, loaded)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppGeometry.screenPadding, vertical: 4),
                          itemCount: loaded.filteredTasks.length,
                          itemBuilder: (context, idx) {
                            final task = loaded.filteredTasks[idx];
                            return _buildTaskCard(context, task, loaded, colors);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    String tab,
    AppSemanticColors colors,
    BuildContext context,
    ProductivityLoaded state,
  ) {
    String msg = 'No tasks in this list';
    IconData icon = Icons.task_alt;

    if (tab == 'Today') {
      msg = 'No pending tasks for today!';
    } else if (tab == 'Overdue') {
      msg = 'No overdue tasks! You are on track.';
      icon = Icons.verified;
    } else if (tab == 'Completed') {
      msg = 'No completed tasks yet.';
      icon = Icons.check_circle_outline;
    } else if (tab == 'Upcoming') {
      msg = 'No upcoming deadlines.';
      icon = Icons.calendar_today_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: colors.textMuted),
          const SizedBox(height: 12),
          Text(msg, style: AppTypography.body.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => TaskDialog(
                  allTasks: state.allTasks,
                  onSave: (t) => context.read<ProductivityBloc>().add(CreateTaskAction(t)),
                ),
              );
            },
            child: const Text('Add a Task'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    TaskModel task,
    ProductivityLoaded state,
    AppSemanticColors colors,
  ) {
    final isDone = task.status == 'Completed';
    final assessment = state.priorityAssessments[task.id];

    Color pColor = colors.textSecondary;
    if (task.priority == 'Urgent') pColor = colors.error;
    if (task.priority == 'High') pColor = colors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => TaskDialog(
              initialTask: task,
              allTasks: state.allTasks,
              onSave: (updated) => context.read<ProductivityBloc>().add(UpdateTaskAction(updated)),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isDone ? colors.success : colors.textMuted,
                  ),
                  onPressed: () {
                    context.read<ProductivityBloc>().add(ToggleTaskCompletionAction(task.id));
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDone ? colors.textMuted : colors.textPrimary,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description!,
                          style: AppTypography.caption.copyWith(color: colors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colors.textMuted, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Task?'),
                        content: Text('Are you sure you want to delete "${task.title}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.read<ProductivityBloc>().add(DeleteTaskAction(task.id));
                            },
                            child: Text('Delete', style: TextStyle(color: colors.error)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            // Tags and metadata row
            Padding(
              padding: const EdgeInsets.only(left: 48, right: 8, bottom: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.surfaceSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(task.category, style: AppTypography.caption.copyWith(fontSize: 10, color: colors.textSecondary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: pColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(task.priority, style: AppTypography.caption.copyWith(fontSize: 10, color: pColor, fontWeight: FontWeight.bold)),
                  ),
                  if (task.estimatedDurationMinutes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text('${task.estimatedDurationMinutes}m', style: AppTypography.caption.copyWith(fontSize: 10, color: colors.textSecondary)),
                    ),
                  if (task.dueDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: task.dueDate!.isBefore(DateTime.now()) && !isDone
                            ? colors.warning.withOpacity(0.15)
                            : colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: task.dueDate!.isBefore(DateTime.now()) && !isDone
                              ? colors.warning.withOpacity(0.4)
                              : colors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 11,
                            color: task.dueDate!.isBefore(DateTime.now()) && !isDone ? colors.warning : colors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, HH:mm').format(task.dueDate!),
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              color: task.dueDate!.isBefore(DateTime.now()) && !isDone ? colors.warning : colors.textSecondary,
                              fontWeight: task.dueDate!.isBefore(DateTime.now()) && !isDone ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (assessment != null && assessment.isBlocked) ...[
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 4, right: 8),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 12, color: colors.warning),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        assessment.explanation,
                        style: AppTypography.caption.copyWith(color: colors.warning, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
