import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/components/app_card.dart';
import '../../shared/components/ai_insight_card.dart';

class HomeView extends StatelessWidget {
  final VoidCallback onExploreWardrobe;
  final VoidCallback onAskOPAI;

  const HomeView({
    Key? key,
    required this.onExploreWardrobe,
    required this.onAskOPAI,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppGeometry.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top greeting bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Good Evening,", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                  Text("Alex Chen", style: AppTypography.h2.copyWith(color: colors.textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.surfaceSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, size: 16, color: colors.warning),
                    const SizedBox(width: 6),
                    Text("28?C ? Clear", style: AppTypography.label.copyWith(color: colors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppGeometry.gapLarge),
          
          // OP AI Smart Insight Card
          AIInsightCard(
            title: "OP AI Insight",
            message: "You haven't worn your White Oxford Shirt in 21 days. It pairs perfectly with your Navy Trousers for tonight's dinner.",
            actionLabel: "Create outfit",
            onAction: onAskOPAI,
          ),
          const SizedBox(height: AppGeometry.gapLarge),

          // Quick Action Cards
          Text("Quick Actions", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
          const SizedBox(height: AppGeometry.gapNormal),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  onTap: onAskOPAI,
                  backgroundColor: colors.surfaceSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, color: colors.primary, size: 24),
                      const SizedBox(height: 8),
                      Text("Get Outfit", style: AppTypography.label.copyWith(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                      Text("Personalized AI pick", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppGeometry.gapNormal),
              Expanded(
                child: AppCard(
                  onTap: onExploreWardrobe,
                  backgroundColor: colors.surfaceSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: colors.primary, size: 24),
                      const SizedBox(height: 8),
                      Text("Add Item", style: AppTypography.label.copyWith(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                      Text("Camera or Gallery", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppGeometry.gapLarge),

          // Wardrobe Health / Stats
          Text("Wardrobe Overview", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
          const SizedBox(height: AppGeometry.gapNormal),
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("Items", "126", colors),
                Container(height: 30, width: 1, color: colors.border),
                _buildStatItem("Active", "118", colors),
                Container(height: 30, width: 1, color: colors.border),
                _buildStatItem("Laundry", "8", colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, AppSemanticColors colors) {
    return Column(
      children: [
        Text(value, style: AppTypography.h2.copyWith(color: colors.textPrimary)),
        Text(label, style: AppTypography.caption.copyWith(color: colors.textMuted)),
      ],
    );
  }
}
