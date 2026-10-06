import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../core/storage/secure_storage.dart';
import '../../shared/components/app_card.dart';
import '../auth/auth_bloc.dart';
import '../onboarding/onboarding_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _aiPersonalization = true;
  String _displayName = 'User';
  String _email = 'user@omnipresence.ai';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final name = await SecureStorage.getDisplayName();
    final email = await SecureStorage.getUserEmail();
    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) _displayName = name;
        if (email != null && email.isNotEmpty) _email = email;
      });
    }
  }

  String get _initials {
    if (_displayName.trim().isEmpty) return 'U';
    final parts = _displayName.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _displayName.substring(0, _displayName.length >= 2 ? 2 : 1).toUpperCase();
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

  void _reenterOnboarding(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingView(
          onComplete: () {
            Navigator.pop(context);
            _loadProfileData();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppGeometry.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile & Settings', style: AppTypography.h2.copyWith(color: colors.textPrimary)),
              const SizedBox(height: AppGeometry.gapLarge),
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: colors.primarySoft,
                      child: Text(_initials, style: AppTypography.h3.copyWith(color: colors.primary)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_displayName, style: AppTypography.h3.copyWith(color: colors.textPrimary)),
                          Text(_email, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Style: Minimal • Smart Casual', style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppGeometry.gapLarge),
              Text('Preferences & Setup', style: AppTypography.h3.copyWith(color: colors.textPrimary)),
              const SizedBox(height: AppGeometry.gapNormal),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingsTile(
                      Icons.refresh_outlined,
                      "Re-run Style Onboarding",
                      "Update aesthetics and dressing goals",
                      colors,
                      onTap: () => _reenterOnboarding(context),
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      Icons.palette_outlined,
                      "Appearance",
                      "System Default",
                      colors,
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      Icons.calendar_month_outlined,
                      "Connected Accounts",
                      "Google Calendar (Active)",
                      colors,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text("OP AI Personalization", style: AppTypography.label.copyWith(color: colors.textPrimary)),
                      subtitle: Text("Use preferences to tune recommendations", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                      value: _aiPersonalization,
                      activeTrackColor: colors.primarySoft,
                      activeThumbColor: colors.primary,
                      onChanged: (v) => setState(() => _aiPersonalization = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppGeometry.gapLarge),
              Text('Account', style: AppTypography.h3.copyWith(color: colors.textPrimary)),
              const SizedBox(height: AppGeometry.gapNormal),
              AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Sign out of your active session'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLogoutDialog(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    AppSemanticColors colors, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: colors.textSecondary),
      title: Text(title, style: AppTypography.label.copyWith(color: colors.textPrimary)),
      subtitle: Text(subtitle, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: colors.textMuted),
      onTap: onTap ?? () {},
    );
  }
}
