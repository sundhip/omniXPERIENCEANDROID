import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../core/storage/secure_storage.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/components/app_card.dart';
import '../profile/models/user_profile_model.dart';
import '../profile/profile_bloc.dart';

class OnboardingView extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingView({super.key, required this.onComplete});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  static const int _totalSteps = 8;
  int _currentStep = 0;

  // Step 0: About You
  final _nameController = TextEditingController(text: "Alex Chen");
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  String? _gender;

  // Step 1: Physical Profile (User-declared)
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _bodyType = 'Average';

  // Step 2: Everyday Style
  final Set<String> _selectedStyles = {"Minimal", "Casual"};

  // Step 3: Fit Preference
  String _selectedFit = 'Regular';

  // Step 4: Color Preferences
  final Set<String> _preferredColors = {"#1E3A8A", "#FFFFFF", "#000000"};
  final Set<String> _dislikedColors = {};

  // Step 5: Occasions & Lifestyle
  final Set<String> _selectedOccasions = {"Office", "Casual Outing", "Party"};
  final Set<String> _selectedLifestyle = {"Work", "Gym", "Travel"};

  // Step 6: Priorities
  final Map<String, double> _priorities = {
    'comfort': 0.8,
    'appearance': 0.8,
    'practicality': 0.7,
    'formality': 0.5,
  };

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingOrDraftData();
  }

  Future<void> _loadExistingOrDraftData() async {
    // 1. Try loading draft
    final draftStr = await SecureStorage.getOnboardingDraft();
    if (draftStr != null && draftStr.isNotEmpty) {
      try {
        final draft = jsonDecode(draftStr);
        if (draft is Map<String, dynamic>) {
          setState(() {
            _currentStep = (draft['step'] as int? ?? 0).clamp(0, _totalSteps - 1);
            if (draft['name'] != null) _nameController.text = draft['name'];
            if (draft['age'] != null) _ageController.text = draft['age'];
            if (draft['location'] != null) _locationController.text = draft['location'];
            if (draft['gender'] != null) _gender = draft['gender'];
            if (draft['height'] != null) _heightController.text = draft['height'];
            if (draft['weight'] != null) _weightController.text = draft['weight'];
            if (draft['body_type'] != null) _bodyType = draft['body_type'];
            if (draft['styles'] is List) {
              _selectedStyles.clear();
              _selectedStyles.addAll(List<String>.from(draft['styles']));
            }
            if (draft['fit'] != null) _selectedFit = draft['fit'];
            if (draft['preferred_colors'] is List) {
              _preferredColors.clear();
              _preferredColors.addAll(List<String>.from(draft['preferred_colors']));
            }
            if (draft['disliked_colors'] is List) {
              _dislikedColors.clear();
              _dislikedColors.addAll(List<String>.from(draft['disliked_colors']));
            }
            if (draft['occasions'] is List) {
              _selectedOccasions.clear();
              _selectedOccasions.addAll(List<String>.from(draft['occasions']));
            }
            if (draft['lifestyle'] is List) {
              _selectedLifestyle.clear();
              _selectedLifestyle.addAll(List<String>.from(draft['lifestyle']));
            }
          });
          return;
        }
      } catch (_) {}
    }

    // 2. Prefill name from SecureStorage
    final savedName = await SecureStorage.getDisplayName();
    if (savedName != null && savedName.isNotEmpty && mounted) {
      setState(() => _nameController.text = savedName);
    }
  }

  Future<void> _saveDraft() async {
    final draft = {
      'step': _currentStep,
      'name': _nameController.text.trim(),
      'age': _ageController.text.trim(),
      'location': _locationController.text.trim(),
      'gender': _gender,
      'height': _heightController.text.trim(),
      'weight': _weightController.text.trim(),
      'body_type': _bodyType,
      'styles': _selectedStyles.toList(),
      'fit': _selectedFit,
      'preferred_colors': _preferredColors.toList(),
      'disliked_colors': _dislikedColors.toList(),
      'occasions': _selectedOccasions.toList(),
      'lifestyle': _selectedLifestyle.toList(),
    };
    await SecureStorage.saveOnboardingDraft(jsonEncode(draft));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _saveDraft();
    } else {
      _completeAndSubmit();
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _saveDraft();
    }
  }

  void _jumpToStep(int step) {
    setState(() => _currentStep = step.clamp(0, _totalSteps - 1));
    _saveDraft();
  }

  Future<void> _completeAndSubmit() async {
    setState(() => _isSaving = true);

    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : "OmniPresence User";
    final age = int.tryParse(_ageController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    final profile = UserProfileModel(
      displayName: name,
      age: age,
      gender: _gender,
      location: _locationController.text.trim(),
      heightCm: height,
      weightKg: weight,
      bodyType: _bodyType,
      stylePreferences: _selectedStyles.toList(),
      fitPreference: _selectedFit,
      preferredColors: _preferredColors.toList(),
      dislikedColors: _dislikedColors.toList(),
      occasions: _selectedOccasions.toList(),
      lifestyle: _selectedLifestyle.toList(),
      priorities: _priorities,
      onboardingCompleted: true,
    );

    context.read<ProfileBloc>().add(SaveOnboardingProfileRequested(profile));
    await SecureStorage.setDisplayName(name);
    await SecureStorage.setOnboardingCompleted(true);
    await SecureStorage.clearOnboardingDraft();

    setState(() => _isSaving = false);
    widget.onComplete();
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
          title: Text(
            'Setup Profile (${_currentStep + 1}/$_totalSteps)',
            style: AppTypography.h3.copyWith(color: colors.textPrimary),
          ),
          backgroundColor: colors.background,
          elevation: 0,
          leading: _currentStep > 0
              ? IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                  onPressed: _handleBack,
                )
              : null,
          actions: [
            if (_currentStep < _totalSteps - 1)
              TextButton(
                onPressed: _handleNext,
                child: Text('Skip', style: TextStyle(color: colors.textSecondary)),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Step Progress Line
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppGeometry.screenPadding),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    minHeight: 4,
                    backgroundColor: colors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppGeometry.screenPadding),
                  child: _buildCurrentStep(colors),
                ),
              ),
              // Bottom Action Bar
              Padding(
                padding: const EdgeInsets.all(AppGeometry.screenPadding),
                child: AppButton(
                  label: _currentStep == _totalSteps - 1
                      ? (_isSaving ? 'Saving...' : 'Confirm & Get Started')
                      : 'Continue',
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _handleNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(AppSemanticColors colors) {
    switch (_currentStep) {
      case 0:
        return _buildStepAboutYou(colors);
      case 1:
        return _buildStepPhysicalProfile(colors);
      case 2:
        return _buildStepStyle(colors);
      case 3:
        return _buildStepFit(colors);
      case 4:
        return _buildStepColors(colors);
      case 5:
        return _buildStepOccasionsLifestyle(colors);
      case 6:
        return _buildStepPriorities(colors);
      case 7:
        return _buildStepReview(colors);
      default:
        return const SizedBox();
    }
  }

  // STEP 0: ABOUT YOU
  Widget _buildStepAboutYou(AppSemanticColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Welcome to OmniPresence", style: AppTypography.h1.copyWith(color: colors.textPrimary)),
        const SizedBox(height: 8),
        Text("Let's establish your style profile to curate your daily wardrobe experience.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppGeometry.gapLarge),
        AppTextField(
          label: 'What should we call you? *',
          controller: _nameController,
          hint: 'Your name',
        ),
        const SizedBox(height: AppGeometry.gapNormal),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Age (optional)',
                controller: _ageController,
                keyboardType: TextInputType.number,
                hint: 'e.g. 26',
              ),
            ),
            const SizedBox(width: AppGeometry.gapNormal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gender (optional)', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppGeometry.radiusInput),
                      border: Border.all(color: colors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _gender,
                        hint: Text('Select', style: TextStyle(color: colors.textSecondary)),
                        items: ['Male', 'Female', 'Non-Binary', 'Prefer not to say']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) => setState(() => _gender = val),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppGeometry.gapNormal),
        AppTextField(
          label: 'Location / City (for weather matching)',
          controller: _locationController,
          hint: 'e.g. San Francisco, CA',
        ),
      ],
    );
  }

  // STEP 1: PHYSICAL PROFILE (User declared)
  Widget _buildStepPhysicalProfile(AppSemanticColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Physical Profile", style: AppTypography.h1.copyWith(color: colors.textPrimary)),
        const SizedBox(height: 8),
        Text("User-provided body dimensions to recommend clothes with the right proportion and fit.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppGeometry.gapLarge),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Height (cm)',
                controller: _heightController,
                keyboardType: TextInputType.number,
                hint: 'e.g. 175',
              ),
            ),
            const SizedBox(width: AppGeometry.gapNormal),
            Expanded(
              child: AppTextField(
                label: 'Weight (kg)',
                controller: _weightController,
                keyboardType: TextInputType.number,
                hint: 'e.g. 70',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppGeometry.gapNormal),
        Text('Body Type', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserProfileModel.availableBodyTypes.map((bt) {
            final isSelected = _bodyType == bt['id'];
            return ChoiceChip(
              label: Text(bt['label']!),
              selected: isSelected,
              onSelected: (_) => setState(() => _bodyType = bt['id']!),
              selectedColor: colors.primarySoft,
              labelStyle: TextStyle(color: isSelected ? colors.primary : colors.textPrimary),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 2: EVERYDAY STYLE
  Widget _buildStepStyle(AppSemanticColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("What best describes your style?", style: AppTypography.h1.copyWith(color: colors.textPrimary)),
        const SizedBox(height: 8),
        Text("Select all aesthetics you gravitate towards.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppGeometry.gapLarge),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserProfileModel.availableStyles.map((s) {
            final id = s['id']!;
            final isSelected = _selectedStyles.contains(id);
            return FilterChip(
              label: Text(s['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedStyles.add(id);
                  } else {
                    _selectedStyles.remove(id);
                  }
                });
              },
              selectedColor: colors.primarySoft,
              labelStyle: TextStyle(color: isSelected ? colors.primary : colors.textPrimary),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 3: FIT PREFERENCE
  Widget _buildStepFit(AppSemanticColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Preferred Fit", style: AppTypography.h1.copyWith(color: colors.textPrimary)),
        const SizedBox(height: 8),
        Text("What kind of silhouette do you usually feel most comfortable wearing?", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppGeometry.gapLarge),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserProfileModel.availableFits.map((f) {
            final id = f['id']!;
            final isSelected = _selectedFit == id;
            return ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFit = id),
              selectedColor: colors.primarySoft,
              labelStyle: TextStyle(color: isSelected ? colors.primary : colors.textPrimary),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 4: COLOR PREFERENCES
  Widget _buildStepColors(AppSemanticColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Color Preferences", style: AppTypography.h1.copyWith(color: colors.textPrimary)),
        const SizedBox(height: 8),
        Text("Choose colors you love wearing and any you avoid.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppGeometry.gapLarge),
        Text("Favorite & Preferred Colors", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
        const SizedBox(height: 8),
        _buildColorSelector(
          selectedHexes: _preferredColors,
          onToggle: (hex) {
            setState(() {
              if (_preferredColors.contains(hex)) {
                _preferredColors.remove(hex);
              } else {
                _preferredColors.add(hex);
                _dislikedColors.remove(hex);
              }
            });
          },
          colors: colors,
        ),
        const SizedBox(height: AppGeometry.gapLarge),
        Text("Colors You Avoid", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
        const SizedBox(height: 8),
        _buildColorSelector(
          selectedHexes: _dislikedColors,
          onToggle: (hex) {
            setState(() {
              if (_dislikedColors.contains(hex)) {
                _dislikedColors.remove(hex);
              } else {
                _dislikedColors.add(hex);
                _preferredColors.remove(hex);
              }
            });
          },
          colors: colors,
        ),
      ],
    );
  }

  // STEP 5: OCCASIONS & LIFESTYLE
  Widget _buildStepOccasionsLifestyle(AppSemanticColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Occasions & Routine", style: AppTypography.h1.copyWith(color: colors.textPrimary)),
        const SizedBox(height: 8),
        Text("What occasions do you regularly dress for?", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppGeometry.gapLarge),
        Text("Target Occasions", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserProfileModel.availableOccasions.map((o) {
            final id = o['id']!;
            final isSelected = _selectedOccasions.contains(id);
            return FilterChip(
              label: Text(o['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedOccasions.add(id);
                  } else {
                    _selectedOccasions.remove(id);
                  }
                });
              },
              selectedColor: colors.primarySoft,
              labelStyle: TextStyle(color: isSelected ? colors.primary : colors.textPrimary),
            );
          }).toList(),
        ),
        const SizedBox(height: AppGeometry.gapLarge),
        Text("Weekly Lifestyle Activities", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserProfileModel.availableLifestyle.map((l) {
            final id = l['id']!;
            final isSelected = _selectedLifestyle.contains(id);
            return FilterChip(
              label: Text(l['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedLifestyle.add(id);
                  } else {
                    _selectedLifestyle.remove(id);
                  }
                });
              },
              selectedColor: colors.primarySoft,
              labelStyle: TextStyle(color: isSelected ? colors.primary : colors.textPrimary),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 6: PRIORITIES
  Widget _buildStepPriorities(AppSemanticColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("What matters most when dressing?", style: AppTypography.h1.copyWith(color: colors.textPrimary)),
        const SizedBox(height: 8),
        Text("Set your personal priority weights for outfit synthesis.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppGeometry.gapLarge),
        ...UserProfileModel.availablePriorityKeys.map((pKey) {
          final key = pKey['key']!;
          final label = pKey['label']!;
          final value = _priorities[key] ?? 0.5;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: AppTypography.body.copyWith(color: colors.textPrimary)),
                  Text('${(value * 100).toInt()}%', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                activeColor: colors.primary,
                onChanged: (newVal) {
                  setState(() {
                    _priorities[key] = double.parse(newVal.toStringAsFixed(1));
                  });
                },
              ),
            ],
          );
        }),
      ],
    );
  }

  // STEP 7: REVIEW & CONFIRM
  Widget _buildStepReview(AppSemanticColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Your Profile Summary", style: AppTypography.h1.copyWith(color: colors.textPrimary)),
        const SizedBox(height: 8),
        Text("Review your information before finalizing your profile setup.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: AppGeometry.gapLarge),

        _buildReviewCard(
          title: 'Identity & Physical',
          subtitle: '${_nameController.text.trim()} • $_bodyType • Fit: $_selectedFit',
          onEdit: () => _jumpToStep(0),
          colors: colors,
        ),
        const SizedBox(height: AppGeometry.gapNormal),

        _buildReviewCard(
          title: 'Aesthetic Style',
          subtitle: _selectedStyles.isNotEmpty ? _selectedStyles.join(', ') : 'None selected',
          onEdit: () => _jumpToStep(2),
          colors: colors,
        ),
        const SizedBox(height: AppGeometry.gapNormal),

        _buildReviewCard(
          title: 'Color Palettes',
          subtitle: '${_preferredColors.length} preferred colors • ${_dislikedColors.length} avoided',
          onEdit: () => _jumpToStep(4),
          colors: colors,
        ),
        const SizedBox(height: AppGeometry.gapNormal),

        _buildReviewCard(
          title: 'Occasions & Routine',
          subtitle: '${_selectedOccasions.length} occasions • ${_selectedLifestyle.length} lifestyle tags',
          onEdit: () => _jumpToStep(5),
          colors: colors,
        ),
        const SizedBox(height: AppGeometry.gapNormal),

        _buildReviewCard(
          title: 'Priority Balance',
          subtitle: 'Comfort ${((_priorities['comfort'] ?? 0.8) * 100).toInt()}% • Appearance ${((_priorities['appearance'] ?? 0.8) * 100).toInt()}%',
          onEdit: () => _jumpToStep(6),
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildReviewCard({
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
    required AppSemanticColors colors,
  }) {
    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.label.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: Text('Edit', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector({
    required Set<String> selectedHexes,
    required ValueChanged<String> onToggle,
    required AppSemanticColors colors,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: UserProfileModel.standardColors.map((c) {
        final hex = c['hex'] as String;
        final name = c['name'] as String;
        final colorValue = Color(c['color'] as int);
        final isSelected = selectedHexes.contains(hex);

        return GestureDetector(
          onTap: () => onToggle(hex),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? colors.primarySoft : colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? colors.primary : colors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorValue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400, width: 0.5),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? colors.primary : colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
