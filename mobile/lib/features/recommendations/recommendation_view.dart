import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/components/app_card.dart';
import '../../shared/components/app_button.dart';

class RecommendationView extends StatefulWidget {
  const RecommendationView({super.key});

  @override
  State<RecommendationView> createState() => _RecommendationViewState();
}

class _RecommendationViewState extends State<RecommendationView> {
  bool _feedbackSubmitted = false;

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
              Text('Your feedback will calibrate personal scoring weights.', style: AppTypography.body.copyWith(color: colors.textSecondary)),
              const SizedBox(height: AppGeometry.gapLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _feedbackPill("Loved it", "★", colors),
                  _feedbackPill("Fine", "•", colors),
                  _feedbackPill("Not for me", "✕", colors),
                ],
              ),
              const SizedBox(height: AppGeometry.gapLarge),
              AppButton(
                label: 'Submit Feedback',
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _feedbackSubmitted = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback recorded for recommendation engine')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _feedbackPill(String label, String iconText, AppSemanticColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Text(iconText, style: TextStyle(fontSize: 16, color: colors.primary)),
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
      appBar: AppBar(
        title: const Text('Recommendations'),
        backgroundColor: colors.background,
      ),
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
                  Text('Curated for Today', style: AppTypography.h2.copyWith(color: colors.textPrimary)),
                ],
              ),
              Text('Dinner • 28°C • Clear Sky', style: AppTypography.body.copyWith(color: colors.textSecondary)),
              const SizedBox(height: AppGeometry.gapLarge),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
                      ),
                      child: Center(
                        child: Icon(Icons.checkroom, size: 72, color: colors.primary),
                      ),
                    ),
                    const SizedBox(height: AppGeometry.gapNormal),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sample Baseline Ensemble', style: AppTypography.h3.copyWith(color: colors.textPrimary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('92% Match', style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('• White Oxford Shirt', style: AppTypography.body.copyWith(color: colors.textSecondary)),
                    Text('• Navy Slim Trousers', style: AppTypography.body.copyWith(color: colors.textSecondary)),
                    Text('• Minimalist White Low-Tops', style: AppTypography.body.copyWith(color: colors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: AppGeometry.gapLarge),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: colors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Phase 0 Foundation Note', style: AppTypography.label.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Full multimodal Gemini outfit intelligence is slated for Phase 1. This preview uses the deterministic scoring engine rules to balance rotation frequency and occasion.',
                      style: AppTypography.body.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppGeometry.gapLarge),
              AppButton(
                label: _feedbackSubmitted ? '✓ Ensemble Logged' : 'Wear This Outfit',
                icon: const Icon(Icons.check, size: 18),
                onPressed: _showFeedbackModal,
              ),
              const SizedBox(height: AppGeometry.gapSmall),
              SecondaryButton(
                label: 'Provide Feedback',
                onPressed: _showFeedbackModal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
