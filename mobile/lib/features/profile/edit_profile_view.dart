import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_text_field.dart';
import 'models/user_profile_model.dart';
import 'profile_bloc.dart';

class EditProfileView extends StatefulWidget {
  final UserProfileModel initialProfile;

  const EditProfileView({super.key, required this.initialProfile});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _locationController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  String? _selectedGender;
  String? _selectedBodyType;
  late Set<String> _selectedStyles;
  late String _primaryStyle;
  late String _selectedFit;
  String? _secondaryFit;
  late Set<String> _selectedPreferredColors;
  late Set<String> _selectedDislikedColors;
  late Set<String> _selectedNeutralColors;
  late Set<String> _selectedOccasions;
  late Set<String> _selectedLifestyle;
  late double _comfortAppearanceScore;
  late double _experimentationScore;
  late String _budgetTier;
  late Map<String, double> _priorities;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameController = TextEditingController(text: p.displayName);
    _ageController = TextEditingController(text: p.age != null ? p.age.toString() : '');
    _locationController = TextEditingController(text: p.location ?? '');
    _heightController = TextEditingController(text: p.heightCm != null ? p.heightCm!.toStringAsFixed(1) : '');
    _weightController = TextEditingController(text: p.weightKg != null ? p.weightKg!.toStringAsFixed(1) : '');

    _selectedGender = p.gender;
    _selectedBodyType = p.bodyType ?? 'Average';
    _selectedStyles = Set<String>.from(p.stylePreferences);
    _primaryStyle = p.primaryStyle.isNotEmpty ? p.primaryStyle : (_selectedStyles.isNotEmpty ? _selectedStyles.first : 'Casual');
    _selectedFit = p.primaryFit.isNotEmpty ? p.primaryFit : 'Regular';
    _secondaryFit = p.secondaryFit;
    _selectedPreferredColors = Set<String>.from(p.preferredColors);
    _selectedDislikedColors = Set<String>.from(p.dislikedColors);
    _selectedNeutralColors = Set<String>.from(p.neutralColors);
    _selectedOccasions = Set<String>.from(p.occasions);
    _selectedLifestyle = Set<String>.from(p.lifestyle);
    _comfortAppearanceScore = p.comfortAppearanceScore;
    _experimentationScore = p.experimentationScore;
    _budgetTier = p.budgetTier;
    _priorities = Map<String, double>.from(p.priorities);
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

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();

    final int? age = ageText.isNotEmpty ? int.tryParse(ageText) : null;
    final double? height = heightText.isNotEmpty ? double.tryParse(heightText) : null;
    final double? weight = weightText.isNotEmpty ? double.tryParse(weightText) : null;

    final updated = widget.initialProfile.copyWith(
      displayName: name,
      age: age,
      gender: _selectedGender,
      location: _locationController.text.trim(),
      heightCm: height,
      weightKg: weight,
      bodyType: _selectedBodyType,
      stylePreferences: _selectedStyles.toList(),
      primaryStyle: _primaryStyle,
      secondaryStyles: _selectedStyles.where((s) => s != _primaryStyle).toList(),
      primaryFit: _selectedFit,
      fitPreference: _selectedFit,
      secondaryFit: _secondaryFit,
      preferredColors: _selectedPreferredColors.toList(),
      dislikedColors: _selectedDislikedColors.toList(),
      neutralColors: _selectedNeutralColors.toList(),
      occasions: _selectedOccasions.toList(),
      lifestyle: _selectedLifestyle.toList(),
      comfortAppearanceScore: _comfortAppearanceScore,
      experimentationScore: _experimentationScore,
      budgetTier: _budgetTier,
      priorities: _priorities,
    );

    context.read<ProfileBloc>().add(UpdateProfileRequested(updated));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Edit Profile & Preferences', style: AppTypography.h3.copyWith(color: colors.textPrimary)),
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppGeometry.screenPadding),
            children: [
              // SECTION 1: IDENTITY
              _buildSectionHeader('Identity', colors),
              AppTextField(
                label: 'Full Name *',
                controller: _nameController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter your name';
                  return null;
                },
              ),
              const SizedBox(height: AppGeometry.gapNormal),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Age',
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final a = int.tryParse(val.trim());
                          if (a == null || a < 10 || a > 120) return 'Invalid age (10-120)';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppGeometry.gapNormal),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gender', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
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
                              value: _selectedGender,
                              hint: Text('Select', style: TextStyle(color: colors.textSecondary)),
                              items: ['Male', 'Female', 'Non-Binary', 'Prefer not to say']
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (val) => setState(() => _selectedGender = val),
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
                label: 'Location / City',
                controller: _locationController,
              ),
              const SizedBox(height: AppGeometry.gapLarge),

              // SECTION 2: PHYSICAL METRICS
              _buildSectionHeader('Physical Attributes', colors, subtitle: 'Self-declared stats for styling fit'),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Height (cm)',
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final h = double.tryParse(val.trim());
                          if (h == null || h < 50 || h > 280) return 'Invalid height (50-280)';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppGeometry.gapNormal),
                  Expanded(
                    child: AppTextField(
                      label: 'Weight (kg)',
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final w = double.tryParse(val.trim());
                          if (w == null || w < 20 || w > 350) return 'Invalid weight (20-350)';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppGeometry.gapNormal),
              Text('Body Type', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UserProfileModel.availableBodyTypes.map((bt) {
                  final id = bt['id']!;
                  final isSelected = _selectedBodyType == id;
                  return ChoiceChip(
                    label: Text(bt['label']!),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedBodyType = id),
                    selectedColor: colors.primarySoft,
                    labelStyle: TextStyle(color: isSelected ? colors.primary : colors.textPrimary),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppGeometry.gapLarge),

              // SECTION 3: STYLE PREFERENCES
              _buildSectionHeader('Aesthetic Styles', colors, subtitle: 'Select styles you gravitate toward'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UserProfileModel.availableStyles.map((style) {
                  final id = style['id']!;
                  final isSelected = _selectedStyles.contains(id);
                  return FilterChip(
                    label: Text(style['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedStyles.add(id);
                        } else {
                          _selectedStyles.remove(id);
                          if (_primaryStyle == id && _selectedStyles.isNotEmpty) {
                            _primaryStyle = _selectedStyles.first;
                          }
                        }
                      });
                    },
                    selectedColor: colors.primarySoft,
                    labelStyle: TextStyle(color: isSelected ? colors.primary : colors.textPrimary),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Primary Everyday Style', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: (_selectedStyles.isNotEmpty ? _selectedStyles : ['Casual']).map((s) {
                  final isPrimary = _primaryStyle == s;
                  return ChoiceChip(
                    avatar: isPrimary ? Icon(Icons.star_rounded, size: 16, color: colors.primary) : null,
                    label: Text(s),
                    selected: isPrimary,
                    onSelected: (_) => setState(() => _primaryStyle = s),
                    selectedColor: colors.primarySoft,
                    labelStyle: TextStyle(color: isPrimary ? colors.primary : colors.textPrimary),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppGeometry.gapLarge),

              // SECTION 4: FIT PREFERENCE
              _buildSectionHeader('Fit Preferences', colors, subtitle: 'Primary & secondary clothing cuts'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UserProfileModel.availableFits.map((fit) {
                  final id = fit['id']!;
                  final isSelected = _selectedFit == id;
                  return ChoiceChip(
                    label: Text(fit['label']!),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFit = id),
                    selectedColor: colors.primarySoft,
                    labelStyle: TextStyle(color: isSelected ? colors.primary : colors.textPrimary),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppGeometry.gapLarge),

              // SECTION 5: COLOR PREFERENCES
              _buildSectionHeader('Favorite Colors', colors, subtitle: 'Standard color palette'),
              _buildColorSelector(
                selectedHexes: _selectedPreferredColors,
                onToggle: (hex) {
                  setState(() {
                    _selectedPreferredColors.contains(hex)
                        ? _selectedPreferredColors.remove(hex)
                        : _selectedPreferredColors.add(hex);
                    _selectedDislikedColors.remove(hex);
                  });
                },
                colors: colors,
              ),
              const SizedBox(height: AppGeometry.gapNormal),
              _buildSectionHeader('Avoided Colors', colors),
              _buildColorSelector(
                selectedHexes: _selectedDislikedColors,
                onToggle: (hex) {
                  setState(() {
                    _selectedDislikedColors.contains(hex)
                        ? _selectedDislikedColors.remove(hex)
                        : _selectedDislikedColors.add(hex);
                    _selectedPreferredColors.remove(hex);
                  });
                },
                colors: colors,
              ),
              const SizedBox(height: AppGeometry.gapLarge),

              // SECTION 6: COMFORT VS APPEARANCE
              _buildSectionHeader('Styling Philosophy', colors),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Comfort Focus', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                  Text('${((1.0 - _comfortAppearanceScore) * 100).toInt()}% Comfort / ${(_comfortAppearanceScore * 100).toInt()}% Appearance', style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _comfortAppearanceScore,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                activeColor: colors.primary,
                onChanged: (val) => setState(() => _comfortAppearanceScore = val),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Adventurousness', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                  Text('${(_experimentationScore * 100).toInt()}%', style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _experimentationScore,
                min: 0.0,
                max: 1.0,
                divisions: 4,
                activeColor: colors.primary,
                onChanged: (val) => setState(() => _experimentationScore = val),
              ),
              const SizedBox(height: AppGeometry.gapLarge),

              // SECTION 7: OCCASIONS & LIFESTYLE
              _buildSectionHeader('Target Occasions', colors),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UserProfileModel.availableOccasions.map((occ) {
                  final id = occ['id']!;
                  final isSelected = _selectedOccasions.contains(id);
                  return FilterChip(
                    label: Text(occ['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selected ? _selectedOccasions.add(id) : _selectedOccasions.remove(id);
                      });
                    },
                    selectedColor: colors.primarySoft,
                    labelStyle: TextStyle(color: isSelected ? colors.primary : colors.textPrimary),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppGeometry.gapNormal),
              _buildSectionHeader('Budget Tier', colors),
              Wrap(
                spacing: 8,
                children: UserProfileModel.budgetTierOptions.map((tier) {
                  final isSelected = _budgetTier == tier;
                  return ChoiceChip(
                    label: Text(tier),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _budgetTier = tier),
                    selectedColor: colors.primarySoft,
                    labelStyle: TextStyle(color: isSelected ? colors.primary : colors.textPrimary),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppGeometry.gapLarge * 2),

              // SAVE BUTTON
              AppButton(
                label: 'Save Preferences',
                onPressed: _saveProfile,
              ),
              const SizedBox(height: AppGeometry.gapLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, dynamic colors, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h3.copyWith(color: colors.textPrimary, fontSize: 16)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _buildColorSelector({
    required Set<String> selectedHexes,
    required Function(String) onToggle,
    required dynamic colors,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: UserProfileModel.standardColors.map((c) {
        final hex = c['hex'] as String;
        final isSelected = selectedHexes.contains(hex);
        return GestureDetector(
          onTap: () => onToggle(hex),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Color(c['color'] as int),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? colors.primary : colors.border,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: 20,
                    color: hex == '#FFFFFF' || hex == '#E5E7EB' ? Colors.black : Colors.white,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
