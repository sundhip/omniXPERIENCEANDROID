import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/components/app_card.dart';
import '../../shared/components/app_button.dart';
import 'models/visual_profile_model.dart';
import 'profile_bloc.dart';
import 'visual_profile_bloc.dart';

class VisualProfileView extends StatefulWidget {
  const VisualProfileView({super.key});

  @override
  State<VisualProfileView> createState() => _VisualProfileViewState();
}

class _VisualProfileViewState extends State<VisualProfileView> {
  final ImagePicker _picker = ImagePicker();
  String? _pickedImagePath;

  // Review Overrides
  String? _selectedFaceShape;
  String? _selectedSkinTone;
  String? _selectedUndertone;
  String? _selectedHairType;

  @override
  void initState() {
    super.initState();
    context.read<VisualProfileBloc>().add(LoadVisualProfileEvent());
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (picked != null) {
        setState(() {
          _pickedImagePath = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _startAnalysis() {
    if (_pickedImagePath != null) {
      context.read<VisualProfileBloc>().add(
            AnalyzeVisualProfileEvent(imagePath: _pickedImagePath!),
          );
    }
  }

  void _confirmAnalysis(VisualProfileModel analyzed) {
    context.read<VisualProfileBloc>().add(
          ConfirmVisualProfileEvent(
            faceShape: _selectedFaceShape ?? analyzed.detectedFaceShape,
            skinTone: _selectedSkinTone ?? analyzed.detectedSkinTone,
            undertone: _selectedUndertone ?? analyzed.detectedUndertone,
            hairType: _selectedHairType ?? analyzed.detectedHairType,
          ),
        );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Visual Profile?'),
        content: const Text(
          'This will permanently delete your facial analysis and encrypted photo from your private profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VisualProfileBloc>().add(DeleteVisualProfileEvent());
              context.read<ProfileBloc>().add(LoadProfileRequested());
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
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
        title: const Text('Visual Profile & Appearance AI'),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocConsumer<VisualProfileBloc, VisualProfileState>(
          listener: (context, state) {
            if (state is VisualProfileReviewing) {
              // Pre-fill override dropdowns with detected values
              setState(() {
                _selectedFaceShape = state.analyzedProfile.detectedFaceShape;
                _selectedSkinTone = state.analyzedProfile.detectedSkinTone;
                _selectedUndertone = state.analyzedProfile.detectedUndertone;
                _selectedHairType = state.analyzedProfile.detectedHairType;
              });
            }
            if (state is VisualProfileLoaded && state.statusMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.statusMessage!)),
              );
              // Also refresh main profile to sync visual profile badge
              context.read<ProfileBloc>().add(LoadProfileRequested());
            }
          },
          builder: (context, state) {
            if (state is VisualProfileLoading) {
              return Center(
                child: CircularProgressIndicator(color: colors.primary),
              );
            }

            if (state is VisualProfileAnalyzing) {
              return _buildAnalyzingView(state, colors);
            }

            if (state is VisualProfileReviewing) {
              return _buildReviewingView(state, colors);
            }

            if (state is VisualProfileLoaded) {
              return _buildLoadedView(state.profile, colors);
            }

            // VisualProfileInitial or VisualProfileFailure
            return _buildCaptureOrPromptView(
              errorMessage: state is VisualProfileFailure ? state.message : null,
              colors: colors,
            );
          },
        ),
      ),
    );
  }

  // 1. CAPTURE / GUIDANCE VIEW
  Widget _buildCaptureOrPromptView({String? errorMessage, required dynamic colors}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppGeometry.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Privacy Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppGeometry.radiusSmall),
              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: colors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Privacy First: Biometric landmarks are computed ephemerally in RAM and permanently discarded. Images are stored encrypted in your private profile.',
                    style: AppTypography.caption.copyWith(color: colors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppGeometry.gapLarge),

          if (errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppGeometry.radiusSmall),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: AppTypography.caption.copyWith(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppGeometry.gapLarge),
          ],

          // Guidance Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: colors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Capture Guidance for Best AI Accuracy',
                      style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: AppGeometry.gapNormal),
                _buildGuidanceItem(
                  icon: Icons.wb_sunny_outlined,
                  text: 'Natural, even lighting (avoid backlighting or heavy shadows)',
                  colors: colors,
                ),
                _buildGuidanceItem(
                  icon: Icons.face_outlined,
                  text: 'Face the camera directly at eye level with a neutral expression',
                  colors: colors,
                ),
                _buildGuidanceItem(
                  icon: Icons.person_outline,
                  text: 'Exactly 1 person in the photo (no group selfies or bystanders)',
                  colors: colors,
                ),
                _buildGuidanceItem(
                  icon: Icons.visibility_outlined,
                  text: 'Keep forehead, jawline, and cheeks uncovered',
                  colors: colors,
                ),
                _buildGuidanceItem(
                  icon: Icons.camera_alt_outlined,
                  text: 'Sharp focus (avoid blurry, fast motion, or low-resolution images)',
                  colors: colors,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppGeometry.gapLarge),

          // Picked Image Preview if any
          if (_pickedImagePath != null) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: colors.surfaceSoft,
                    border: Border.all(color: colors.primary, width: 2),
                  ),
                  child: Image.file(
                    File(_pickedImagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppGeometry.gapNormal),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Change Photo',
                    onPressed: () => setState(() => _pickedImagePath = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Analyze Photo',
                    icon: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                    onPressed: _startAnalysis,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Capture Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Take Selfie',
                    icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SecondaryButton(
                    label: 'From Gallery',
                    icon: Icon(Icons.photo_library, size: 18, color: colors.primary),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuidanceItem({
    required IconData icon,
    required String text,
    required dynamic colors,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
          ),
        ],
      ),
    );
  }

  // 2. ANALYZING IN-PROGRESS VIEW
  Widget _buildAnalyzingView(VisualProfileAnalyzing state, dynamic colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
              child: SizedBox(
                width: 140,
                height: 140,
                child: Image.file(
                  File(state.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 20),
            const Text(
              'Running Face & Visual AI',
              style: AppTypography.h3,
            ),
            const SizedBox(height: 8),
            Text(
              state.stageMessage,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              '• MediaPipe BlazeFace detection\n• 478 Landmark 3D geometry\n• CIELAB / ITA° skin tone science\n• Gradient frequency hair texture',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: colors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // 3. REVIEWING / EDITING DETECTED RESULTS VIEW
  Widget _buildReviewingView(VisualProfileReviewing state, dynamic colors) {
    final analyzed = state.analyzedProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppGeometry.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text('Review Detected Features', style: AppTypography.h2),
          const SizedBox(height: 4),
          Text(
            'Confirm the computer vision readings or adjust manually to refine future outfit & neckline recommendations.',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppGeometry.gapNormal),

          // Photo & Proportions Card
          AppCard(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppGeometry.radiusSmall),
                  child: SizedBox(
                    width: 90,
                    height: 110,
                    child: Image.file(
                      File(state.localImagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text('Quality Passed', style: AppTypography.caption.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('1 Face Detected', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (analyzed.faceProportions.isNotEmpty) ...[
                        Text(
                          'L/W: ${analyzed.faceProportions['length_to_width']?.toStringAsFixed(2) ?? '1.30'} • Jaw/Forehead: ${analyzed.faceProportions['jaw_to_forehead']?.toStringAsFixed(2) ?? '0.85'}',
                          style: AppTypography.caption.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppGeometry.gapLarge),

          // Face Shape Field
          _buildReviewCard(
            title: 'Face Shape',
            detectedValue: analyzed.detectedFaceShape,
            confidence: analyzed.faceShapeConfidence,
            currentValue: _selectedFaceShape ?? analyzed.detectedFaceShape,
            options: VisualProfileModel.availableFaceShapes,
            onChanged: (val) => setState(() => _selectedFaceShape = val),
            colors: colors,
            icon: Icons.face_retouching_natural,
          ),
          const SizedBox(height: AppGeometry.gapNormal),

          // Skin Tone Field
          _buildReviewCard(
            title: 'Skin Tone',
            detectedValue: analyzed.detectedSkinTone,
            confidence: analyzed.skinToneConfidence,
            currentValue: _selectedSkinTone ?? analyzed.detectedSkinTone,
            options: VisualProfileModel.availableSkinTones,
            onChanged: (val) => setState(() => _selectedSkinTone = val),
            colors: colors,
            icon: Icons.palette_outlined,
            colorSwatch: analyzed.skinToneColor,
            extraSubtitle: analyzed.skinItaAngle != null
                ? 'Hex: ${analyzed.skinToneHex ?? 'N/A'} • ITA: ${analyzed.skinItaAngle!.toStringAsFixed(1)}°'
                : null,
          ),
          const SizedBox(height: AppGeometry.gapNormal),

          // Undertone Field
          _buildReviewCard(
            title: 'Undertone',
            detectedValue: analyzed.detectedUndertone,
            confidence: 0.85,
            currentValue: _selectedUndertone ?? analyzed.detectedUndertone,
            options: VisualProfileModel.availableUndertones,
            onChanged: (val) => setState(() => _selectedUndertone = val),
            colors: colors,
            icon: Icons.gradient,
          ),
          const SizedBox(height: AppGeometry.gapNormal),

          // Hair Texture Field
          _buildReviewCard(
            title: 'Hair Texture',
            detectedValue: analyzed.detectedHairType,
            confidence: analyzed.hairConfidence,
            currentValue: _selectedHairType ?? analyzed.detectedHairType,
            options: VisualProfileModel.availableHairTypes,
            onChanged: (val) => setState(() => _selectedHairType = val),
            colors: colors,
            icon: Icons.waves,
          ),
          const SizedBox(height: AppGeometry.gapLarge),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Retake',
                  onPressed: () {
                    context.read<VisualProfileBloc>().add(ResetVisualProfileEvent());
                    setState(() => _pickedImagePath = null);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Confirm & Save',
                  icon: const Icon(Icons.check, size: 18, color: Colors.white),
                  onPressed: () => _confirmAnalysis(analyzed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required String detectedValue,
    required double confidence,
    required String currentValue,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required dynamic colors,
    required IconData icon,
    Color? colorSwatch,
    String? extraSubtitle,
  }) {
    final confPct = (confidence * 100).round();
    final bool isEdited = currentValue != detectedValue;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(title, style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$confPct% confidence',
                  style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (colorSwatch != null) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorSwatch,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border, width: 1.5),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text('Detected: $detectedValue', style: AppTypography.body.copyWith(fontSize: 13)),
              if (isEdited) ...[
                const SizedBox(width: 6),
                Text('(Adjusted)', style: AppTypography.caption.copyWith(color: colors.primary, fontStyle: FontStyle.italic)),
              ],
            ],
          ),
          if (extraSubtitle != null) ...[
            const SizedBox(height: 2),
            Text(extraSubtitle, style: AppTypography.caption.copyWith(color: colors.textSecondary, fontSize: 11)),
          ],
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: options.contains(currentValue) ? currentValue : options.first,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: options.map((opt) {
              return DropdownMenuItem(value: opt, child: Text(opt));
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // 4. CONFIRMED VISUAL PROFILE VIEW
  Widget _buildLoadedView(VisualProfileModel profile, dynamic colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppGeometry.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verified Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary.withValues(alpha: 0.15), colors.surfaceSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified, color: colors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visual Intelligence Active',
                        style: AppTypography.label.copyWith(color: colors.primary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.visualSummary,
                        style: AppTypography.caption.copyWith(color: colors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppGeometry.gapLarge),

          // Visual Details Grid
          const Text('Appearance Geometry & Colorimetry', style: AppTypography.h3),
          const SizedBox(height: AppGeometry.gapNormal),

          // Face Shape Card
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.face_retouching_natural, color: colors.primary),
              ),
              title: Text('Face Shape: ${profile.displayFaceShape}', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Confidence: ${(profile.faceShapeConfidence * 100).round()}% • Length/Width: ${profile.faceProportions['length_to_width']?.toStringAsFixed(2) ?? '1.30'}',
                style: AppTypography.caption.copyWith(color: colors.textSecondary),
              ),
              trailing: profile.confirmedFaceShape != null
                  ? Chip(label: const Text('Confirmed', style: TextStyle(fontSize: 10)), backgroundColor: colors.surfaceSoft)
                  : null,
            ),
          ),
          const SizedBox(height: AppGeometry.gapNormal),

          // Skin Tone Card
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: profile.skinToneColor ?? Colors.amber,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border, width: 2),
                ),
              ),
              title: Text('Skin Tone: ${profile.displaySkinTone}', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Undertone: ${profile.displayUndertone}${profile.skinItaAngle != null ? ' • ITA: ${profile.skinItaAngle!.toStringAsFixed(1)}°' : ''}',
                style: AppTypography.caption.copyWith(color: colors.textSecondary),
              ),
              trailing: profile.skinToneHex != null
                  ? Text(profile.skinToneHex!, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold))
                  : null,
            ),
          ),
          const SizedBox(height: AppGeometry.gapNormal),

          // Hair Texture Card
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.waves, color: colors.primary),
              ),
              title: Text('Hair Texture: ${profile.displayHairType}', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Texture Confidence: ${(profile.hairConfidence * 100).round()}%',
                style: AppTypography.caption.copyWith(color: colors.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: AppGeometry.gapLarge),

          // Actions
          SecondaryButton(
            label: 'Retake Photo & Analysis',
            icon: Icon(Icons.refresh, size: 18, color: colors.primary),
            onPressed: () {
              context.read<VisualProfileBloc>().add(ResetVisualProfileEvent());
              setState(() => _pickedImagePath = null);
            },
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Delete Visual Profile',
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => _showDeleteDialog(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
