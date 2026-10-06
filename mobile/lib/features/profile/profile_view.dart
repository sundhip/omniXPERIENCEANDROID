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
            if (state is ProfileLoading && state is! ProfileLoaded) {
              return Center(
                child: CircularProgressIndicator(color: colors.primary),
              );
            }

            if (state is ProfileFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ErrorState(
                    message: state.message,
                    onRetry: () => context.read<ProfileBloc>().add(LoadProfileRequested()),
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
            final summaryText = profile.generateDeterministicSummary();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ProfileBloc>().add(LoadProfileRequested());
              },
              color: colors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppGeometry.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PROFILE HEADER
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: colors.primary,
                          child: Text(
                            _getInitials(profile.displayName),
                            style: AppTypography.h1.copyWith(color: Colors.white, fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: AppGeometry.gapNormal),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.displayName.isNotEmpty ? profile.displayName : 'OmniPresence User',
                                style: AppTypography.h2,
                              ),
                              if (profile.email != null && profile.email!.isNotEmpty)
                                Text(
                                  profile.email!,
                                  style: AppTypography.caption.copyWith(color: colors.textSecondary),
                                ),
                              if (profile.location != null && profile.location!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: colors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      profile.location!,
                                      style: AppTypography.caption.copyWith(color: colors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.logout_rounded, color: colors.textSecondary),
                          tooltip: 'Log Out',
                          onPressed: () => _showLogoutDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppGeometry.gapLarge),

                    // COMPLETION BAR
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Personalization Completeness', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
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
                            completion >= 90
                                ? 'Full style profile complete & ready for Phase 3 Face AI'
                                : 'Complete remaining preferences to sharpen personalization',
                            style: AppTypography.caption.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppGeometry.gapLarge),

                    // PERSONAL STYLE PROFILE HERO CARD
                    _buildSectionTitle('Personal Style Profile (Deterministic)', colors),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.primary.withValues(alpha: 0.12), colors.surfaceSoft],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: colors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text("Style Synthesis", style: AppTypography.label.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "\"$summaryText\"",
                            style: AppTypography.body.copyWith(fontStyle: FontStyle.italic, height: 1.4),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMiniBadge("Primary Style", profile.primaryStyle, colors, isHighlight: true),
                              _buildMiniBadge("Primary Fit", profile.primaryFit, colors),
                              _buildMiniBadge("Comfort Focus", "${((1.0 - profile.comfortAppearanceScore) * 100).toInt()}%", colors),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppGeometry.gapLarge),

                    // STYLE & FIT DETAILS
                    _buildSectionTitle('Aesthetics & Fits', colors),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Primary Everyday Style', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                          const SizedBox(height: 6),
                          _buildChip(profile.primaryStyle, colors, isStar: true),
                          if (profile.secondaryStyles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('Secondary Styles', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: profile.secondaryStyles.map((s) => _buildChip(s, colors)).toList(),
                            ),
                          ],
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Primary Fit', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(profile.primaryFit, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              if (profile.secondaryFit != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Secondary Fit', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Text(profile.secondaryFit!, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                                  ],
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
                          if (profile.neutralColors.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('Neutral Staples', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.neutralColors.map((hex) => _buildColorChip(hex, colors)).toList(),
                            ),
                          ],
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
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Color Openness', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                              Text('${(profile.colorExperimentationScore * 100).toInt()}%', style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppGeometry.gapLarge),

                    // OCCASIONS & LIFESTYLE
                    _buildSectionTitle('Occasions & Routines', colors),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profile.topOccasions.isNotEmpty) ...[
                            Text('Top Dress-Up Occasions', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: profile.topOccasions.map((o) => _buildChip(o, colors, isStar: true)).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text('All Target Occasions', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                          const SizedBox(height: 6),
                          profile.occasions.isNotEmpty
                              ? Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: profile.occasions.map((o) => _buildChip(o, colors)).toList(),
                                )
                              : Text('Not specified', style: AppTypography.body.copyWith(color: colors.textSecondary)),
                          const SizedBox(height: 12),
                          Text('Weekly Activities', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
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

                    // FASHION PRIORITIES RANKING
                    _buildSectionTitle('Fashion Priorities (Ranked Weights)', colors),
                    AppCard(
                      child: Column(
                        children: profile.fashionPrioritiesRanked.map((key) {
                          final label = UserProfileModel.standardRankedPriorities.firstWhere(
                            (p) => p['key'] == key,
                            orElse: () => {'key': key, 'label': key},
                          )['label']!;
                          final weight = profile.fashionPriorityWeights[key] ?? 0.8;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(width: 140, child: Text(label, style: AppTypography.caption.copyWith(color: colors.textPrimary))),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: weight,
                                      minHeight: 6,
                                      backgroundColor: colors.border,
                                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('${(weight * 100).toInt()}%', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                              ],
                            ),
                          );
                        }).toList(),
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

                    // BRANDS & BUDGET
                    _buildSectionTitle('Brands & Budget', colors),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Budget Tier', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                              Text(profile.budgetTier, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: colors.primary)),
                            ],
                          ),
                          if (profile.preferredBrands.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text('Preferred Brands', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: profile.preferredBrands.map((b) => _buildChip(b, colors)).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppGeometry.gapLarge),

                    // ACTION BUTTONS
                    AppButton(
                      label: 'Edit Preferences',
                      onPressed: () => _navigateToEdit(context, profile),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Re-take Style Assessment'),
                        onPressed: () => _reenterOnboarding(context),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String title, String val, dynamic colors, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isHighlight ? colors.primary.withValues(alpha: 0.2) : colors.surfaceSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isHighlight ? colors.primary : colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: AppTypography.label.copyWith(color: colors.textSecondary, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, dynamic colors) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.h3.copyWith(color: colors.textPrimary, fontSize: 16)),
      ],
    );
  }

  Widget _buildChip(String text, dynamic colors, {bool isStar = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isStar ? colors.primary.withValues(alpha: 0.15) : colors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isStar ? colors.primary.withValues(alpha: 0.4) : colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isStar) ...[
            Icon(Icons.star_rounded, size: 14, color: colors.primary),
            const SizedBox(width: 4),
          ],
          Text(text, style: TextStyle(color: isStar ? colors.primary : colors.textPrimary, fontSize: 12, fontWeight: isStar ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildColorChip(String hex, dynamic colors, {bool isAvoided = false}) {
    Color parsedColor;
    try {
      parsedColor = Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      parsedColor = Colors.grey;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: parsedColor,
        shape: BoxShape.circle,
        border: Border.all(color: isAvoided ? Colors.red : colors.border, width: isAvoided ? 2 : 1),
      ),
      child: isAvoided ? const Icon(Icons.close, size: 16, color: Colors.red) : null,
    );
  }
}
