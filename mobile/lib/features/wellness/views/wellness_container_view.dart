import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/database/app_database.dart';
import '../wellness_bloc.dart';
import 'habit_dialog.dart';
import 'routine_step_dialog.dart';
import 'skincare_profile_dialog.dart';

class WellnessContainerView extends StatefulWidget {
  const WellnessContainerView({super.key});

  @override
  State<WellnessContainerView> createState() => _WellnessContainerViewState();
}

class _WellnessContainerViewState extends State<WellnessContainerView> {
  // Client-side transient checklist for today's skincare steps
  final Set<String> _completedStepIds = {};

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<WellnessBloc, WellnessState>(
      builder: (context, state) {
        if (state is WellnessLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is WellnessError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colors.error),
                  const SizedBox(height: 16),
                  const Text('Failed to load wellness routines', style: AppTypography.h3),
                  const SizedBox(height: 8),
                  Text(state.message, textAlign: TextAlign.center, style: AppTypography.body),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<WellnessBloc>().add(const LoadWellnessData(forceRefresh: true)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! WellnessLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final today = state.todayWellness;
        final habits = state.habits;
        final morningRoutine = today.morningRoutine;
        final eveningRoutine = today.eveningRoutine;
        final insights = today.insights;

        final todayStr = DateTime.now().toIso8601String().split('T').first;

        return Scaffold(
          backgroundColor: colors.background,
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<WellnessBloc>().add(const LoadWellnessData(forceRefresh: true));
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (Navigator.canPop(context)) ...[
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('WELLNESS & SELF-CARE', style: AppTypography.caption.copyWith(letterSpacing: 1.2, color: colors.primary)),
                                    const SizedBox(height: 2),
                                    Text("Today's Routines", style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.face_retouching_natural, size: 20),
                                  tooltip: 'Skincare Profile',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => SkincareProfileDialog(
                                        initialProfile: state.skincareProfile,
                                        onSave: (data) => context.read<WellnessBloc>().add(SaveSkincareProfileEvent(data)),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  icon: const Icon(Icons.add, size: 20),
                                  tooltip: 'Add Habit or Routine',
                                  onPressed: () => _showAddOptions(context, state),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Progress Summary Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.spa, color: colors.primary, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Daily Completion',
                                      style: AppTypography.caption.copyWith(color: colors.textSecondary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${today.completedHabitsCount} of ${today.totalHabitsCount} habits logged',
                                      style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    if (today.totalHabitsCount > 0) ...[
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: (today.completedHabitsCount / today.totalHabitsCount).clamp(0.0, 1.0),
                                          minHeight: 6,
                                          backgroundColor: colors.background,
                                          valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Insights banner
                        if (insights.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.primarySoft.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.bolt, size: 20, color: colors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        insights.first.title,
                                        style: AppTypography.label.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        insights.first.description,
                                        style: AppTypography.body,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Morning Skincare Section
                        _sectionHeader(
                          context,
                          title: 'Morning Skincare',
                          icon: Icons.wb_sunny_outlined,
                          onAdd: () {
                            showDialog(
                              context: context,
                              builder: (_) => RoutineStepDialog(
                                defaultTimeOfDay: 'morning',
                                onSave: (data) => context.read<WellnessBloc>().add(AddRoutineStepEvent(data)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        if (morningRoutine.isEmpty)
                          _emptySectionCard(context, 'No morning steps yet. Tap + to add Cleanser, SPF, etc.')
                        else
                          ...morningRoutine.map((step) => _routineStepTile(context, step)),

                        const SizedBox(height: 20),

                        // Daily Habits Section
                        _sectionHeader(
                          context,
                          title: 'Daily Habits',
                          icon: Icons.check_circle_outline,
                          onAdd: () {
                            showDialog(
                              context: context,
                              builder: (_) => HabitDialog(
                                onSave: (data) => context.read<WellnessBloc>().add(AddHabitEvent(data)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        if (habits.isEmpty)
                          _emptySectionCard(context, 'No habits created yet. Tap + to build your routines.')
                        else
                          ...habits.map((h) => _habitTile(context, h, todayStr)),

                        const SizedBox(height: 20),

                        // Evening Skincare Section
                        _sectionHeader(
                          context,
                          title: 'Evening Skincare',
                          icon: Icons.nights_stay_outlined,
                          onAdd: () {
                            showDialog(
                              context: context,
                              builder: (_) => RoutineStepDialog(
                                defaultTimeOfDay: 'evening',
                                onSave: (data) => context.read<WellnessBloc>().add(AddRoutineStepEvent(data)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        if (eveningRoutine.isEmpty)
                          _emptySectionCard(context, 'No evening steps yet. Tap + to add Night Cream, etc.')
                        else
                          ...eveningRoutine.map((step) => _routineStepTile(context, step)),

                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'Personal lifestyle & routine tracker. Non-medical.',
                            style: AppTypography.caption.copyWith(color: colors.textSecondary.withOpacity(0.6)),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddOptions(BuildContext context, WellnessLoaded state) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.check_circle_outline, color: colors.primary),
                  title: const Text('Add Daily Habit'),
                  subtitle: const Text('Track water, exercise, study, etc.'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showDialog(
                      context: context,
                      builder: (_) => HabitDialog(
                        onSave: (data) => context.read<WellnessBloc>().add(AddHabitEvent(data)),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.spa_outlined, color: colors.primary),
                  title: const Text('Add Routine Step / Product'),
                  subtitle: const Text('Add cleanser, sunscreen, moisturizer, etc.'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showDialog(
                      context: context,
                      builder: (_) => RoutineStepDialog(
                        onSave: (data) => context.read<WellnessBloc>().add(AddRoutineStepEvent(data)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onAdd,
  }) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Text(title, style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: onAdd,
          color: colors.primary,
        ),
      ],
    );
  }

  Widget _emptySectionCard(BuildContext context, String hint) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      child: Text(hint, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
    );
  }

  Widget _routineStepTile(BuildContext context, RoutineStepTodayModel step) {
    final colors = context.colors;
    final isDone = _completedStepIds.contains(step.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDone ? colors.primary.withOpacity(0.3) : colors.border.withOpacity(0.6)),
      ),
      child: ListTile(
        leading: InkWell(
          onTap: () {
            setState(() {
              if (isDone) {
                _completedStepIds.remove(step.id);
              } else {
                _completedStepIds.add(step.id);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? colors.primary : Colors.transparent,
              border: Border.all(color: isDone ? colors.primary : colors.textSecondary),
            ),
            child: Icon(Icons.check, size: 14, color: isDone ? Colors.white : Colors.transparent),
          ),
        ),
        title: Text(
          step.productName,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? colors.textSecondary : colors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Step ${step.routineStep} • ${step.category}',
          style: AppTypography.caption,
        ),
      ),
    );
  }

  Widget _habitTile(BuildContext context, HabitModel habit, String todayStr) {
    final colors = context.colors;
    final isCompleted = habit.completedToday;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCompleted ? colors.primary.withOpacity(0.3) : colors.border.withOpacity(0.6)),
      ),
      child: ListTile(
        leading: InkWell(
          onTap: () {
            context.read<WellnessBloc>().add(
              LogHabitEvent(
                habitId: habit.id,
                logDate: todayStr,
                status: isCompleted ? 'Missed' : 'Completed',
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? colors.primary : Colors.transparent,
              border: Border.all(color: isCompleted ? colors.primary : colors.textSecondary),
            ),
            child: Icon(Icons.check, size: 14, color: isCompleted ? Colors.white : Colors.transparent),
          ),
        ),
        title: Text(
          habit.name,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? colors.textSecondary : colors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${habit.category} • ${habit.target} ${habit.unit}/day',
          style: AppTypography.caption,
        ),
        trailing: habit.currentStreak > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, size: 14, color: Colors.deepOrange),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.currentStreak}d',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
