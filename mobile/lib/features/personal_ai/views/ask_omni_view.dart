import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_geometry.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/components/app_card.dart';
import '../models/personal_ai_models.dart';
import '../personal_ai_bloc.dart';

class AskOmniView extends StatefulWidget {
  const AskOmniView({super.key});

  @override
  State<AskOmniView> createState() => _AskOmniViewState();
}

class _AskOmniViewState extends State<AskOmniView> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickPrompts = [
    "What should I focus on tomorrow?",
    "Plan my tomorrow.",
    "What should I wear tomorrow?",
    "Am I overspending?",
    "Remind me to study DSA tonight",
  ];

  @override
  void initState() {
    super.initState();
    context.read<PersonalAiBloc>().add(const LoadPersonalAiOverviewEvent());
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitPrompt(String prompt) {
    final clean = prompt.trim();
    if (clean.isEmpty) return;
    _promptController.clear();
    context.read<PersonalAiBloc>().add(AskAssistantEvent(clean));
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, color: colors.primary, size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ask OmniXPERIENCE", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
                Text("Context-Aware Personal AI", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
              ],
            ),
          ],
        ),
        backgroundColor: colors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: colors.textMuted),
            tooltip: "Clear Chat",
            onPressed: () => context.read<PersonalAiBloc>().add(const ClearChatEvent()),
          ),
        ],
      ),
      body: BlocConsumer<PersonalAiBloc, PersonalAiState>(
        listener: (context, state) {
          if (state.actionFeedback != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.actionFeedback!), backgroundColor: colors.success),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: colors.error),
            );
          }
          _scrollToBottom();
        },
        builder: (context, state) {
          final messages = state.messages;

          return Column(
            children: [
              // Message list
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState(colors)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppGeometry.screenPadding),
                        itemCount: messages.length + (state.isAsking ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length && state.isAsking) {
                            return _buildThinkingIndicator(colors);
                          }
                          final msg = messages[index];
                          return _buildMessageItem(msg, colors);
                        },
                      ),
              ),

              // Quick prompts chips
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickPrompts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final p = _quickPrompts[idx];
                    return ActionChip(
                      label: Text(p, style: AppTypography.caption.copyWith(color: colors.textPrimary)),
                      backgroundColor: colors.surfaceSoft,
                      side: BorderSide(color: colors.border),
                      onPressed: () => _submitPrompt(p),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),

              // Prompt Input Bar
              Container(
                padding: const EdgeInsets.all(AppGeometry.screenPadding),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        style: AppTypography.body.copyWith(color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: "Ask anything across your life...",
                          hintStyle: AppTypography.body.copyWith(color: colors.textMuted),
                          filled: true,
                          fillColor: colors.surfaceSoft,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: colors.border),
                          ),
                        ),
                        onSubmitted: _submitPrompt,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_upward, color: Colors.white),
                        onPressed: () => _submitPrompt(_promptController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppSemanticColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology_outlined, size: 48, color: colors.primary),
            ),
            const SizedBox(height: 16),
            Text("One Personal AI That Understands You", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              "OmniXPERIENCE connects your wardrobe, calendar, tasks, finances, wellness, and learning into unified intelligence.",
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            Text("Try asking:", style: AppTypography.label.copyWith(color: colors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator(AppSemanticColors colors) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Text("Synthesizing context across your domains...", style: AppTypography.caption.copyWith(color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(AssistantMessageModel msg, AppSemanticColors colors) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(18).copyWith(bottomRight: const Radius.circular(2)),
          ),
          child: Text(
            msg.prompt,
            style: AppTypography.body.copyWith(color: Colors.white),
          ),
        ),
      );
    }

    // Assistant message bubble
    Color badgeColor = colors.primary;
    if (msg.epistemicLevel == 'CALCULATED') badgeColor = Colors.teal;
    if (msg.epistemicLevel == 'RECOMMENDED') badgeColor = Colors.purple;
    if (msg.epistemicLevel == 'UNCERTAIN') badgeColor = colors.warning;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with epistemic badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_outlined, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      msg.epistemicLevel,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Referenced domain tags
              ...msg.referencedDomains.map((d) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text("#$d", style: AppTypography.caption.copyWith(color: colors.textMuted, fontSize: 10)),
              )),
            ],
          ),
          const SizedBox(height: 6),

          // Message Card
          AppCard(
            backgroundColor: colors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.response,
                  style: AppTypography.body.copyWith(color: colors.textPrimary, height: 1.4),
                ),

                // Citations
                if (msg.citations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: colors.border, height: 1),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: msg.citations.map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "• $c",
                        style: AppTypography.caption.copyWith(fontSize: 10, color: colors.textSecondary),
                      ),
                    )).toList(),
                  ),
                ],

                // Action Proposal Card
                if (msg.actionProposal != null) ...[
                  const SizedBox(height: 12),
                  _buildProposalCard(msg.actionProposal!, colors),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(ActionProposalModel prop, AppSemanticColors colors) {
    final isExecuted = prop.status == 'executed';
    final isRejected = prop.status == 'rejected';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExecuted
            ? colors.success.withOpacity(0.08)
            : (isRejected ? colors.surfaceSoft : colors.primarySoft.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExecuted
              ? colors.success
              : (isRejected ? colors.border : colors.primary.withOpacity(0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExecuted ? Icons.check_circle : (isRejected ? Icons.cancel : Icons.pending_actions),
                size: 16,
                color: isExecuted ? colors.success : (isRejected ? colors.textMuted : colors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prop.title,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(prop.description, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 10),

          if (!isExecuted && !isRejected) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.read<PersonalAiBloc>().add(RejectProposalEvent(prop.id)),
                  child: Text("Decline", style: TextStyle(color: colors.textMuted)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text("Confirm Action"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => context.read<PersonalAiBloc>().add(ConfirmProposalEvent(prop.id)),
                ),
              ],
            ),
          ] else if (isExecuted) ...[
            Text("✓ Action confirmed and added to your schedule.", style: AppTypography.caption.copyWith(color: colors.success, fontWeight: FontWeight.bold)),
          ] else ...[
            Text("✕ Action was cancelled.", style: AppTypography.caption.copyWith(color: colors.textMuted)),
          ],
        ],
      ),
    );
  }
}
