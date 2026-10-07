import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/database/app_database.dart';

class AiPlanDialog extends StatelessWidget {
  final GoalPlanRecommendationModel plan;
  final Function(List<MilestonePlanSuggestionModel> milestones) onConfirmMilestones;

  const AiPlanDialog({
    super.key,
    required this.plan,
    required this.onConfirmMilestones,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Color statusColor;
    switch (plan.deadlineStatus) {
      case 'On Track':
        statusColor = Colors.green;
        break;
      case 'Tight':
        statusColor = Colors.orange;
        break;
      case 'Unrealistic':
      case 'Passed':
        statusColor = colors.error;
        break;
      default:
        statusColor = colors.primary;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colors.surface,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: colors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text('AI Goal Planner', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Goal Title Banner
              Text(plan.goalTitle, style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Feasibility Badge & Metric Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Feasibility Status', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          plan.deadlineStatus,
                          style: AppTypography.label.copyWith(fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Weekly Required', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          '${plan.weeklyHoursRequired} hrs/wk',
                          style: AppTypography.label.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Rationale Explanation
              Text('Plan Analysis', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                plan.rationale,
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 12),

              // Detected Conflicts Alert
              if (plan.detectedConflicts.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          plan.detectedConflicts.first,
                          style: AppTypography.caption.copyWith(color: colors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Next Action Recommendation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recommended Action', style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(plan.recommendedNextAction, style: AppTypography.body),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Suggested Staged Milestones
              if (plan.suggestedMilestones.isNotEmpty) ...[
                Text('Suggested Staged Milestones', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...plan.suggestedMilestones.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.surfaceSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: colors.primary.withOpacity(0.2),
                        child: Text('${m.order}', style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                            Text('Target: ${m.targetDate} • ~${m.estimatedHours} hrs', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onConfirmMilestones(plan.suggestedMilestones);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply Plan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
