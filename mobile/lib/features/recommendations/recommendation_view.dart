import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/components/app_card.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/ai_insight_card.dart';

class RecommendationView extends StatefulWidget {
  const RecommendationView({Key? key}) : super(key: key);

  @override
  State<RecommendationView> createState() => _RecommendationViewState();
}

class _RecommendationViewState extends State<RecommendationView> {
  void _showFeedbackModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppGeometry.radiusModal)),
      ),
      builder: (ctx) {
        final colors = ctx.colors;
        return Padding(
          padding: const EdgeInsets.all(AppGeometry.sectionPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How was this outfit pick?', style: AppTypography.h3.copyWith(color: colors.textPrimary)),
              const SizedBox(height: 8),
              Text('Your feedback tunes your personal scoring weights.', style: AppTypography.body.copyWith(color: colors.textSecondary)),
              const SizedBox(height: AppGeometry.gapLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _feedbackPill("Loved it", "??", colors),
                  _feedbackPill("Fine", "??", colors),
                  _feedbackPill("Not for me", "??", colors),
                ],
              ),
              const SizedBox(height: AppGeometry.gapLarge),
              AppButton(
                label: 'Submit Feedback',
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('? Personalization signals updated')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _feedbackPill(String label, String emoji, AppSemanticColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.label.copyWith(color: colors.textPrimary)),
        ],
      ),
    );
  }

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
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: colors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('Recommended for You', style: AppTypography.h2.copyWith(color: colors.textPrimary)),
                ],
              ),
              Text('Dinner ? 28?C ? Clear', style: AppTypography.body.copyWith(color: colors.textSecondary)),
              const SizedBox(height: AppGeometry.gapLarge),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppGeometry.radiusCard - 2),
                      ),
                      child: Center(
                        child: Icon(Icons.checkroom, size: 64, color: colors.primary.withValues(alpha: 0.8)),
                      ),
                    ),
                    const SizedBox(height: AppGeometry.gapNormal),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Curated Ensemble', style: AppTypography.h3.copyWith(color: colors.textPrimary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '92% Match',
                            style: AppTypography.caption.copyWith(color: colors.success, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('? White Oxford Shirt', style: AppTypography.body.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500)),
                    Text('? Navy Slim Trousers', style: AppTypography.body.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500)),
                    Text('? Minimalist White Low-Tops', style: AppTypography.body.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: AppGeometry.gapLarge),
              const AIInsightCard(
                title: "Why this works",
                message: "Fits the dinner occasion, suits today's 28?C clear evening, and brings forward versatile pieces you haven't worn in 3 weeks.",
              ),
              const SizedBox(height: AppGeometry.gapLarge),
              AppButton(
                label: 'Wear This',
                icon: const Icon(Icons.check, size: 18),
                onPressed: _showFeedbackModal,
              ),
              const SizedBox(height: AppGeometry.gapSmall),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Change Items',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppGeometry.gapSmall),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Not For Me',
                      onPressed: _showFeedbackModal,
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
