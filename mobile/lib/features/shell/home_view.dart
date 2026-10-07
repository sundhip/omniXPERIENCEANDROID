import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/components/app_card.dart';
import '../auth/auth_bloc.dart';
import '../personal_ai/personal_ai_bloc.dart';
import '../personal_ai/models/personal_ai_models.dart';
import '../personal_ai/views/daily_readiness_card.dart';
import '../wardrobe/wardrobe_bloc.dart';

class HomeView extends StatelessWidget {
  final VoidCallback onExploreWardrobe;
  final VoidCallback onAskOPAI;
  final VoidCallback? onOpenProductivity;
  final VoidCallback? onOpenMoney;
  final VoidCallback? onOpenWellness;
  final VoidCallback? onOpenLearning;

  const HomeView({
    super.key,
    required this.onExploreWardrobe,
    required this.onAskOPAI,
    this.onOpenProductivity,
    this.onOpenMoney,
    this.onOpenWellness,
    this.onOpenLearning,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning,";
    } else if (hour < 17) {
      return "Good Afternoon,";
    } else {
      return "Good Evening,";
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return "$weekday, $month ${now.day}";
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppGeometry.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top greeting bar with real user data
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              String displayName = "Personal OS";
              if (authState is Authenticated) {
                displayName = authState.displayName.isNotEmpty
                    ? authState.displayName
                    : authState.email.split('@')[0];
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getGreeting(), style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                      Text(displayName, style: AppTypography.h2.copyWith(color: colors.textPrimary)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.surfaceSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.today_outlined, size: 15, color: colors.primary),
                        const SizedBox(width: 6),
                        Text(_getFormattedDate(), style: AppTypography.label.copyWith(color: colors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppGeometry.gapLarge),

          // Central Daily Readiness Layer
          BlocBuilder<PersonalAiBloc, PersonalAiState>(
            builder: (context, aiState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DailyReadinessCard(
                    brief: aiState.dailyBrief,
                    onOpenAi: onAskOPAI,
                    onRefresh: () {
                      context.read<PersonalAiBloc>().add(const LoadPersonalAiOverviewEvent());
                    },
                  ),
                  const SizedBox(height: AppGeometry.gapLarge),

                  // Proactive Intelligence Insights Section
                  if (aiState.insights.where((i) => !i.dismissed).isNotEmpty) ...[
                    Text("Proactive Insights", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
                    const SizedBox(height: AppGeometry.gapNormal),
                    ...aiState.insights.where((i) => !i.dismissed).map((insight) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppGeometry.gapNormal),
                        child: _buildProactiveInsightItem(context, insight, colors),
                      );
                    }),
                    const SizedBox(height: AppGeometry.gapNormal),
                  ],
                ],
              );
            },
          ),

          // Productivity Hub Card
          if (onOpenProductivity != null) ...[
            AppCard(
              onTap: onOpenProductivity,
              backgroundColor: colors.surfaceSoft,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.today_outlined, color: colors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's Schedule & Tasks", style: AppTypography.label.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                        const SizedBox(height: 2),
                        Text("View timeline, deadlines, and smart planning", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: colors.textMuted),
                ],
              ),
            ),
            const SizedBox(height: AppGeometry.gapNormal),
          ],

          // Money & Expenses Card
          if (onOpenMoney != null) ...[
            AppCard(
              onTap: onOpenMoney,
              backgroundColor: colors.surfaceSoft,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Money & Expenses", style: AppTypography.label.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                        const SizedBox(height: 2),
                        Text("Spending tracking, budgets & analytics", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: colors.textMuted),
                ],
              ),
            ),
            const SizedBox(height: AppGeometry.gapNormal),
          ],

          // Wellness & Habits Card
          if (onOpenWellness != null) ...[
            AppCard(
              onTap: onOpenWellness,
              backgroundColor: colors.surfaceSoft,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.spa_outlined, color: Colors.purple, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Wellness & Routines", style: AppTypography.label.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                        const SizedBox(height: 2),
                        Text("Skincare steps, habits & truthful streaks", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: colors.textMuted),
                ],
              ),
            ),
            const SizedBox(height: AppGeometry.gapNormal),
          ],

          // Learn & Goals Card
          if (onOpenLearning != null) ...[
            AppCard(
              onTap: onOpenLearning,
              backgroundColor: colors.surfaceSoft,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_outlined, color: Colors.indigo, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Learn & Goals", style: AppTypography.label.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                        const SizedBox(height: 2),
                        Text("Subjects, goals, milestones & AI planning", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: colors.textMuted),
                ],
              ),
            ),
            const SizedBox(height: AppGeometry.gapLarge),
          ],

          // Quick Action Cards
          Text("Quick Actions", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
          const SizedBox(height: AppGeometry.gapNormal),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  onTap: onAskOPAI,
                  backgroundColor: colors.surfaceSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, color: colors.primary, size: 24),
                      const SizedBox(height: 8),
                      Text("Ask Personal AI", style: AppTypography.label.copyWith(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                      Text("Cross-domain assistance", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppGeometry.gapNormal),
              Expanded(
                child: AppCard(
                  onTap: onExploreWardrobe,
                  backgroundColor: colors.surfaceSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: colors.primary, size: 24),
                      const SizedBox(height: 8),
                      Text("Add Wardrobe Item", style: AppTypography.label.copyWith(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                      Text("Camera or Gallery", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppGeometry.gapLarge),

          // Wardrobe Overview reading real live data
          Text("Wardrobe Overview", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
          const SizedBox(height: AppGeometry.gapNormal),
          BlocBuilder<WardrobeBloc, WardrobeState>(
            builder: (context, wardrobeState) {
              int totalItems = 0;
              int favoriteItems = 0;
              int wornItems = 0;

              if (wardrobeState is WardrobeLoaded) {
                totalItems = wardrobeState.allItems.length;
                favoriteItems = wardrobeState.allItems.where((i) => i.favorite).length;
                wornItems = wardrobeState.allItems.where((i) => i.wearCount > 0).length;
              }

              return AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Items", totalItems.toString(), colors),
                    Container(height: 30, width: 1, color: colors.border),
                    _buildStatItem("Favorites", favoriteItems.toString(), colors),
                    Container(height: 30, width: 1, color: colors.border),
                    _buildStatItem("Worn", wornItems.toString(), colors),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProactiveInsightItem(
    BuildContext context,
    ProactiveInsightModel insight,
    AppSemanticColors colors,
  ) {
    Color badgeColor = colors.primary;
    if (insight.severity == 'urgent') {
      badgeColor = colors.error;
    } else if (insight.severity == 'warning') {
      badgeColor = colors.warning;
    }

    return AppCard(
      backgroundColor: colors.surface,
      border: Border.all(color: badgeColor.withOpacity(0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      insight.severity.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    insight.title,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, size: 16, color: colors.textMuted),
                onPressed: () {
                  context.read<PersonalAiBloc>().add(DismissInsightEvent(insight.id));
                },
                tooltip: "Dismiss",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            insight.explanation,
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          if (insight.recommendedAction != null && insight.recommendedAction!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 14, color: colors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      insight.recommendedAction!,
                      style: AppTypography.caption.copyWith(color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, AppSemanticColors colors) {
    return Column(
      children: [
        Text(value, style: AppTypography.h2.copyWith(color: colors.textPrimary)),
        Text(label, style: AppTypography.caption.copyWith(color: colors.textMuted)),
      ],
    );
  }
}
