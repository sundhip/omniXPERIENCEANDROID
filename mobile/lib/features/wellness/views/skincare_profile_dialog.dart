import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/database/app_database.dart';

class SkincareProfileDialog extends StatefulWidget {
  final SkincareProfileModel? initialProfile;
  final Function(Map<String, dynamic> data) onSave;

  const SkincareProfileDialog({
    super.key,
    this.initialProfile,
    required this.onSave,
  });

  @override
  State<SkincareProfileDialog> createState() => _SkincareProfileDialogState();
}

class _SkincareProfileDialogState extends State<SkincareProfileDialog> {
  late String _skinType;
  late String _sensitivity;
  late String _frequency;
  late List<String> _selectedConcerns;

  final List<String> _skinTypes = ['Normal', 'Dry', 'Oily', 'Combination', 'Sensitive'];
  final List<String> _allConcerns = [
    'Acne', 'Hyperpigmentation', 'Dryness', 'Dullness', 'Aging', 'Texture', 'Sun Protection'
  ];
  final List<String> _sensitivities = ['Low', 'Normal', 'High'];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _skinType = p?.skinType ?? 'Combination';
    _sensitivity = p?.sensitivityLevel ?? 'Normal';
    _frequency = p?.routineFrequency ?? 'Twice daily';
    _selectedConcerns = List<String>.from(p?.skinConcerns ?? ['Hydration', 'Sun Protection']);
  }

  void _submit() {
    final data = <String, dynamic>{
      'skin_type': _skinType,
      'skin_concerns': _selectedConcerns,
      'sensitivity_level': _sensitivity,
      'routine_frequency': _frequency,
    };
    widget.onSave(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colors.surface,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Skincare Profile',
                    style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Personalized routine tracking based on your skin type and goals.',
                style: AppTypography.caption.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Skin Type
              Text('Skin Type', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skinTypes.map((st) {
                  final isSelected = _skinType == st;
                  return ChoiceChip(
                    label: Text(st),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _skinType = st),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Skin Concerns
              Text('Focus Areas / Concerns', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allConcerns.map((c) {
                  final isSelected = _selectedConcerns.contains(c);
                  return FilterChip(
                    label: Text(c),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedConcerns.add(c);
                        } else {
                          _selectedConcerns.remove(c);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Sensitivity Level
              Text('Sensitivity Level', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _sensitivities.map((s) {
                  final isSelected = _sensitivity == s;
                  return ChoiceChip(
                    label: Text(s),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _sensitivity = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
