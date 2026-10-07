import 'package:equatable/equatable.dart';

class ActionProposalModel extends Equatable {
  final String id;
  final String actionType;
  final String title;
  final String description;
  final Map<String, dynamic> payload;
  final bool requiresConfirmation;
  final String status;
  final DateTime? createdAt;

  const ActionProposalModel({
    required this.id,
    required this.actionType,
    required this.title,
    required this.description,
    this.payload = const {},
    this.requiresConfirmation = true,
    this.status = 'pending',
    this.createdAt,
  });

  factory ActionProposalModel.fromJson(Map<String, dynamic> json) {
    return ActionProposalModel(
      id: json['id'] ?? '',
      actionType: json['action_type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
      requiresConfirmation: json['requires_confirmation'] ?? true,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action_type': actionType,
      'title': title,
      'description': description,
      'payload': payload,
      'requires_confirmation': requiresConfirmation,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  ActionProposalModel copyWith({
    String? id,
    String? actionType,
    String? title,
    String? description,
    Map<String, dynamic>? payload,
    bool? requiresConfirmation,
    String? status,
    DateTime? createdAt,
  }) {
    return ActionProposalModel(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      title: title ?? this.title,
      description: description ?? this.description,
      payload: payload ?? this.payload,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, actionType, title, description, payload, requiresConfirmation, status, createdAt];
}


class AssistantMessageModel extends Equatable {
  final String id;
  final String prompt;
  final String response;
  final String epistemicLevel; // KNOWN, CALCULATED, RECOMMENDED, UNCERTAIN
  final List<String> referencedDomains;
  final List<String> citations;
  final ActionProposalModel? actionProposal;
  final List<String> suggestedFollowups;
  final DateTime createdAt;
  final bool isUser;

  const AssistantMessageModel({
    required this.id,
    required this.prompt,
    required this.response,
    this.epistemicLevel = 'RECOMMENDED',
    this.referencedDomains = const [],
    this.citations = const [],
    this.actionProposal,
    this.suggestedFollowups = const [],
    required this.createdAt,
    this.isUser = false,
  });

  factory AssistantMessageModel.fromJson(Map<String, dynamic> json) {
    return AssistantMessageModel(
      id: json['id'] ?? '',
      prompt: json['prompt'] ?? '',
      response: json['response'] ?? '',
      epistemicLevel: json['epistemic_level'] ?? 'RECOMMENDED',
      referencedDomains: List<String>.from(json['referenced_domains'] ?? []),
      citations: List<String>.from(json['citations'] ?? []),
      actionProposal: json['action_proposal'] != null
          ? ActionProposalModel.fromJson(json['action_proposal'])
          : null,
      suggestedFollowups: List<String>.from(json['suggested_followups'] ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      isUser: json['is_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'response': response,
      'epistemic_level': epistemicLevel,
      'referenced_domains': referencedDomains,
      'citations': citations,
      'action_proposal': actionProposal?.toJson(),
      'suggested_followups': suggestedFollowups,
      'created_at': createdAt.toIso8601String(),
      'is_user': isUser,
    };
  }

  @override
  List<Object?> get props => [
    id, prompt, response, epistemicLevel, referencedDomains,
    citations, actionProposal, suggestedFollowups, createdAt, isUser
  ];
}


class DailyPersonalBriefModel extends Equatable {
  final String date;
  final String greeting;
  final String userName;
  final int eventsCount;
  final int priorityTasksCount;
  final int approachingDeadlinesCount;
  final int pendingHabitsCount;
  final String focus;
  final String plan;
  final String prepare;
  final String wellness;
  final List<String> proactiveAlerts;

  const DailyPersonalBriefModel({
    required this.date,
    required this.greeting,
    required this.userName,
    this.eventsCount = 0,
    this.priorityTasksCount = 0,
    this.approachingDeadlinesCount = 0,
    this.pendingHabitsCount = 0,
    this.focus = '',
    this.plan = '',
    this.prepare = '',
    this.wellness = '',
    this.proactiveAlerts = const [],
  });

  factory DailyPersonalBriefModel.fromJson(Map<String, dynamic> json) {
    return DailyPersonalBriefModel(
      date: json['date'] ?? '',
      greeting: json['greeting'] ?? '',
      userName: json['user_name'] ?? 'Alex',
      eventsCount: json['events_count'] ?? 0,
      priorityTasksCount: json['priority_tasks_count'] ?? 0,
      approachingDeadlinesCount: json['approaching_deadlines_count'] ?? 0,
      pendingHabitsCount: json['pending_habits_count'] ?? 0,
      focus: json['focus'] ?? '',
      plan: json['plan'] ?? '',
      prepare: json['prepare'] ?? '',
      wellness: json['wellness'] ?? '',
      proactiveAlerts: List<String>.from(json['proactive_alerts'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'greeting': greeting,
      'user_name': userName,
      'events_count': eventsCount,
      'priority_tasks_count': priorityTasksCount,
      'approaching_deadlines_count': approachingDeadlinesCount,
      'pending_habits_count': pendingHabitsCount,
      'focus': focus,
      'plan': plan,
      'prepare': prepare,
      'wellness': wellness,
      'proactive_alerts': proactiveAlerts,
    };
  }

  @override
  List<Object?> get props => [
    date, greeting, userName, eventsCount, priorityTasksCount,
    approachingDeadlinesCount, pendingHabitsCount, focus, plan, prepare, wellness, proactiveAlerts
  ];
}


class ProactiveInsightModel extends Equatable {
  final String id;
  final String insightType;
  final String severity; // info, warning, urgent
  final String title;
  final String explanation;
  final Map<String, dynamic> supportingData;
  final String? recommendedAction;
  final ActionProposalModel? actionProposal;
  final bool dismissed;
  final DateTime createdAt;

  const ProactiveInsightModel({
    required this.id,
    required this.insightType,
    this.severity = 'info',
    required this.title,
    required this.explanation,
    this.supportingData = const {},
    this.recommendedAction,
    this.actionProposal,
    this.dismissed = false,
    required this.createdAt,
  });

  factory ProactiveInsightModel.fromJson(Map<String, dynamic> json) {
    return ProactiveInsightModel(
      id: json['id'] ?? '',
      insightType: json['insight_type'] ?? '',
      severity: json['severity'] ?? 'info',
      title: json['title'] ?? '',
      explanation: json['explanation'] ?? '',
      supportingData: Map<String, dynamic>.from(json['supporting_data'] ?? {}),
      recommendedAction: json['recommended_action'],
      actionProposal: json['action_proposal'] != null
          ? ActionProposalModel.fromJson(json['action_proposal'])
          : null,
      dismissed: json['dismissed'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'insight_type': insightType,
      'severity': severity,
      'title': title,
      'explanation': explanation,
      'supporting_data': supportingData,
      'recommended_action': recommendedAction,
      'action_proposal': actionProposal?.toJson(),
      'dismissed': dismissed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id, insightType, severity, title, explanation,
    supportingData, recommendedAction, actionProposal, dismissed, createdAt
  ];
}


class UserMemoryModel extends Equatable {
  final String id;
  final String key;
  final String value;
  final String domain;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserMemoryModel({
    required this.id,
    required this.key,
    required this.value,
    this.domain = 'general',
    this.source = 'user_confirmed',
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserMemoryModel.fromJson(Map<String, dynamic> json) {
    return UserMemoryModel(
      id: json['id'] ?? '',
      key: json['key'] ?? '',
      value: json['value'] ?? '',
      domain: json['domain'] ?? 'general',
      source: json['source'] ?? 'user_confirmed',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'domain': domain,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, key, value, domain, source, createdAt, updatedAt];
}
