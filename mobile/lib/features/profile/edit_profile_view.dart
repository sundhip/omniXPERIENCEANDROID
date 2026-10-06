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
  late String _selectedFit;
  late Set<String> _selectedPreferredColors;
  late Set<String> _selectedDislikedColors;
  late Set<String> _selectedOccasions;
  late Set<String> _selectedLifestyle;
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
    _selectedFit = p.fitPreference.isNotEmpty ? p.fitPreference : 'Regular';
    _selectedPreferredColors = Set<String>.from(p.preferredColors);
    _selectedDislikedColors = Set<String>.from(p.dislikedColors);
    _selectedOccasions = Set<String>.from(p.occasions);
    _selectedLifestyle = Set<String>.from(p.lifestyle);
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
      fitPreference: _selectedFit,
      preferredColors: _selectedPreferredColors.toList(),
      dislikedColors: _selectedDislikedColors.toList(),
      occasions: _selectedOccasions.toList(),
      lifestyle: _selectedLifestyle.toList(),
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
        title: Text('Edit Profile', style: AppTypography.h3.copyWith(color: colors.textPrimary)),
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
                hint: 'e.g. San Francisco, CA',
              ),
              const SizedBox(height: AppGeometry.gapLarge),

              // SECTION 2: PHYSICAL PROFILE (User declared)
              _buildSectionHeader('Physical Profile', colors, subtitle: 'User-declared dimensions for tailoring & fit'),
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
                          if (h == null || h < 50 || h > 250) return '50 - 250 cm';
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
                          if (w == null || w < 20 || w > 300) return '20 - 300 kg';
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
                  final isSelected = _selectedBodyType == bt['id'];
                  return ChoiceChip(
                    label: Text(bt['label']!),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedBodyType = bt['id']),
                    selectedColor: colors.primarySoft,
                    labelStyle: TextStyle(color: isSelected ? colors.primary : colors.textPrimary),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppGeometry.gapLarge),

              // SECTION 3: STYLE PROFILE
              _buildSectionHeader('Style Preferences', colors, subtitle: 'Select all aesthetics that resonate with you'),
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
                        }
                      });
                    },
                    selectedColor: colors.primarySoft,
                    labelStyle: TextStyle(color: isSelected ? colors.primary : colors.textPrimary),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppGeometry.gapLarge),

              // SECTION 4: FIT PREFERENCE
              _buildSectionHeader('Fit Preference', colors, subtitle: 'Your default clothing fit'),
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
              _buildSectionHeader('Favorite & Preferred Colors', colors, subtitle: 'Standard color palette'),
              _buildColorSelector(
                selectedHexes: _selectedPreferredColors,
                onToggle: (hex) {
                  setState(() {
                    if (_selectedPreferredColors.contains(hex)) {
                      _selectedPreferredColors.remove(hex);
                    } else {
                      _selectedPreferredColors.add(hex);
                      _selectedDislikedColors.remove(hex);
                    }
                  });
                },
                colors: colors,
              ),
              const SizedBox(height: AppGeometry.gapNormal),
              _buildSectionHeader('Colors You Avoid / Dislike', colors),
              _buildColorSelector(
                selectedHexes: _selectedDislikedColors,
                onToggle: (hex) {
                  setState(() {
                    if (_selectedDislikedColors.contains(hex)) {
                      _selectedDislikedColors.remove(hex);
                    } else {
                      _selectedDislikedColors.add(hex);
                      _selectedPreferredColors.remove(hex);
                    }
                  });
                },
                colors: colors,
              ),
              const SizedBox(height: AppGeometry.gapLarge),

              // SECTION 6: OCCASIONS & LIFESTYLE
              _buildSectionHeader('Occasions', colors, subtitle: 'What settings do you usually dress for?'),
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
              const SizedBox(height: AppGeometry.gapNormal),
              _buildSectionHeader('Lifestyle Activities', colors),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UserProfileModel.availableLifestyle.map((act) {
                  final id = act['id']!;
                  final isSelected = _selectedLifestyle.contains(id);
                  return FilterChip(
                    label: Text(act['label']!),
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
              const SizedBox(height: AppGeometry.gapLarge),

              // SECTION 7: PRIORITIES
              _buildSectionHeader('Style & Dressing Priorities', colors, subtitle: 'Fine-tune what matters most'),
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
                        Text('${(value * 100).toInt()}%', style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: AppGeometry.gapLarge),

              // SAVE BUTTON
              AppButton(
                label: 'Save Changes',
                icon: const Icon(Icons.check, size: 18),
                onPressed: _saveProfile,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppSemanticColors colors, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h3.copyWith(color: colors.textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
          ],
          const SizedBox(height: 8),
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
      spacing: 10,
      runSpacing: 10,
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
                  width: 16,
                  height: 16,
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
