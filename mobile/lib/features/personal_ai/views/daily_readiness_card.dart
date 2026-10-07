import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/components/app_card.dart';
import '../models/personal_ai_models.dart';

class DailyReadinessCard extends StatelessWidget {
  final DailyPersonalBriefModel? brief;
  final VoidCallback onOpenAi;
  final VoidCallback? onRefresh;

  const DailyReadinessCard({
    super.key,
    required this.brief,
    required this.onOpenAi,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasBrief = brief != null;

    final urgentAlertsCount = hasBrief
        ? (brief!.approachingDeadlinesCount + brief!.proactiveAlerts.length)
        : 0;

    final statusText = urgentAlertsCount > 0
        ? "$urgentAlertsCount items need attention"
        : "All systems aligned";
    final statusColor = urgentAlertsCount > 0 ? colors.warning : colors.success;

    return AppCard(
      backgroundColor: colors.surface,
      border: Border.all(color: colors.primary.withOpacity(0.35), width: 1.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.wb_sunny_rounded, color: colors.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Daily Readiness",
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        "What do I need to know & do today?",
                        style: AppTypography.caption.copyWith(color: colors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: AppTypography.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 12),

          // Readiness Content based strictly on live data
          if (hasBrief && brief!.focus.isNotEmpty) ...[
            _buildReadinessItem(
              icon: Icons.track_changes_outlined,
              iconColor: colors.primary,
              label: "Primary Focus",
              description: brief!.focus,
              colors: colors,
            ),
            const SizedBox(height: 10),
          ],

          if (hasBrief && brief!.plan.isNotEmpty) ...[
            _buildReadinessItem(
              icon: Icons.calendar_today_outlined,
              iconColor: Colors.teal,
              label: "Schedule & Work Blocks",
              description: brief!.plan,
              colors: colors,
            ),
            const SizedBox(height: 10),
          ],

          if (hasBrief && brief!.prepare.isNotEmpty) ...[
            _buildReadinessItem(
              icon: Icons.checkroom_outlined,
              iconColor: Colors.deepPurple,
              label: "Outfit & Environmental Readiness",
              description: brief!.prepare,
              colors: colors,
            ),
            const SizedBox(height: 10),
          ],

          if (hasBrief && brief!.wellness.isNotEmpty) ...[
            _buildReadinessItem(
              icon: Icons.spa_outlined,
              iconColor: Colors.green,
              label: "Wellness & Self-Care",
              description: brief!.wellness,
              colors: colors,
            ),
            const SizedBox(height: 10),
          ],

          if (!hasBrief || (brief!.focus.isEmpty && brief!.plan.isEmpty)) ...[
            Text(
              "Your live daily agenda is currently clear. Add tasks, events, or habits to trigger proactive readiness intelligence.",
              style: AppTypography.caption.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 10),
          ],

          // Footer action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onOpenAi,
                icon: Icon(Icons.chat_bubble_outline, size: 14, color: colors.primary),
                label: Text(
                  "Discuss Day with AI",
                  style: AppTypography.caption.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String description,
    required AppSemanticColors colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
