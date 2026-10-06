import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/components/app_card.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _aiPersonalization = true;

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
                      child: Text('AC', style: AppTypography.h3.copyWith(color: colors.primary)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alex Chen', style: AppTypography.h3.copyWith(color: colors.textPrimary)),
                        Text('alex.chen@omnipresence.ai', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Style: Minimal ? Smart Casual', style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppGeometry.gapLarge),
              Text('Settings', style: AppTypography.h3.copyWith(color: colors.textPrimary)),
              const SizedBox(height: AppGeometry.gapNormal),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingsTile(Icons.palette_outlined, "Appearance", "System Default", colors),
                    const Divider(height: 1),
                    _buildSettingsTile(Icons.style_outlined, "Style Preferences", "Minimal, Casual", colors),
                    const Divider(height: 1),
                    _buildSettingsTile(Icons.calendar_month_outlined, "Connected Accounts", "Google Calendar (Active)", colors),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text("? OP AI Personalization", style: AppTypography.label.copyWith(color: colors.textPrimary)),
                      subtitle: Text("Use preferences to tune recommendations", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                      value: _aiPersonalization,
                      activeTrackColor: colors.primarySoft, activeThumbColor: colors.primary,
                      onChanged: (v) => setState(() => _aiPersonalization = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, AppSemanticColors colors) {
    return ListTile(
      leading: Icon(icon, color: colors.textSecondary),
      title: Text(title, style: AppTypography.label.copyWith(color: colors.textPrimary)),
      subtitle: Text(subtitle, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: colors.textMuted),
      onTap: () {},
    );
  }
}
