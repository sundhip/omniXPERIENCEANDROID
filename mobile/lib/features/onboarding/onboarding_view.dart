import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../core/storage/secure_storage.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/components/filter_chip.dart';
import '../../shared/components/app_card.dart';

class OnboardingView extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingView({super.key, required this.onComplete});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int _currentStep = 0;
  final _nameController = TextEditingController(text: "Alex Chen");
  final Set<String> _selectedStyles = {"Minimal", "Casual"};
  final Set<String> _selectedPriorities = {"Comfort", "Appearance", "Time saving"};
  bool _aiConsentGranted = true;
  bool _isSaving = false;

  final List<String> _allStyles = ["Minimal", "Classic", "Casual", "Street", "Formal", "Sporty", "Smart Casual"];
  final List<String> _allPriorities = ["Comfort", "Appearance", "Budget", "Time saving", "Trends"];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final name = await SecureStorage.getDisplayName();
    if (name != null && name.isNotEmpty && mounted) {
      setState(() => _nameController.text = name);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      setState(() => _isSaving = true);
      // Persist onboarding completion and display name
      final name = _nameController.text.trim();
      if (name.isNotEmpty) {
        await SecureStorage.setDisplayName(name);
      }
      await SecureStorage.setOnboardingCompleted(true);
      setState(() => _isSaving = false);
      widget.onComplete();
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text('Setup Profile (${_currentStep + 1}/4)', style: AppTypography.h3),
          backgroundColor: colors.background,
          elevation: 0,
          leading: _currentStep > 0
              ? IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                  onPressed: _handleBack,
                )
              : null,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppGeometry.sectionPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  isLoading: _isSaving,
                  onPressed: _handleNext,
                ),
              ],
            ),
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
              runSpacing: 8,
              children: _allStyles.map((s) {
                final isSelected = _selectedStyles.contains(s);
                return SemanticFilterChip(
                  label: s,
                  isSelected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      if (isSelected) {
                        _selectedStyles.remove(s);
                      } else {
                        _selectedStyles.add(s);
                      }
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
            Text("What matters most when dressing?", style: AppTypography.h1.copyWith(color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text("We prioritize these factors when planning ensembles.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
            const SizedBox(height: AppGeometry.gapLarge),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allPriorities.map((p) {
                final isSelected = _selectedPriorities.contains(p);
                return SemanticFilterChip(
                  label: p,
                  isSelected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      if (isSelected) {
                        _selectedPriorities.remove(p);
                      } else {
                        _selectedPriorities.add(p);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("OP AI Privacy & Personalization", style: AppTypography.h1.copyWith(color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text("Your personal wardrobe data stays private and encrypted.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
            const SizedBox(height: AppGeometry.gapLarge),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: colors.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text("Enable OP AI Context Engine", style: AppTypography.label.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Allows OP AI to synthesize weather, calendar occasions, and wear frequency into daily recommendations.",
                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: AppGeometry.gapNormal),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Active Intelligence", style: AppTypography.label.copyWith(color: colors.textPrimary)),
                    value: _aiConsentGranted,
                    activeTrackColor: colors.primarySoft,
                    activeThumbColor: colors.primary,
                    onChanged: (v) => setState(() => _aiConsentGranted = v),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}
