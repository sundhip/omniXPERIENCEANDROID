import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_geometry.dart';
import '../../../shared/components/app_card.dart';
import '../productivity_bloc.dart';
import 'event_dialog.dart';
import 'task_dialog.dart';

class TodayView extends StatelessWidget {
  final VoidCallback? onOpenCalendar;
  final VoidCallback? onOpenTasks;

  const TodayView({
    super.key,
    this.onOpenCalendar,
    this.onOpenTasks,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    return BlocBuilder<ProductivityBloc, ProductivityState>(
      builder: (context, state) {
        if (state is ProductivityLoading && state is! ProductivityLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProductivityError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colors.error),
                  const SizedBox(height: 12),
                  Text('Failed to load schedule', style: AppTypography.h3.copyWith(color: colors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(state.message, style: AppTypography.caption.copyWith(color: colors.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProductivityBloc>().add(const LoadProductivityData(forceRefresh: true)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! ProductivityLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final loaded = state;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<ProductivityBloc>().add(const LoadProductivityData(forceRefresh: true));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppGeometry.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Today's date & actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TODAY', style: AppTypography.label.copyWith(color: colors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        Text(dateStr, style: AppTypography.h2.copyWith(color: colors.textPrimary)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Add Event',
                          icon: Icon(Icons.add_circle_outline, color: colors.primary, size: 28),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => EventDialog(
                                initialDate: now,
                                onSave: (ev) => context.read<ProductivityBloc>().add(CreateEventAction(ev)),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Add Task',
                          icon: Icon(Icons.check_circle_outline, color: colors.primary, size: 28),
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
                  ],
                ),
                const SizedBox(height: 8),

                // Summary natural status message
                Text(
                  loaded.summaryMessage,
                  style: AppTypography.body.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Conflict Alerts Banner
                if (loaded.conflicts.isNotEmpty) ...[
                  ...loaded.conflicts.map((c) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
                      border: Border.all(color: colors.error.withOpacity(0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: colors.error, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Schedule Conflict Detected',
                                style: AppTypography.label.copyWith(color: colors.error, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(c.message, style: AppTypography.caption.copyWith(color: colors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],

                // Overdue tasks banner
                if (loaded.overdueTasks.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppGeometry.radiusInput),
                      border: Border.all(color: colors.warning.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.alarm, color: colors.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${loaded.overdueTasks.length} task${loaded.overdueTasks.length > 1 ? 's are' : ' is'} overdue. Tap below to finish.',
                            style: AppTypography.caption.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Events Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Events", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
                    if (onOpenCalendar != null)
                      TextButton(
                        onPressed: onOpenCalendar,
                        child: Text('View Calendar →', style: TextStyle(color: colors.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (loaded.todayEvents.isEmpty)
                  AppCard(
                    backgroundColor: colors.surfaceSoft,
                    child: Row(
                      children: [
                        Icon(Icons.event_available, color: colors.textMuted, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No events scheduled today.',
                            style: AppTypography.body.copyWith(color: colors.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => EventDialog(
                                initialDate: now,
                                onSave: (ev) => context.read<ProductivityBloc>().add(CreateEventAction(ev)),
                              ),
                            );
                          },
                          child: const Text('Add Event'),
                        ),
                      ],
                    ),
                  )
                else
                  ...loaded.todayEvents.map((ev) => _buildEventItem(context, ev, loaded, colors)),

                const SizedBox(height: 24),

                // Tasks Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Action Items & Tasks", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
                    if (onOpenTasks != null)
                      TextButton(
                        onPressed: onOpenTasks,
                        child: Text('All Tasks →', style: TextStyle(color: colors.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (loaded.todayTasks.isEmpty && loaded.overdueTasks.isEmpty)
                  AppCard(
                    backgroundColor: colors.surfaceSoft,
                    child: Row(
                      children: [
                        Icon(Icons.task_alt, color: colors.success, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All caught up! No pending tasks due today.',
                            style: AppTypography.body.copyWith(color: colors.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => TaskDialog(
                                allTasks: loaded.allTasks,
                                onSave: (t) => context.read<ProductivityBloc>().add(CreateTaskAction(t)),
                              ),
                            );
                          },
                          child: const Text('Add Task'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Render overdue tasks first
                  ...loaded.overdueTasks.map((t) => _buildTaskItem(context, t, loaded, colors, isOverdue: true)),
                  // Then today's tasks
                  ...loaded.todayTasks.map((t) => _buildTaskItem(context, t, loaded, colors)),
                ],

                const SizedBox(height: 24),

                // Intelligent Scheduling & Available Blocks
                if (loaded.suggestedSlots.isNotEmpty) ...[
                  Text("Smart Planning Suggestions", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
                  const SizedBox(height: 8),
                  ...loaded.suggestedSlots.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceSoft,
                      borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.auto_awesome, color: colors.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${DateFormat('HH:mm').format(s.suggestedStart)} – ${DateFormat('HH:mm').format(s.suggestedEnd)}',
                                style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                s.taskTitle,
                                style: AppTypography.body.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                s.reason,
                                style: AppTypography.caption.copyWith(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventItem(BuildContext context, EventModel ev, ProductivityLoaded state, AppSemanticColors colors) {
    final startFmt = DateFormat('HH:mm').format(ev.startTime);
    final endFmt = DateFormat('HH:mm').format(ev.endTime);

    Color pColor = colors.textSecondary;
    if (ev.priority == 'Urgent') pColor = colors.error;
    if (ev.priority == 'High') pColor = colors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => EventDialog(
              initialEvent: ev,
              onSave: (updated) => context.read<ProductivityBloc>().add(UpdateEventAction(updated)),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(startFmt, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                Text(endFmt, style: AppTypography.caption.copyWith(color: colors.textMuted)),
              ],
            ),
            const SizedBox(width: 14),
            Container(width: 3, height: 40, color: pColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ev.title,
                          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, color: colors.textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.surfaceSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(ev.category, style: AppTypography.caption.copyWith(fontSize: 10, color: colors.textSecondary)),
                      ),
                    ],
                  ),
                  if (ev.location != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: colors.textMuted),
                        const SizedBox(width: 4),
                        Text(ev.location!, style: AppTypography.caption.copyWith(color: colors.textMuted)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    TaskModel task,
    ProductivityLoaded state,
    AppSemanticColors colors, {
    bool isOverdue = false,
  }) {
    final isDone = task.status == 'Completed';
    final assessment = state.priorityAssessments[task.id];

    Color pColor = colors.textSecondary;
    if (task.priority == 'Urgent') pColor = colors.error;
    if (task.priority == 'High') pColor = colors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
        child: Row(
          children: [
            // One-tap completion checkbox
            IconButton(
              icon: Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isDone ? colors.success : (isOverdue ? colors.warning : colors.textMuted),
              ),
              onPressed: () {
                context.read<ProductivityBloc>().add(ToggleTaskCompletionAction(task.id));
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDone ? colors.textMuted : colors.textPrimary,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: pColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(task.priority, style: AppTypography.caption.copyWith(fontSize: 10, color: pColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (assessment != null && assessment.isBlocked) ...[
                    const SizedBox(height: 2),
                    Row(
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
                  ] else if (task.dueDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${isOverdue ? 'Overdue: ' : 'Due: '}${DateFormat('MMM d, HH:mm').format(task.dueDate!)}',
                      style: AppTypography.caption.copyWith(
                        color: isOverdue ? colors.warning : colors.textMuted,
                        fontSize: 11,
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
