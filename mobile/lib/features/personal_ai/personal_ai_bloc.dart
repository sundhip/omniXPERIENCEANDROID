import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'models/personal_ai_models.dart';
import 'personal_ai_repository.dart';

// ---------------- Events ----------------
abstract class PersonalAiEvent extends Equatable {
  const PersonalAiEvent();
  @override
  List<Object?> get props => [];
}

class LoadPersonalAiOverviewEvent extends PersonalAiEvent {
  const LoadPersonalAiOverviewEvent();
}

class AskAssistantEvent extends PersonalAiEvent {
  final String prompt;
  const AskAssistantEvent(this.prompt);
  @override
  List<Object?> get props => [prompt];
}

class ConfirmProposalEvent extends PersonalAiEvent {
  final String proposalId;
  const ConfirmProposalEvent(this.proposalId);
  @override
  List<Object?> get props => [proposalId];
}

class RejectProposalEvent extends PersonalAiEvent {
  final String proposalId;
  const RejectProposalEvent(this.proposalId);
  @override
  List<Object?> get props => [proposalId];
}

class DismissInsightEvent extends PersonalAiEvent {
  final String insightId;
  const DismissInsightEvent(this.insightId);
  @override
  List<Object?> get props => [insightId];
}

class ClearChatEvent extends PersonalAiEvent {
  const ClearChatEvent();
}


// ---------------- State ----------------
enum PersonalAiStatus { initial, loading, success, failure }

class PersonalAiState extends Equatable {
  final PersonalAiStatus status;
  final DailyPersonalBriefModel? dailyBrief;
  final List<ProactiveInsightModel> insights;
  final List<AssistantMessageModel> messages;
  final List<UserMemoryModel> memories;
  final bool isAsking;
  final String? errorMessage;
  final String? actionFeedback;

  const PersonalAiState({
    this.status = PersonalAiStatus.initial,
    this.dailyBrief,
    this.insights = const [],
    this.messages = const [],
    this.memories = const [],
    this.isAsking = false,
    this.errorMessage,
    this.actionFeedback,
  });

  PersonalAiState copyWith({
    PersonalAiStatus? status,
    DailyPersonalBriefModel? dailyBrief,
    List<ProactiveInsightModel>? insights,
    List<AssistantMessageModel>? messages,
    List<UserMemoryModel>? memories,
    bool? isAsking,
    String? errorMessage,
    String? actionFeedback,
  }) {
    return PersonalAiState(
      status: status ?? this.status,
      dailyBrief: dailyBrief ?? this.dailyBrief,
      insights: insights ?? this.insights,
      messages: messages ?? this.messages,
      memories: memories ?? this.memories,
      isAsking: isAsking ?? this.isAsking,
      errorMessage: errorMessage,
      actionFeedback: actionFeedback,
    );
  }

  @override
  List<Object?> get props => [
    status, dailyBrief, insights, messages,
    memories, isAsking, errorMessage, actionFeedback
  ];
}


// ---------------- BLoC ----------------
class PersonalAiBloc extends Bloc<PersonalAiEvent, PersonalAiState> {
  final PersonalAiRepository repository;

  PersonalAiBloc({required this.repository}) : super(const PersonalAiState()) {
    on<LoadPersonalAiOverviewEvent>(_onLoadOverview);
    on<AskAssistantEvent>(_onAskAssistant);
    on<ConfirmProposalEvent>(_onConfirmProposal);
    on<RejectProposalEvent>(_onRejectProposal);
    on<DismissInsightEvent>(_onDismissInsight);
    on<ClearChatEvent>(_onClearChat);
  }

  Future<void> _onLoadOverview(
    LoadPersonalAiOverviewEvent event,
    Emitter<PersonalAiState> emit,
  ) async {
    emit(state.copyWith(status: PersonalAiStatus.loading));
    try {
      final brief = await repository.getDailyBrief();
      final insights = await repository.getProactiveInsights();
      final memories = await repository.getMemories();
      final history = await repository.getChatHistory();

      emit(state.copyWith(
        status: PersonalAiStatus.success,
        dailyBrief: brief,
        insights: insights,
        memories: memories,
        messages: history,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PersonalAiStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAskAssistant(
    AskAssistantEvent event,
    Emitter<PersonalAiState> emit,
  ) async {
    final userMsg = AssistantMessageModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      prompt: event.prompt,
      response: event.prompt,
      createdAt: DateTime.now(),
      isUser: true,
    );

    final updatedMessages = List<AssistantMessageModel>.from(state.messages)..add(userMsg);
    emit(state.copyWith(messages: updatedMessages, isAsking: true, errorMessage: null));

    try {
      final reply = await repository.askAssistant(event.prompt);
      final finalMessages = List<AssistantMessageModel>.from(state.messages)..add(reply);
      emit(state.copyWith(messages: finalMessages, isAsking: false));
    } catch (e) {
      emit(state.copyWith(
        isAsking: false,
        errorMessage: 'Failed to process request: $e',
      ));
    }
  }

  Future<void> _onConfirmProposal(
    ConfirmProposalEvent event,
    Emitter<PersonalAiState> emit,
  ) async {
    try {
      final success = await repository.executeAction(event.proposalId, confirm: true);
      if (success) {
        // Update proposal status in state messages
        final updated = state.messages.map((m) {
          if (m.actionProposal != null && m.actionProposal!.id == event.proposalId) {
            final updatedProposal = m.actionProposal!.copyWith(status: 'executed');
            return AssistantMessageModel(
              id: m.id,
              prompt: m.prompt,
              response: m.response,
              epistemicLevel: m.epistemicLevel,
              referencedDomains: m.referencedDomains,
              citations: m.citations,
              actionProposal: updatedProposal,
              suggestedFollowups: m.suggestedFollowups,
              createdAt: m.createdAt,
              isUser: m.isUser,
            );
          }
          return m;
        }).toList();

        emit(state.copyWith(
          messages: updated,
          actionFeedback: 'Action executed successfully.',
        ));
      } else {
        emit(state.copyWith(errorMessage: 'Could not execute action.'));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onRejectProposal(
    RejectProposalEvent event,
    Emitter<PersonalAiState> emit,
  ) async {
    try {
      await repository.executeAction(event.proposalId, confirm: false);
      final updated = state.messages.map((m) {
        if (m.actionProposal != null && m.actionProposal!.id == event.proposalId) {
          final updatedProposal = m.actionProposal!.copyWith(status: 'rejected');
          return AssistantMessageModel(
            id: m.id,
            prompt: m.prompt,
            response: m.response,
            epistemicLevel: m.epistemicLevel,
            referencedDomains: m.referencedDomains,
            citations: m.citations,
            actionProposal: updatedProposal,
            suggestedFollowups: m.suggestedFollowups,
            createdAt: m.createdAt,
            isUser: m.isUser,
          );
        }
        return m;
      }).toList();

      emit(state.copyWith(
        messages: updated,
        actionFeedback: 'Action cancelled.',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDismissInsight(
    DismissInsightEvent event,
    Emitter<PersonalAiState> emit,
  ) async {
    await repository.dismissInsight(event.insightId);
    final updated = state.insights.where((i) => i.id != event.insightId).toList();
    emit(state.copyWith(insights: updated));
  }

  Future<void> _onClearChat(
    ClearChatEvent event,
    Emitter<PersonalAiState> emit,
  ) async {
    await repository.clearChatHistory();
    emit(state.copyWith(messages: const []));
  }
}
