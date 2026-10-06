import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/components/app_card.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/state_banners.dart';
import '../auth/auth_bloc.dart';
import '../onboarding/onboarding_view.dart';
import 'models/user_profile_model.dart';
import 'profile_bloc.dart';
import 'edit_profile_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfileRequested());
  }

  String _getInitials(String displayName) {
    if (displayName.trim().isEmpty) return 'U';
    final parts = displayName.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.substring(0, displayName.length >= 2 ? 2 : 1).toUpperCase();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out of OmniPresence?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AuthBloc>().add(LogoutRequested());
              },
              child: const Text('Log Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEdit(BuildContext context, UserProfileModel profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileView(initialProfile: profile),
      ),
    );
  }

  void _reenterOnboarding(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingView(
          onComplete: () {
            Navigator.pop(context);
            context.read<ProfileBloc>().add(LoadProfileRequested());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoaded && state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.successMessage!)),
              );
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProfileFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppGeometry.screenPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ErrorBanner(message: 'Unable to load profile: ${state.message}'),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Retry',
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: () => context.read<ProfileBloc>().add(LoadProfileRequested()),
                      ),
                    ],
                  ),
                ),
              );
            }

            final profile = (state is ProfileLoaded)
                ? state.profile
                : (state is ProfileUpdating)
                    ? state.currentProfile
                    : const UserProfileModel(displayName: 'OmniPresence User');

            final completion = profile.calculateCompletionPercentage();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppGeometry.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Bar with Edit Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Profile & Settings', style: AppTypography.h2.copyWith(color: colors.textPrimary)),
                      TextButton.icon(
                        icon: Icon(Icons.edit_outlined, size: 16, color: colors.primary),
                        label: Text('Edit', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                        onPressed: () => _navigateToEdit(context, profile),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppGeometry.gapLarge),

                  // USER IDENTITY HEADER CARD
                  AppCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: colors.primarySoft,
                          child: Text(
                            _getInitials(profile.displayName),
                            style: AppTypography.h2.copyWith(color: colors.primary),
                          ),
                        ),
                        const SizedBox(width: AppGeometry.gapLarge),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.displayName, style: AppTypography.h3.copyWith(color: colors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(profile.email ?? 'Active Session', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                              if (profile.location != null && profile.location!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: colors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(profile.location!, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppGeometry.gapNormal),

                  // DETERMINISTIC PROFILE COMPLETION INDICATOR
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Profile Completion', style: AppTypography.label.copyWith(color: colors.textPrimary)),
                            Text('$completion%', style: AppTypography.label.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: completion / 100.0,
                            minHeight: 8,
                            backgroundColor: colors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          completion >= 80 ? 'Comprehensive profile ready for AI synthesis' : 'Add style details to enhance outfit recommendations',
                          style: AppTypography.caption.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppGeometry.gapLarge),

                  // PHYSICAL ATTRIBUTES
                  _buildSectionTitle('Physical Attributes (User Declared)', colors),
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol('Height', profile.heightCm != null ? '${profile.heightCm!.toInt()} cm' : 'Not set', colors),
                        _buildMetricCol('Weight', profile.weightKg != null ? '${profile.weightKg!.toInt()} kg' : 'Not set', colors),
                        _buildMetricCol('Body Type', profile.bodyType ?? 'Average', colors),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppGeometry.gapLarge),

                  // STYLE & FIT PREFERENCES
                  _buildSectionTitle('Style & Fit Preferences', colors),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aesthetics', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                        const SizedBox(height: 6),
                        profile.stylePreferences.isNotEmpty
                            ? Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: profile.stylePreferences.map((s) => _buildChip(s, colors)).toList(),
                              )
                            : Text('None specified', style: AppTypography.body.copyWith(color: colors.textSecondary)),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Default Fit Preference', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.primarySoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(profile.fitPreference, style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppGeometry.gapLarge),

                  // COLOR PREFERENCES
                  _buildSectionTitle('Color Preferences', colors),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preferred Colors', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                        const SizedBox(height: 8),
                        profile.preferredColors.isNotEmpty
                            ? Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: profile.preferredColors.map((hex) => _buildColorChip(hex, colors)).toList(),
                              )
                            : Text('None selected', style: AppTypography.body.copyWith(color: colors.textSecondary)),
                        if (profile.dislikedColors.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text('Avoided Colors', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile.dislikedColors.map((hex) => _buildColorChip(hex, colors, isAvoided: true)).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppGeometry.gapLarge),

                  // OCCASIONS & LIFESTYLE
                  _buildSectionTitle('Occasions & Lifestyle', colors),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target Occasions', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                        const SizedBox(height: 6),
                        profile.occasions.isNotEmpty
                            ? Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: profile.occasions.map((o) => _buildChip(o, colors)).toList(),
                              )
                            : Text('Not specified', style: AppTypography.body.copyWith(color: colors.textSecondary)),
                        const SizedBox(height: 12),
                        Text('Daily Lifestyle Activities', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                        const SizedBox(height: 6),
                        profile.lifestyle.isNotEmpty
                            ? Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: profile.lifestyle.map((l) => _buildChip(l, colors)).toList(),
                              )
                            : Text('Not specified', style: AppTypography.body.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppGeometry.gapLarge),

                  // DRESSING PRIORITIES
                  _buildSectionTitle('Style & Dressing Priorities', colors),
                  AppCard(
                    child: Column(
                      children: profile.priorities.entries.map((e) {
                        final label = UserProfileModel.availablePriorityKeys
                            .firstWhere((k) => k['key'] == e.key, orElse: () => {'label': e.key})['label']!;
                        final pct = (e.value * 100).toInt();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(width: 120, child: Text(label, style: AppTypography.caption.copyWith(color: colors.textPrimary))),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: e.value,
                                    minHeight: 6,
                                    backgroundColor: colors.border,
                                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(width: 36, child: Text('$pct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textSecondary))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppGeometry.gapLarge),

                  // ACTIONS
                  _buildSectionTitle('Actions & Setup', colors),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.refresh, color: colors.primary),
                          title: Text('Re-run Style Onboarding', style: AppTypography.label.copyWith(color: colors.textPrimary)),
                          subtitle: Text('Re-answer onboarding questionnaire', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                          trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
                          onTap: () => _reenterOnboarding(context),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.logout, color: colors.error),
                          title: Text('Log Out', style: AppTypography.label.copyWith(color: colors.error)),
                          subtitle: Text('Sign out of your active session', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                          trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
                          onTap: () => _showLogoutDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppSemanticColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTypography.h3.copyWith(color: colors.textPrimary)),
    );
  }

  Widget _buildMetricCol(String label, String value, AppSemanticColors colors) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.h3.copyWith(color: colors.textPrimary)),
      ],
    );
  }

  Widget _buildChip(String label, AppSemanticColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Text(label, style: AppTypography.caption.copyWith(color: colors.textPrimary)),
    );
  }

  Widget _buildColorChip(String hex, AppSemanticColors colors, {bool isAvoided = false}) {
    final std = UserProfileModel.standardColors.firstWhere(
      (c) => c['hex'] == hex,
      orElse: () => {'name': hex, 'color': 0xFF9E9E9E},
    );
    final color = Color(std['color'] as int);
    final name = std['name'] as String;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvoided ? colors.error.withValues(alpha: 0.1) : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAvoided ? colors.error : colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400, width: 0.5),
            ),
          ),
          const SizedBox(width: 4),
          Text(name, style: TextStyle(fontSize: 11, color: isAvoided ? colors.error : colors.textPrimary)),
        ],
      ),
    );
  }
}
