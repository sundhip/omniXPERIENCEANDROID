import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/components/filter_chip.dart';
import '../../shared/components/app_card.dart';

class OnboardingView extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingView({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int _currentStep = 0;
  final _nameController = TextEditingController(text: "Alex Chen");
  final Set<String> _selectedStyles = {"Minimal", "Casual"};
  final Set<String> _selectedPriorities = {"Comfort", "Appearance", "Time saving"};
  bool _aiConsentGranted = true;

  final List<String> _allStyles = ["Minimal", "Classic", "Casual", "Street", "Formal", "Sporty", "Smart Casual"];
  final List<String> _allPriorities = ["Comfort", "Appearance", "Budget", "Time saving", "Trends"];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Setup Profile (${_currentStep + 1}/4)', style: AppTypography.h3),
        backgroundColor: colors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppGeometry.sectionPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: (_currentStep + 1) / 4,
                backgroundColor: colors.surfaceSoft,
                color: colors.primary,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: AppGeometry.gapLarge),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStepContent(colors),
                ),
              ),
              AppButton(
                label: _currentStep == 3 ? 'Get Started' : 'Continue',
                onPressed: () {
                  if (_currentStep < 3) {
                    setState(() => _currentStep++);
                  } else {
                    widget.onComplete();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(AppSemanticColors colors) {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("What's your name?", style: AppTypography.h1.copyWith(color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text("How should OmniPresence address you?", style: AppTypography.body.copyWith(color: colors.textSecondary)),
            const SizedBox(height: AppGeometry.gapLarge),
            AppTextField(
              label: "Display Name",
              hint: "Your name",
              controller: _nameController,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("What best describes your style?", style: AppTypography.h1.copyWith(color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text("Select the aesthetics you gravitate towards.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
            const SizedBox(height: AppGeometry.gapLarge),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _allStyles.map((style) {
                final isSelected = _selectedStyles.contains(style);
                return SemanticFilterChip(
                  label: style,
                  isSelected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) _selectedStyles.add(style);
                      else _selectedStyles.remove(style);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("What matters most to you?", style: AppTypography.h1.copyWith(color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text("We balance these priorities in our recommendation engine.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
            const SizedBox(height: AppGeometry.gapLarge),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _allPriorities.map((p) {
                final isSelected = _selectedPriorities.contains(p);
                return SemanticFilterChip(
                  label: p,
                  isSelected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) _selectedPriorities.add(p);
                      else _selectedPriorities.remove(p);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      case 3:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("? OP AI Personalization", style: AppTypography.h1.copyWith(color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text("Explicitly choose how AI enriches your presence layer.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
            const SizedBox(height: AppGeometry.gapLarge),
            AppCard(
              backgroundColor: colors.surfaceTint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Allow Personalization", style: AppTypography.label.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                      Switch(
                        value: _aiConsentGranted,
                        activeTrackColor: colors.primarySoft, activeThumbColor: colors.primary,
                        onChanged: (val) => setState(() => _aiConsentGranted = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Allows OP AI to combine weather, calendar occasion, and wear frequency signals to propose curated outfits.",
                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}
