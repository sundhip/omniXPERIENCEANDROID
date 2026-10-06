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
  static const int _totalSteps = 10;
  int _currentStep = 0;

  // Step 0: Welcome & Identity
  final _nameController = TextEditingController(text: "Alex Chen");
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  String? _gender;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _bodyType = 'Average';

  // Step 1: Aesthetic Style
  final Set<String> _selectedStyles = {"Minimal", "Casual", "Smart Casual"};
  String _primaryStyle = 'Smart Casual';

  // Step 2: Fit Preference
  String _primaryFit = 'Relaxed';
  String? _secondaryFit = 'Regular';

  // Step 3: Color Palette & Openness
  final Set<String> _preferredColors = {"#1E3A8A", "#FFFFFF", "#000000"};
  final Set<String> _neutralColors = {"#1F2937", "#6B7280", "#E5E7EB"};
  final Set<String> _dislikedColors = {"#F59E0B"};
  final Set<String> _colorsToExperiment = {"#881337"};
  double _colorExperimentationScore = 0.5;

  // Step 4: Occasions & Priority Dressing
  final Set<String> _selectedOccasions = {"Office", "College", "Casual outing", "Party"};
  final List<String> _topOccasions = ["Office", "College", "Casual outing"];

  // Step 5: Weekly Routine & Outfit Frequency
  final Set<String> _selectedLifestyle = {"Work", "College", "Gym", "Travel"};
  final Map<String, double> _occasionFrequencies = {
    'casual': 0.9,
    'smart_casual': 0.7,
    'formal': 0.3,
    'sportswear': 0.5,
  };

  // Step 6: Comfort vs Appearance & Adventurousness
  double _comfortAppearanceScore = 0.4; // 0.0 (Comfort) <---> 1.0 (Appearance)
  double _experimentationScore = 0.5; // Very Safe to Very Experimental

  // Step 7: Fashion Priorities Ranking
  List<String> _rankedPriorities = [
    'comfort',
    'appearance',
    'practicality',
    'color_coordination',
    'occasion_suitability',
    'trendiness',
    'uniqueness',
    'weather_suitability',
  ];

  // Step 8: Brands & Budget (Optional)
  final _brandController = TextEditingController();
  final Set<String> _preferredBrands = {"Uniqlo", "Zara"};
  final Set<String> _avoidedBrands = {};
  String _budgetTier = 'Mid-range';

  bool _isSaving = false;
  String? _errorMessage;

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
            if (draft['primary_style'] != null) _primaryStyle = draft['primary_style'];
            if (draft['primary_fit'] != null) _primaryFit = draft['primary_fit'];
            if (draft['secondary_fit'] != null) _secondaryFit = draft['secondary_fit'];
            if (draft['preferred_colors'] is List) {
              _preferredColors.clear();
              _preferredColors.addAll(List<String>.from(draft['preferred_colors']));
            }
            if (draft['neutral_colors'] is List) {
              _neutralColors.clear();
              _neutralColors.addAll(List<String>.from(draft['neutral_colors']));
            }
            if (draft['disliked_colors'] is List) {
              _dislikedColors.clear();
              _dislikedColors.addAll(List<String>.from(draft['disliked_colors']));
            }
            if (draft['colors_to_experiment'] is List) {
              _colorsToExperiment.clear();
              _colorsToExperiment.addAll(List<String>.from(draft['colors_to_experiment']));
            }
            if (draft['color_experimentation_score'] is num) {
              _colorExperimentationScore = (draft['color_experimentation_score'] as num).toDouble();
            }
            if (draft['occasions'] is List) {
              _selectedOccasions.clear();
              _selectedOccasions.addAll(List<String>.from(draft['occasions']));
            }
            if (draft['top_occasions'] is List) {
              _topOccasions.clear();
              _topOccasions.addAll(List<String>.from(draft['top_occasions']));
            }
            if (draft['lifestyle'] is List) {
              _selectedLifestyle.clear();
              _selectedLifestyle.addAll(List<String>.from(draft['lifestyle']));
            }
            if (draft['comfort_appearance_score'] is num) {
              _comfortAppearanceScore = (draft['comfort_appearance_score'] as num).toDouble();
            }
            if (draft['experimentation_score'] is num) {
              _experimentationScore = (draft['experimentation_score'] as num).toDouble();
            }
            if (draft['ranked_priorities'] is List) {
              _rankedPriorities = List<String>.from(draft['ranked_priorities']);
            }
            if (draft['preferred_brands'] is List) {
              _preferredBrands.clear();
              _preferredBrands.addAll(List<String>.from(draft['preferred_brands']));
            }
            if (draft['budget_tier'] != null) _budgetTier = draft['budget_tier'];
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
      'primary_style': _primaryStyle,
      'primary_fit': _primaryFit,
      'secondary_fit': _secondaryFit,
      'preferred_colors': _preferredColors.toList(),
      'neutral_colors': _neutralColors.toList(),
      'disliked_colors': _dislikedColors.toList(),
      'colors_to_experiment': _colorsToExperiment.toList(),
      'color_experimentation_score': _colorExperimentationScore,
      'occasions': _selectedOccasions.toList(),
      'top_occasions': _topOccasions,
      'lifestyle': _selectedLifestyle.toList(),
      'comfort_appearance_score': _comfortAppearanceScore,
      'experimentation_score': _experimentationScore,
      'ranked_priorities': _rankedPriorities,
      'preferred_brands': _preferredBrands.toList(),
      'budget_tier': _budgetTier,
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
    _brandController.dispose();
    super.dispose();
  }

  void _handleNext() {
    setState(() => _errorMessage = null);
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _saveDraft();
    } else {
      _completeAndSubmit();
    }
  }

  void _handleBack() {
    setState(() => _errorMessage = null);
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _saveDraft();
    }
  }

  void _jumpToStep(int step) {
    setState(() {
      _currentStep = step.clamp(0, _totalSteps - 1);
      _errorMessage = null;
    });
    _saveDraft();
  }

  Future<void> _completeAndSubmit() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : "OmniPresence User";
    final age = int.tryParse(_ageController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    final secondaryStylesList = _selectedStyles.where((s) => s != _primaryStyle).toList();

    // Deterministic priority weight mapping
    final n = _rankedPriorities.length;
    final Map<String, double> priorityWeights = {};
    for (int i = 0; i < n; i++) {
      final weightVal = n <= 1 ? 1.0 : 1.0 - (i * (0.8 / (n - 1)));
      priorityWeights[_rankedPriorities[i]] = double.parse(weightVal.toStringAsFixed(2));
    }

    final profile = UserProfileModel(
      displayName: name,
      age: age,
      gender: _gender,
      location: _locationController.text.trim(),
      heightCm: height,
      weightKg: weight,
      bodyType: _bodyType,
      stylePreferences: _selectedStyles.toList(),
      primaryStyle: _primaryStyle,
      secondaryStyles: secondaryStylesList,
      fitPreference: _primaryFit,
      primaryFit: _primaryFit,
      secondaryFit: _secondaryFit,
      preferredColors: _preferredColors.toList(),
      neutralColors: _neutralColors.toList(),
      dislikedColors: _dislikedColors.toList(),
      colorsToExperiment: _colorsToExperiment.toList(),
      colorExperimentationScore: _colorExperimentationScore,
      occasions: _selectedOccasions.toList(),
      topOccasions: _topOccasions,
      occasionFrequencies: _occasionFrequencies,
      lifestyle: _selectedLifestyle.toList(),
      comfortAppearanceScore: _comfortAppearanceScore,
      experimentationScore: _experimentationScore,
      priorities: priorityWeights,
      fashionPrioritiesRanked: _rankedPriorities,
      fashionPriorityWeights: priorityWeights,
      preferredBrands: _preferredBrands.toList(),
      avoidedBrands: _avoidedBrands.toList(),
      budgetTier: _budgetTier,
      onboardingCompleted: true,
    );

    try {
      context.read<ProfileBloc>().add(SaveOnboardingProfileRequested(profile));
      await SecureStorage.setDisplayName(name);
      await SecureStorage.setOnboardingCompleted(true);
      await SecureStorage.clearOnboardingDraft();
      if (mounted) {
        setState(() => _isSaving = false);
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = "Could not save your profile right now. Your answers are preserved.";
        });
      }
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
          backgroundColor: colors.background,
          elevation: 0,
          leading: _currentStep > 0
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
                  onPressed: _handleBack,
                )
              : null,
          title: Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: AppTypography.caption.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600),
          ),
          actions: [
            if (_currentStep < _totalSteps - 1)
              TextButton(
                onPressed: _handleNext,
                child: Text('Skip', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: colors.surfaceSoft,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              minHeight: 3,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_errorMessage != null)
                Container(
                  color: Colors.red.shade900.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!, style: AppTypography.caption.copyWith(color: Colors.redAccent)),
                      ),
                      TextButton(
                        onPressed: _completeAndSubmit,
                        child: const Text('Try Again', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: _buildCurrentStepView(),
                ),
              ),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep0Identity();
      case 1:
        return _buildStep1Styles();
      case 2:
        return _buildStep2Fit();
      case 3:
        return _buildStep3Colors();
      case 4:
        return _buildStep4Occasions();
      case 5:
        return _buildStep5Routine();
      case 6:
        return _buildStep6ComfortAndAdventurousness();
      case 7:
        return _buildStep7FashionPriorities();
      case 8:
        return _buildStep8BrandsAndBudget();
      case 9:
        return _buildStep9ReviewAndSynthesis();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 0: Welcome & Identity
  Widget _buildStep0Identity() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Welcome to OmniXPERIENCE", style: AppTypography.h2),
        const SizedBox(height: 6),
        Text("Let's understand who you are and build your personal presence.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 24),
        AppTextField(controller: _nameController, label: "Preferred Name", hint: "Alex Chen"),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _ageController,
                label: "Age (Optional)",
                hint: "26",
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: _locationController,
                label: "City / Location",
                hint: "San Francisco",
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text("Gender (Optional)", style: AppTypography.label.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ["Male", "Female", "Non-Binary", "Prefer not to say"].map((g) {
            final isSelected = _gender == g;
            return ChoiceChip(
              label: Text(g),
              selected: isSelected,
              onSelected: (val) => setState(() => _gender = val ? g : null),
              selectedColor: colors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? colors.primary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text("Physical Profile (User-declared)", style: AppTypography.label.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _heightController,
                label: "Height (cm)",
                hint: "178",
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: _weightController,
                label: "Weight (kg)",
                hint: "72",
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text("Body Type", style: AppTypography.label.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserProfileModel.availableBodyTypes.map((bt) {
            final isSelected = _bodyType == bt['id'];
            return ChoiceChip(
              label: Text(bt['label']!),
              selected: isSelected,
              onSelected: (val) => setState(() => _bodyType = bt['id']!),
              selectedColor: colors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? colors.primary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 1: Aesthetic Style
  Widget _buildStep1Styles() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Your Style Identity", style: AppTypography.h2),
        const SizedBox(height: 6),
        Text("Which styles do you naturally gravitate toward? (Select all that fit you)", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: UserProfileModel.availableStyles.map((s) {
            final isSelected = _selectedStyles.contains(s['id']);
            return FilterChip(
              label: Text(s['label']!),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedStyles.add(s['id']!);
                    if (_selectedStyles.length == 1) _primaryStyle = s['id']!;
                  } else {
                    _selectedStyles.remove(s['id']!);
                    if (_primaryStyle == s['id'] && _selectedStyles.isNotEmpty) {
                      _primaryStyle = _selectedStyles.first;
                    }
                  }
                });
              },
              selectedColor: colors.primary.withValues(alpha: 0.15),
              checkmarkColor: colors.primary,
              labelStyle: TextStyle(
                color: isSelected ? colors.primary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Text("Your Everyday Primary Style", style: AppTypography.label.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("If you had to choose one style that fits you best day-to-day:", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (_selectedStyles.isNotEmpty ? _selectedStyles : UserProfileModel.availableStyles.map((s) => s['id']!)).map((sId) {
            final isPrimary = _primaryStyle == sId;
            return ChoiceChip(
              avatar: isPrimary ? Icon(Icons.star_rounded, size: 16, color: colors.primary) : null,
              label: Text(sId),
              selected: isPrimary,
              onSelected: (val) => setState(() => _primaryStyle = sId),
              selectedColor: colors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isPrimary ? colors.primary : colors.textSecondary,
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 2: Fit Preference
  Widget _buildStep2Fit() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Your Ideal Fit", style: AppTypography.h2),
        const SizedBox(height: 6),
        Text("What fit do you feel most comfortable wearing?", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 20),
        Text("Primary Fit", style: AppTypography.label.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserProfileModel.availableFits.map((f) {
            final isSelected = _primaryFit == f['id'];
            return ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (val) => setState(() => _primaryFit = f['id']!),
              selectedColor: colors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? colors.primary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        Text("Secondary Fit (Optional)", style: AppTypography.label.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 4),
        Text("Do you also enjoy an alternative fit for specific occasions?", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            {'id': 'None', 'label': 'No secondary fit'},
            ...UserProfileModel.availableFits,
          ].map((f) {
            final isSelected = (_secondaryFit ?? 'None') == f['id'];
            return ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (val) => setState(() => _secondaryFit = f['id'] == 'None' ? null : f['id']),
              selectedColor: colors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? colors.primary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 3: Color Palette & Openness
  Widget _buildStep3Colors() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Color Palette & Tone", style: AppTypography.h2),
        const SizedBox(height: 6),
        Text("Select the colors you love, stick to as neutrals, or avoid.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 20),
        
        // Favorite Colors
        Text("Favorite Colors", style: AppTypography.label.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildColorMatrix(_preferredColors, (hex) {
          setState(() {
            _preferredColors.contains(hex) ? _preferredColors.remove(hex) : _preferredColors.add(hex);
            _dislikedColors.remove(hex);
          });
        }),
        const SizedBox(height: 20),

        // Neutral Colors
        Text("Neutral Staples", style: AppTypography.label.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserProfileModel.neutralColorsList.map((c) {
            final hex = c['hex'] as String;
            final isSelected = _neutralColors.contains(hex);
            return FilterChip(
              avatar: CircleAvatar(backgroundColor: Color(c['color'] as int), radius: 8),
              label: Text(c['name'] as String),
              selected: isSelected,
              onSelected: (val) => setState(() => val ? _neutralColors.add(hex) : _neutralColors.remove(hex)),
              selectedColor: colors.primary.withValues(alpha: 0.15),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Avoided Colors
        Text("Colors You Avoid", style: AppTypography.label.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildColorMatrix(_dislikedColors, (hex) {
          setState(() {
            _dislikedColors.contains(hex) ? _dislikedColors.remove(hex) : _dislikedColors.add(hex);
            _preferredColors.remove(hex);
          });
        }),
        const SizedBox(height: 24),

        // Openness Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Willingness to Experiment with Colors", style: AppTypography.label.copyWith(color: colors.textSecondary)),
            Text("${(_colorExperimentationScore * 100).toInt()}%", style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: _colorExperimentationScore,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          activeColor: colors.primary,
          inactiveColor: colors.surfaceSoft,
          onChanged: (val) => setState(() => _colorExperimentationScore = val),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Stick to staples", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
            Text("Open to experimentation", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildColorMatrix(Set<String> targetSet, Function(String) onToggle) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: UserProfileModel.standardColors.map((c) {
        final hex = c['hex'] as String;
        final isSelected = targetSet.contains(hex);
        return GestureDetector(
          onTap: () => onToggle(hex),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color(c['color'] as int),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? context.colors.primary : Colors.grey.withValues(alpha: 0.4),
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: context.colors.primary.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)]
                  : null,
            ),
            child: isSelected
                ? Icon(Icons.check, size: 22, color: hex == '#FFFFFF' || hex == '#E5E7EB' ? Colors.black : Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  // STEP 4: Occasions & Priority Dressing
  Widget _buildStep4Occasions() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Where You Dress Up", style: AppTypography.h2),
        const SizedBox(height: 6),
        Text("Where do you need outfit recommendations?", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserProfileModel.availableOccasions.map((o) {
            final isSelected = _selectedOccasions.contains(o['id']);
            return FilterChip(
              label: Text(o['label']!),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedOccasions.add(o['id']!);
                    if (_topOccasions.length < 3 && !_topOccasions.contains(o['id'])) {
                      _topOccasions.add(o['id']!);
                    }
                  } else {
                    _selectedOccasions.remove(o['id']!);
                    _topOccasions.remove(o['id']!);
                  }
                });
              },
              selectedColor: colors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? colors.primary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Text("Which do you dress for most often? (Pick up to 3)", style: AppTypography.label.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedOccasions.map((oId) {
            final isTop = _topOccasions.contains(oId);
            final rank = isTop ? (_topOccasions.indexOf(oId) + 1) : null;
            return ChoiceChip(
              avatar: isTop ? CircleAvatar(radius: 10, backgroundColor: colors.primary, child: Text("$rank", style: const TextStyle(fontSize: 10, color: Colors.white))) : null,
              label: Text(oId),
              selected: isTop,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    if (_topOccasions.length < 3) _topOccasions.add(oId);
                  } else {
                    _topOccasions.remove(oId);
                  }
                });
              },
              selectedColor: colors.primary.withValues(alpha: 0.2),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 5: Weekly Routine & Outfit Frequency
  Widget _buildStep5Routine() {
    final colors = context.colors;
    final hasCollege = _selectedOccasions.contains('College') || _selectedLifestyle.contains('College');
    final hasFormal = _selectedOccasions.contains('Office') || _selectedOccasions.contains('Formal event');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Your Weekly Rhythm", style: AppTypography.h2),
        const SizedBox(height: 6),
        Text("Which activities are part of your regular week?", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserProfileModel.availableLifestyle.map((l) {
            final isSelected = _selectedLifestyle.contains(l['id']);
            return FilterChip(
              label: Text(l['label']!),
              selected: isSelected,
              onSelected: (val) => setState(() => val ? _selectedLifestyle.add(l['id']!) : _selectedLifestyle.remove(l['id']!)),
              selectedColor: colors.primary.withValues(alpha: 0.15),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        if (hasCollege || hasFormal)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: colors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasCollege && hasFormal
                        ? "Adaptive tailoring active for Campus and Professional schedules."
                        : hasCollege
                            ? "Adaptive tailoring active for Campus daily routines."
                            : "Adaptive tailoring active for Professional and Formalwear needs.",
                    style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        Text("Outfit Need Frequency", style: AppTypography.label.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...['casual', 'smart_casual', 'formal', 'sportswear'].map((cat) {
          final label = cat == 'smart_casual' ? 'Smart Casual' : cat[0].toUpperCase() + cat.substring(1);
          final val = _occasionFrequencies[cat] ?? 0.5;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: AppTypography.label.copyWith(color: colors.textSecondary)),
                    Text(
                      val >= 0.75 ? "Very often" : val >= 0.5 ? "Often" : val >= 0.25 ? "Sometimes" : "Rarely",
                      style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Slider(
                  value: val,
                  min: 0.0,
                  max: 1.0,
                  divisions: 3,
                  activeColor: colors.primary,
                  onChanged: (newVal) => setState(() => _occasionFrequencies[cat] = newVal),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // STEP 6: Comfort vs Appearance & Adventurousness
  Widget _buildStep6ComfortAndAdventurousness() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Your Styling Philosophy", style: AppTypography.h2),
        const SizedBox(height: 6),
        Text("When getting dressed, what matters more to you?", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 28),
        AppCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.spa_rounded, color: colors.primary, size: 20),
                      const SizedBox(width: 6),
                      Text("Comfort First", style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      Text("Appearance First", style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Icon(Icons.style_rounded, color: colors.primary, size: 20),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Slider(
                value: _comfortAppearanceScore,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                activeColor: colors.primary,
                inactiveColor: colors.surfaceSoft,
                onChanged: (val) => setState(() => _comfortAppearanceScore = val),
              ),
              Text(
                _comfortAppearanceScore < 0.4
                    ? "Prioritizes relaxed ease, breathability, and unrestricted feel."
                    : _comfortAppearanceScore > 0.6
                        ? "Prioritizes sharp silhouettes, tailoring, and visual impact."
                        : "Balanced: looks sharp while maintaining comfort.",
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text("How adventurous are you with your outfits?", style: AppTypography.label.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text("This determines how far recommendations can push outside your comfort zone.", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 12),
        ...UserProfileModel.experimentationLevels.map((lvl) {
          final score = lvl['score'] as double;
          final isSelected = (_experimentationScore - score).abs() < 0.12;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => _experimentationScore = score),
              borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary.withValues(alpha: 0.1) : colors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
                  border: Border.all(color: isSelected ? colors.primary : colors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? colors.primary : colors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lvl['label'] as String,
                        style: AppTypography.body.copyWith(
                          color: isSelected ? colors.primary : colors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text("${(score * 100).toInt()}%", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // STEP 7: Fashion Priorities Ranking
  Widget _buildStep7FashionPriorities() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Fashion Priorities", style: AppTypography.h2),
        const SizedBox(height: 6),
        Text("Arrange what matters most to least in your daily outfits.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 16),
        Text("Use handles to reorder priorities (top item receives highest weight):", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _rankedPriorities.length,
          // ignore: deprecated_member_use
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _rankedPriorities.removeAt(oldIndex);
              _rankedPriorities.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) {
            final key = _rankedPriorities[index];
            final label = UserProfileModel.standardRankedPriorities.firstWhere(
              (p) => p['key'] == key,
              orElse: () => {'key': key, 'label': key},
            )['label']!;

            final weightPct = _rankedPriorities.length <= 1
                ? 100
                : (100 - (index * (80 / (_rankedPriorities.length - 1)))).round();

            return Container(
              key: ValueKey(key),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
                border: Border.all(color: index == 0 ? colors.primary.withValues(alpha: 0.6) : colors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: index == 0 ? colors.primary : colors.border,
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(fontSize: 12, color: index == 0 ? Colors.white : colors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text("$weightPct%", style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.drag_handle_rounded, color: colors.textSecondary, size: 20),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // STEP 8: Brands & Budget (Optional)
  Widget _buildStep8BrandsAndBudget() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Brands & Budget (Optional)", style: AppTypography.h2),
        const SizedBox(height: 6),
        Text("Help us refine shopping and style affinity without pressure.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 20),
        Text("Preferred Brands", style: AppTypography.label.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _preferredBrands.map((b) {
            return Chip(
              label: Text(b),
              onDeleted: () => setState(() => _preferredBrands.remove(b)),
              deleteIconColor: colors.textSecondary,
              backgroundColor: colors.surfaceSoft,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppTextField(controller: _brandController, label: "Add Brand", hint: "e.g. Uniqlo, Levi's"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final txt = _brandController.text.trim();
                if (txt.isNotEmpty) {
                  setState(() {
                    _preferredBrands.add(txt);
                    _brandController.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text("Budget Tier", style: AppTypography.label.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: UserProfileModel.budgetTierOptions.map((tier) {
            final isSelected = _budgetTier == tier;
            return ChoiceChip(
              label: Text(tier),
              selected: isSelected,
              onSelected: (val) => setState(() => _budgetTier = tier),
              selectedColor: colors.primary.withValues(alpha: 0.15),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 9: Style Review & Synthesis
  Widget _buildStep9ReviewAndSynthesis() {
    final colors = context.colors;

    // Build model for preview synthesis
    final previewProfile = UserProfileModel(
      displayName: _nameController.text.trim(),
      primaryStyle: _primaryStyle,
      primaryFit: _primaryFit,
      preferredColors: _preferredColors.toList(),
      topOccasions: _topOccasions,
      comfortAppearanceScore: _comfortAppearanceScore,
      experimentationScore: _experimentationScore,
    );

    final summaryText = previewProfile.generateDeterministicSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Your Personal Style Profile", style: AppTypography.h2),
        const SizedBox(height: 6),
        Text("Review the personalized profile created from your answers.", style: AppTypography.body.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 20),

        // Synthesis Quote Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary.withValues(alpha: 0.15), colors.surfaceSoft],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
            border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text("Deterministic Profile Synthesis", style: AppTypography.label.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "\"$summaryText\"",
                style: AppTypography.body.copyWith(fontStyle: FontStyle.italic, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Summary Breakdown Cards
        _buildReviewSection(
          title: "Identity & Physical Stats",
          step: 0,
          content: "${_nameController.text.trim()} • $_bodyType • ${_heightController.text.isNotEmpty ? '${_heightController.text}cm' : ''} ${_weightController.text.isNotEmpty ? '${_weightController.text}kg' : ''}",
        ),
        _buildReviewSection(
          title: "Primary & Secondary Styles",
          step: 1,
          content: "Primary: $_primaryStyle\nSecondary: ${_selectedStyles.where((s) => s != _primaryStyle).join(', ')}",
        ),
        _buildReviewSection(
          title: "Fit Preference",
          step: 2,
          content: "Primary: $_primaryFit${_secondaryFit != null ? ' • Secondary: $_secondaryFit' : ''}",
        ),
        _buildReviewSection(
          title: "Color Profile",
          step: 3,
          content: "${_preferredColors.length} preferred colors • ${_neutralColors.length} neutrals • ${_dislikedColors.length} avoided",
        ),
        _buildReviewSection(
          title: "Top Occasions",
          step: 4,
          content: _topOccasions.join(' • '),
        ),
        _buildReviewSection(
          title: "Comfort vs Appearance",
          step: 6,
          content: "${(_comfortAppearanceScore * 100).toInt()}% Appearance Focus • Experimentation: ${(_experimentationScore * 100).toInt()}%",
        ),
        _buildReviewSection(
          title: "Top Priorities",
          step: 7,
          content: _rankedPriorities.take(3).map((p) => p.replaceAll('_', ' ')).join(' > '),
        ),
      ],
    );
  }

  Widget _buildReviewSection({required String title, required int step, required String content}) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.caption.copyWith(color: colors.textSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(content, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: colors.primary),
            onPressed: () => _jumpToStep(step),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final colors = context.colors;
    final isLast = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SecondaryButton(
                  label: 'Back',
                  onPressed: _handleBack,
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: AppButton(
              label: isLast ? 'Confirm & Get Started' : 'Next Step',
              isLoading: _isSaving,
              onPressed: _handleNext,
            ),
          ),
        ],
      ),
    );
  }
}
