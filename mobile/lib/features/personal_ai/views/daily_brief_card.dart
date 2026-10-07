import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/components/app_card.dart';
import '../models/personal_ai_models.dart';

class DailyBriefCard extends StatelessWidget {
  final DailyPersonalBriefModel brief;
  final VoidCallback onOpenAi;

  const DailyBriefCard({
    super.key,
    required this.brief,
    required this.onOpenAi,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      backgroundColor: colors.surface,
      border: Border.all(color: colors.primary.withOpacity(0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome, color: colors.primary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Daily Personal Brief",
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onOpenAi,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Text("Ask OP AI", style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios, size: 10, color: colors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metrics Pills Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _metricPill("${brief.eventsCount} Events", Icons.calendar_today_outlined, colors.primary, colors),
                const SizedBox(width: 6),
                _metricPill("${brief.priorityTasksCount} Priority Tasks", Icons.check_circle_outline, colors.warning, colors),
                const SizedBox(width: 6),
                _metricPill("${brief.approachingDeadlinesCount} Deadlines", Icons.timer_outlined, Colors.purple, colors),
                const SizedBox(width: 6),
                _metricPill("${brief.pendingHabitsCount} Habits Due", Icons.self_improvement_outlined, Colors.teal, colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 10),

          // Focus Section
          if (brief.focus.isNotEmpty) ...[
            _sectionRow("Focus", brief.focus, Icons.flag_outlined, colors.primary, colors),
            const SizedBox(height: 8),
          ],

          // Plan Section
          if (brief.plan.isNotEmpty) ...[
            _sectionRow("Plan", brief.plan, Icons.schedule_outlined, Colors.teal, colors),
            const SizedBox(height: 8),
          ],

          // Prepare Section
          if (brief.prepare.isNotEmpty) ...[
            _sectionRow("Prepare", brief.prepare, Icons.wb_cloudy_outlined, Colors.amber, colors),
            const SizedBox(height: 8),
          ],

          // Wellness Section
          if (brief.wellness.isNotEmpty) ...[
            _sectionRow("Wellness", brief.wellness, Icons.spa_outlined, colors.success, colors),
          ],

          // Proactive Alerts Banner
          if (brief.proactiveAlerts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: colors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      brief.proactiveAlerts.first,
                      style: AppTypography.caption.copyWith(color: colors.error, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricPill(String label, IconData icon, Color accent, AppSemanticColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _sectionRow(String label, String content, IconData icon, Color iconColor, AppSemanticColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.caption.copyWith(color: colors.textPrimary, height: 1.3),
              children: [
                TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: content, style: TextStyle(color: colors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
