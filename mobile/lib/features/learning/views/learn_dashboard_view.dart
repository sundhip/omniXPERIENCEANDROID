import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/database/app_database.dart';
import '../learning_bloc.dart';
import 'learning_item_dialog.dart';
import 'goal_dialog.dart';
import 'study_session_dialog.dart';
import 'knowledge_note_dialog.dart';
import 'ai_plan_dialog.dart';

class LearnDashboardView extends StatefulWidget {
  const LearnDashboardView({super.key});

  @override
  State<LearnDashboardView> createState() => _LearnDashboardViewState();
}

class _LearnDashboardViewState extends State<LearnDashboardView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocConsumer<LearningBloc, LearningState>(
      listener: (context, state) {
        if (state is LearningLoaded && state.activeGoalPlan != null) {
          final plan = state.activeGoalPlan!;
          context.read<LearningBloc>().add(const ClearGoalPlanEvent());
          showDialog(
            context: context,
            builder: (_) => AiPlanDialog(
              plan: plan,
              onConfirmMilestones: (suggested) {
                // Apply milestones to goal
                final goal = state.goals.firstWhere((g) => g.id == plan.goalId);
                final updatedMilestones = List<Map<String, dynamic>>.from(
                  goal.milestones.map((m) => m.toJson())
                );
                for (final sm in suggested) {
                  updatedMilestones.add({
                    'id': 'plan_${DateTime.now().millisecondsSinceEpoch}_${sm.order}',
                    'title': sm.title,
                    'target_date': sm.targetDate,
                    'completed': false,
                    'order': sm.order,
                  });
                }
                context.read<LearningBloc>().add(
                  UpdateGoalEvent(goal.id, {'milestones': updatedMilestones})
                );
              },
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is LearningLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is LearningError) {
          return Scaffold(
            backgroundColor: colors.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colors.error),
                    const SizedBox(height: 16),
                    const Text('Failed to load learning data', style: AppTypography.h3),
                    const SizedBox(height: 8),
                    Text(state.message, textAlign: TextAlign.center, style: AppTypography.body),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<LearningBloc>().add(const LoadLearningData(forceRefresh: true)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is! LearningLoaded) {
          return const SizedBox.shrink();
        }

        final dash = state.dashboard;

        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Row
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
                                      Text(
                                        'LEARN & GOALS',
                                        style: AppTypography.caption.copyWith(letterSpacing: 1.2, color: colors.primary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Personal Intelligence',
                                        style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Add Action Button
                              IconButton.filled(
                                icon: const Icon(Icons.add, size: 20),
                                tooltip: 'Create',
                                onPressed: () => _showAddOptions(context, state),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Summary Metrics Cards
                          Row(
                            children: [
                              _metricBox(
                                context,
                                label: 'Active Goals',
                                value: '${dash.activeGoalsCount}',
                                icon: Icons.flag_outlined,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 10),
                              _metricBox(
                                context,
                                label: 'Learning Items',
                                value: '${dash.activeLearningCount}',
                                icon: Icons.school_outlined,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 10),
                              _metricBox(
                                context,
                                label: 'Study Mins',
                                value: '${dash.totalStudyMinutesThisWeek}m',
                                icon: Icons.timer_outlined,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Actionable Insights / Overload Alert Banner
                          if (dash.insights.isNotEmpty) ...[
                            _insightCard(context, dash.insights.first),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: colors.primary,
                        labelColor: colors.primary,
                        unselectedLabelColor: colors.textSecondary,
                        tabs: const [
                          Tab(text: 'Today'),
                          Tab(text: 'Goals'),
                          Tab(text: 'Learning'),
                          Tab(text: 'Notes'),
                        ],
                      ),
                      colors.surface,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildTodayTab(context, state),
                  _buildGoalsTab(context, state),
                  _buildLearningTab(context, state),
                  _buildNotesTab(context, state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Tab 1: Today ---
  Widget _buildTodayTab(BuildContext context, LearningLoaded state) {
    final colors = context.colors;
    final dash = state.dashboard;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Upcoming Deadlines Card
        Text('Upcoming Deadlines (Next 7 Days)', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (dash.upcomingDeadlines.isEmpty)
          _emptyHint(context, 'No urgent deadlines in the next 7 days.')
        else
          ...dash.upcomingDeadlines.map((d) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (d['days_left'] as int? ?? 0) <= 2
                        ? colors.error.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${d['days_left']}d left',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (d['days_left'] as int? ?? 0) <= 2 ? colors.error : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['title'] ?? '', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                      Text('${d['type']} • ${d['category']}', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        const SizedBox(height: 20),

        // High Priority Focus Items
        Text('High Priority Topics', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (dash.todayLearning.isEmpty)
          _emptyHint(context, 'No high priority items. Tap + to add subjects or topics.')
        else
          ...dash.todayLearning.map((item) => _learningItemTile(context, item)),

        const SizedBox(height: 20),

        // Today's Study Sessions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's Logged Sessions", style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Log Session'),
              onPressed: () => _openAddSession(context, state),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (dash.todaySessions.isEmpty)
          _emptyHint(context, 'No sessions logged today. Use focused blocks to build retention.')
        else
          ...dash.todaySessions.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: colors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s.title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                ),
                Text('${s.actualDurationMinutes}m', style: AppTypography.label.copyWith(color: colors.primary)),
              ],
            ),
          )),
      ],
    );
  }

  // --- Tab 2: Goals ---
  Widget _buildGoalsTab(BuildContext context, LearningLoaded state) {
    final goals = state.goals;

    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flag_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No goals yet', style: AppTypography.h3),
            const SizedBox(height: 4),
            const Text('Set academic, project, or career goals with milestones', style: AppTypography.caption),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openAddGoal(context),
              child: const Text('Create Goal'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      itemBuilder: (context, idx) {
        final goal = goals[idx];
        return _goalCard(context, goal, state);
      },
    );
  }

  // --- Tab 3: Learning Items ---
  Widget _buildLearningTab(BuildContext context, LearningLoaded state) {
    final colors = context.colors;
    final items = state.filteredItems;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: state.availableCategories.map((cat) {
              final isSelected = state.selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => context.read<LearningBloc>().add(FilterCategoryChanged(cat)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        if (items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('No learning items in this category.', style: AppTypography.body.copyWith(color: colors.textSecondary)),
            ),
          )
        else
          ...items.map((item) => _learningItemTile(context, item)),
      ],
    );
  }

  // --- Tab 4: Knowledge Notes ---
  Widget _buildNotesTab(BuildContext context, LearningLoaded state) {
    final colors = context.colors;
    final notes = state.notes;

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notes_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No notes yet', style: AppTypography.h3),
            const SizedBox(height: 4),
            const Text('Keep lightweight formulas, code snippets, and key ideas', style: AppTypography.caption),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openAddNote(context, state),
              child: const Text('New Note'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, idx) {
        final note = notes[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(note.title, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => context.read<LearningBloc>().add(DeleteKnowledgeNoteEvent(note.id)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(note.content, style: AppTypography.body),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: note.tags.map((t) => Chip(
                    label: Text(t, style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                  )).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---
  Widget _metricBox(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colors = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value, style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _insightCard(BuildContext context, LearningInsightModel insight) {
    final colors = context.colors;
    Color iconColor;
    if (insight.severity == 'critical') {
      iconColor = colors.error;
    } else if (insight.severity == 'warning') {
      iconColor = Colors.orange;
    } else {
      iconColor = colors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 22, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: AppTypography.label.copyWith(fontWeight: FontWeight.bold, color: iconColor)),
                const SizedBox(height: 2),
                Text(insight.description, style: AppTypography.caption.copyWith(color: colors.textPrimary)),
                const SizedBox(height: 4),
                Text('→ ${insight.actionableRecommendation}', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: iconColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalCard(BuildContext context, GoalModel goal, LearningLoaded state) {
    final colors = context.colors;
    final isDone = goal.status == 'Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDone ? colors.primary.withOpacity(0.3) : colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      '${goal.category} • ${goal.priority} Priority${goal.targetDate != null ? ' • Due ${goal.targetDate!.toIso8601String().substring(0, 10)}' : ''}',
                      style: AppTypography.caption.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: Colors.purple, size: 22),
                tooltip: 'Plan with AI',
                onPressed: () {
                  context.read<LearningBloc>().add(RequestGoalPlanEvent(goal.id));
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (goal.progress / 100.0).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: colors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${goal.progress.toInt()}%', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),

          // Milestones
          if (goal.milestones.isNotEmpty) ...[
            Text('Milestones (${goal.milestones.where((m) => m.completed).length}/${goal.milestones.length})',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...goal.milestones.map((m) => InkWell(
              onTap: () {
                context.read<LearningBloc>().add(ToggleMilestoneEvent(goal.id, m.id));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(
                      m.completed ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: m.completed ? colors.primary : colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.title,
                        style: AppTypography.caption.copyWith(
                          decoration: m.completed ? TextDecoration.lineThrough : null,
                          color: m.completed ? colors.textSecondary : colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _learningItemTile(BuildContext context, LearningItemModel item) {
    final colors = context.colors;
    final isDone = item.status == 'Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDone ? colors.primary.withOpacity(0.3) : colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surfaceSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(item.type, style: AppTypography.caption),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (item.progress / 100.0).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: colors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${item.progress.toInt()}%', style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(BuildContext context, String text) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withOpacity(0.6)),
      ),
      child: Text(text, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
    );
  }

  void _showAddOptions(BuildContext context, LearningLoaded state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('Add Learning Item / Subject'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openAddLearningItem(context, state);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Create New Goal'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openAddGoal(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Log Study / Work Session'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openAddSession(context, state);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notes_outlined),
                title: const Text('New Knowledge Note'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openAddNote(context, state);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAddLearningItem(BuildContext context, LearningLoaded state) {
    showDialog(
      context: context,
      builder: (_) => LearningItemDialog(
        existingItems: state.learningItems,
        onSave: (data) => context.read<LearningBloc>().add(AddLearningItemEvent(data)),
      ),
    );
  }

  void _openAddGoal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => GoalDialog(
        onSave: (data) => context.read<LearningBloc>().add(AddGoalEvent(data)),
      ),
    );
  }

  void _openAddSession(BuildContext context, LearningLoaded state) {
    showDialog(
      context: context,
      builder: (_) => StudySessionDialog(
        learningItems: state.learningItems,
        goals: state.goals,
        onSave: (data) => context.read<LearningBloc>().add(AddStudySessionEvent(data)),
      ),
    );
  }

  void _openAddNote(BuildContext context, LearningLoaded state) {
    showDialog(
      context: context,
      builder: (_) => KnowledgeNoteDialog(
        learningItems: state.learningItems,
        goals: state.goals,
        onSave: (data) => context.read<LearningBloc>().add(AddKnowledgeNoteEvent(data)),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color backgroundColor;

  _SliverAppBarDelegate(this._tabBar, this.backgroundColor);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
