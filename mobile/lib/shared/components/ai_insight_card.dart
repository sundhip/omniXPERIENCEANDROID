import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import 'app_card.dart';

class AIInsightCard extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AIInsightCard({
    Key? key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      backgroundColor: colors.surfaceTint,
      border: Border.all(color: colors.lavender.withValues(alpha: 0.4), width: 1.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.label.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppGeometry.gapSmall),
          Text(
            message,
            style: AppTypography.body.copyWith(
              color: colors.textPrimary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppGeometry.gapNormal),
            GestureDetector(
              onTap: onAction,
              child: Text(
                '$actionLabel',
                style: AppTypography.label.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
