import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_card.dart';
import '../recommendations/recommendation_view.dart';

class OutfitPlannerView extends StatelessWidget {
  const OutfitPlannerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppGeometry.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan Outfit', style: AppTypography.h2.copyWith(color: colors.textPrimary)),
              const SizedBox(height: 4),
              Text('Saturday, Sep 5 ? Dinner Event', style: AppTypography.body.copyWith(color: colors.textSecondary)),
              const SizedBox(height: AppGeometry.gapNormal),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppGeometry.radiusInput),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: colors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text("28?C ? Clear Sky (10% Rain)", style: AppTypography.label.copyWith(color: colors.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: AppGeometry.gapLarge),
              _buildSlotCard("SHIRT", "White Oxford Shirt", "Smart Casual ? 100% Cotton", Icons.checkroom, colors),
              const SizedBox(height: AppGeometry.gapSmall),
              Center(child: Text("+", style: TextStyle(color: colors.textMuted, fontSize: 18))),
              const SizedBox(height: AppGeometry.gapSmall),
              _buildSlotCard("PANTS", "Navy Slim Trousers", "Smart Casual ? Stretch Cotton", Icons.dry_cleaning, colors),
              const SizedBox(height: AppGeometry.gapSmall),
              Center(child: Text("+", style: TextStyle(color: colors.textMuted, fontSize: 18))),
              const SizedBox(height: AppGeometry.gapSmall),
              _buildSlotCard("SHOES", "Minimal White Sneakers", "Casual ? Italian Leather", Icons.roller_skating, colors),
              const SizedBox(height: AppGeometry.gapLarge),
              AppButton(
                label: 'Ask OP AI for Recommendation',
                icon: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RecommendationView()));
                },
              ),
              const SizedBox(height: AppGeometry.gapSmall),
              SecondaryButton(
                label: 'Save Planned Outfit',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('? Outfit saved to calendar')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCard(String slotName, String itemName, String subtitle, IconData icon, AppSemanticColors colors) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slotName, style: AppTypography.caption.copyWith(color: colors.textMuted, fontWeight: FontWeight.bold)),
                Text(itemName, style: AppTypography.label.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                Text(subtitle, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.swap_horiz, color: colors.textMuted),
        ],
      ),
    );
  }
}
