import 'package:equatable/equatable.dart';

class WardrobeItemModel extends Equatable {
  final String id;
  final String category;
  final String subcategory;
  final String name;
  final String? primaryColor;
  final List<String> secondaryColors;
  final List<String> colors;
  final String pattern;
  final List<String> styleTags;
  final String? material;
  final List<String> seasons;
  final List<String> seasonTags;
  final List<String> occasionTags;
  final String formality;
  final String fit;
  final String? size;
  final String? brand;
  final String? imageUrl;
  final String? thumbnailUrl;
  final double purchasePrice;
  final String currency;
  final String? purchaseDate;
  final String? notes;
  final int wearCount;
  final DateTime? lastWornDate;
  final bool favorite;
  final bool aiAnalyzed;
  final double? aiConfidence;
  final String? aiModel;
  final String? aiModelVersion;
  final String? analysisVersion;
  final bool userConfirmed;
  final String status;
  final int syncVersion;

  const WardrobeItemModel({
    required this.id,
    required this.category,
    required this.subcategory,
    required this.name,
    this.primaryColor,
    this.secondaryColors = const [],
    this.colors = const [],
    this.pattern = 'Solid',
    this.styleTags = const [],
    this.material,
    this.seasons = const ['Spring', 'Summer', 'Fall', 'Winter'],
    this.seasonTags = const [],
    this.occasionTags = const [],
    this.formality = 'Casual',
    this.fit = 'Regular',
    this.size,
    this.brand,
    this.imageUrl,
    this.thumbnailUrl,
    this.purchasePrice = 0.0,
    this.currency = 'USD',
    this.purchaseDate,
    this.notes,
    this.wearCount = 0,
    this.lastWornDate,
    this.favorite = false,
    this.aiAnalyzed = false,
    this.aiConfidence,
    this.aiModel,
    this.aiModelVersion,
    this.analysisVersion,
    this.userConfirmed = true,
    this.status = 'available',
    this.syncVersion = 1,
  });

  WardrobeItemModel copyWith({
    String? id,
    String? name,
    String? category,
    String? subcategory,
    String? primaryColor,
    List<String>? secondaryColors,
    List<String>? colors,
    String? pattern,
    List<String>? styleTags,
    String? material,
    List<String>? seasons,
    List<String>? seasonTags,
    List<String>? occasionTags,
    String? formality,
    String? fit,
    String? size,
    String? brand,
    String? imageUrl,
    String? thumbnailUrl,
    double? purchasePrice,
    String? currency,
    String? purchaseDate,
    String? notes,
    int? wearCount,
    DateTime? lastWornDate,
    bool? favorite,
    bool? aiAnalyzed,
    double? aiConfidence,
    String? aiModel,
    String? aiModelVersion,
    String? analysisVersion,
    bool? userConfirmed,
    String? status,
    int? syncVersion,
  }) {
    return WardrobeItemModel(
      id: id ?? this.id,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      name: name ?? this.name,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColors: secondaryColors ?? this.secondaryColors,
      colors: colors ?? this.colors,
      pattern: pattern ?? this.pattern,
      styleTags: styleTags ?? this.styleTags,
      material: material ?? this.material,
      seasons: seasons ?? this.seasons,
      seasonTags: seasonTags ?? this.seasonTags,
      occasionTags: occasionTags ?? this.occasionTags,
      formality: formality ?? this.formality,
      fit: fit ?? this.fit,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currency: currency ?? this.currency,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
      wearCount: wearCount ?? this.wearCount,
      lastWornDate: lastWornDate ?? this.lastWornDate,
      favorite: favorite ?? this.favorite,
      aiAnalyzed: aiAnalyzed ?? this.aiAnalyzed,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      aiModel: aiModel ?? this.aiModel,
      aiModelVersion: aiModelVersion ?? this.aiModelVersion,
      analysisVersion: analysisVersion ?? this.analysisVersion,
      userConfirmed: userConfirmed ?? this.userConfirmed,
      status: status ?? this.status,
      syncVersion: syncVersion ?? this.syncVersion,
    );
  }

  factory WardrobeItemModel.fromJson(Map<String, dynamic> json) {
    final rawColors = List<String>.from(json['colors'] ?? []);
    final pColor = json['primary_color'] as String? ?? (rawColors.isNotEmpty ? rawColors.first : null);
    final secColors = List<String>.from(json['secondary_colors'] ?? []);
    final sTags = List<String>.from(json['season_tags'] ?? json['seasons'] ?? []);

    return WardrobeItemModel(
      id: json['id'] ?? '',
      category: json['category'] ?? 'Tops',
      subcategory: json['subcategory'] ?? 'Shirts',
      name: json['name'] ?? '',
      primaryColor: pColor,
      secondaryColors: secColors,
      colors: rawColors.isNotEmpty ? rawColors : (pColor != null ? [pColor, ...secColors] : []),
      pattern: json['pattern'] ?? 'Solid',
      styleTags: List<String>.from(json['style_tags'] ?? []),
      material: json['material'],
      seasons: List<String>.from(json['seasons'] ?? ['Spring', 'Summer', 'Fall', 'Winter']),
      seasonTags: sTags,
      occasionTags: List<String>.from(json['occasion_tags'] ?? []),
      formality: json['formality'] ?? 'Casual',
      fit: json['fit'] ?? 'Regular',
      size: json['size'],
      brand: json['brand'],
      imageUrl: json['image_url'],
      thumbnailUrl: json['thumbnail_url'],
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      purchaseDate: json['purchase_date'],
      notes: json['notes'],
      wearCount: json['wear_count'] ?? 0,
      lastWornDate: json['last_worn_date'] != null ? DateTime.tryParse(json['last_worn_date']) : null,
      favorite: json['favorite'] == true || json['favorite'] == 1,
      aiAnalyzed: json['ai_analyzed'] == true || json['ai_analyzed'] == 1,
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      aiModel: json['ai_model'],
      aiModelVersion: json['ai_model_version'],
      analysisVersion: json['analysis_version'],
      userConfirmed: json['user_confirmed'] != false,
      status: json['status'] ?? 'available',
      syncVersion: json['sync_version'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'subcategory': subcategory,
      'name': name,
      'primary_color': primaryColor,
      'secondary_colors': secondaryColors,
      'colors': colors,
      'pattern': pattern,
      'style_tags': styleTags,
      'material': material,
      'seasons': seasons,
      'season_tags': seasonTags,
      'occasion_tags': occasionTags,
      'formality': formality,
      'fit': fit,
      'size': size,
      'brand': brand,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'purchase_price': purchasePrice,
      'currency': currency,
      'purchase_date': purchaseDate,
      'notes': notes,
      'wear_count': wearCount,
      'last_worn_date': lastWornDate?.toIso8601String(),
      'favorite': favorite,
      'ai_analyzed': aiAnalyzed,
      'ai_confidence': aiConfidence,
      'ai_model': aiModel,
      'ai_model_version': aiModelVersion,
      'analysis_version': analysisVersion,
      'user_confirmed': userConfirmed,
      'status': status,
      'sync_version': syncVersion,
    };
  }

  @override
  List<Object?> get props => [
    id, category, subcategory, name, primaryColor, secondaryColors, colors,
    pattern, styleTags, formality, fit, size, brand, imageUrl, thumbnailUrl,
    purchasePrice, wearCount, lastWornDate, favorite, aiAnalyzed, aiConfidence, status
  ];
}

class WearEventModel extends Equatable {
  final String id;
  final String wardrobeItemId;
  final String? outfitId;
  final DateTime timestamp;
  final String eventContext;
  final String source;

  const WearEventModel({
    required this.id,
    required this.wardrobeItemId,
    this.outfitId,
    required this.timestamp,
    this.eventContext = 'Daily',
    this.source = 'manual',
  });

  factory WearEventModel.fromJson(Map<String, dynamic> json) {
    return WearEventModel(
      id: json['id'] ?? '',
      wardrobeItemId: json['wardrobe_item_id'] ?? '',
      outfitId: json['outfit_id'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      eventContext: json['event_context'] ?? 'Daily',
      source: json['source'] ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wardrobe_item_id': wardrobeItemId,
      'outfit_id': outfitId,
      'timestamp': timestamp.toIso8601String(),
      'event_context': eventContext,
      'source': source,
    };
  }

  @override
  List<Object?> get props => [id, wardrobeItemId, timestamp, eventContext];
}

class PlannedOutfitModel extends Equatable {
  final String id;
  final String name;
  final List<String> itemIds;
  final String plannedDate;
  final String occasion;
  final double score;
  final String status;

  const PlannedOutfitModel({
    required this.id,
    required this.name,
    required this.itemIds,
    required this.plannedDate,
    required this.occasion,
    this.score = 0.0,
    this.status = 'planned',
  });

  factory PlannedOutfitModel.fromJson(Map<String, dynamic> json) {
    return PlannedOutfitModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Planned Outfit',
      itemIds: List<String>.from(json['item_ids'] ?? []),
      plannedDate: json['planned_date'] ?? '',
      occasion: json['occasion'] ?? 'Casual',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'planned',
    );
  }

  @override
  List<Object?> get props => [id, name, itemIds, plannedDate, occasion, score];
}

class EventModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool allDay;
  final String? location;
  final String category;
  final String priority;
  final String status;
  final String? color;
  final String? notes;
  final Map<String, dynamic>? recurrence;
  final List<int> reminderSettings;
  final List<String> relatedTaskIds;
  final String? relatedGoalId;
  final String? occasion;
  final String? sourceType;
  final String? sourceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.allDay = false,
    this.location,
    this.category = 'Personal',
    this.priority = 'Medium',
    this.status = 'scheduled',
    this.color,
    this.notes,
    this.recurrence,
    this.reminderSettings = const [],
    this.relatedTaskIds = const [],
    this.relatedGoalId,
    this.occasion,
    this.sourceType,
    this.sourceId,
    required this.createdAt,
    required this.updatedAt,
  });

  EventModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? allDay,
    String? location,
    String? category,
    String? priority,
    String? status,
    String? color,
    String? notes,
    Map<String, dynamic>? recurrence,
    List<int>? reminderSettings,
    List<String>? relatedTaskIds,
    String? relatedGoalId,
    String? occasion,
    String? sourceType,
    String? sourceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      location: location ?? this.location,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      recurrence: recurrence ?? this.recurrence,
      reminderSettings: reminderSettings ?? this.reminderSettings,
      relatedTaskIds: relatedTaskIds ?? this.relatedTaskIds,
      relatedGoalId: relatedGoalId ?? this.relatedGoalId,
      occasion: occasion ?? this.occasion,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      startTime: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['end_time'] ?? '') ?? DateTime.now(),
      allDay: json['all_day'] == true,
      location: json['location'],
      category: json['category'] ?? 'Personal',
      priority: json['priority'] ?? 'Medium',
      status: json['status'] ?? 'scheduled',
      color: json['color'],
      notes: json['notes'],
      recurrence: json['recurrence'] is Map<String, dynamic> ? json['recurrence'] : null,
      reminderSettings: List<int>.from(json['reminder_settings'] ?? []),
      relatedTaskIds: List<String>.from(json['related_task_ids'] ?? []),
      relatedGoalId: json['related_goal_id'],
      occasion: json['occasion'],
      sourceType: json['source_type'],
      sourceId: json['source_id'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'all_day': allDay,
      'location': location,
      'category': category,
      'priority': priority,
      'status': status,
      'color': color,
      'notes': notes,
      'recurrence': recurrence,
      'reminder_settings': reminderSettings,
      'related_task_ids': relatedTaskIds,
      'related_goal_id': relatedGoalId,
      'occasion': occasion,
      'source_type': sourceType,
      'source_id': sourceId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id, userId, title, description, startTime, endTime, allDay, location,
    category, priority, status, color, notes, recurrence, reminderSettings,
    relatedTaskIds, relatedGoalId, occasion, sourceType, sourceId, createdAt, updatedAt
  ];
}

class TaskModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final String? dueTime;
  final int estimatedDurationMinutes;
  final String category;
  final List<String> tags;
  final String? eventId;
  final String? parentTaskId;
  final List<String> dependencyTaskIds;
  final Map<String, dynamic>? recurrence;
  final String? notes;
  final List<int> reminderSettings;
  final DateTime? completedAt;
  final String? sourceType;
  final String? sourceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.status = 'Todo',
    this.priority = 'Medium',
    this.dueDate,
    this.dueTime,
    this.estimatedDurationMinutes = 30,
    this.category = 'Personal',
    this.tags = const [],
    this.eventId,
    this.parentTaskId,
    this.dependencyTaskIds = const [],
    this.recurrence,
    this.notes,
    this.reminderSettings = const [],
    this.completedAt,
    this.sourceType,
    this.sourceId,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    String? dueTime,
    int? estimatedDurationMinutes,
    String? category,
    List<String>? tags,
    String? eventId,
    String? parentTaskId,
    List<String>? dependencyTaskIds,
    Map<String, dynamic>? recurrence,
    String? notes,
    List<int>? reminderSettings,
    DateTime? completedAt,
    String? sourceType,
    String? sourceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      eventId: eventId ?? this.eventId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      dependencyTaskIds: dependencyTaskIds ?? this.dependencyTaskIds,
      recurrence: recurrence ?? this.recurrence,
      notes: notes ?? this.notes,
      reminderSettings: reminderSettings ?? this.reminderSettings,
      completedAt: completedAt ?? this.completedAt,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'Todo',
      priority: json['priority'] ?? 'Medium',
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
      dueTime: json['due_time'],
      estimatedDurationMinutes: json['estimated_duration_minutes'] ?? 30,
      category: json['category'] ?? 'Personal',
      tags: List<String>.from(json['tags'] ?? []),
      eventId: json['event_id'],
      parentTaskId: json['parent_task_id'],
      dependencyTaskIds: List<String>.from(json['dependency_task_ids'] ?? []),
      recurrence: json['recurrence'] is Map<String, dynamic> ? json['recurrence'] : null,
      notes: json['notes'],
      reminderSettings: List<int>.from(json['reminder_settings'] ?? []),
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
      sourceType: json['source_type'],
      sourceId: json['source_id'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'due_time': dueTime,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'category': category,
      'tags': tags,
      'event_id': eventId,
      'parent_task_id': parentTaskId,
      'dependency_task_ids': dependencyTaskIds,
      'recurrence': recurrence,
      'notes': notes,
      'reminder_settings': reminderSettings,
      'completed_at': completedAt?.toIso8601String(),
      'source_type': sourceType,
      'source_id': sourceId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id, userId, title, description, status, priority, dueDate, dueTime,
    estimatedDurationMinutes, category, tags, eventId, parentTaskId,
    dependencyTaskIds, recurrence, notes, reminderSettings, completedAt,
    sourceType, sourceId, createdAt, updatedAt
  ];
}

// ==========================================
// PHASE 6 — MONEY MODELS
// ==========================================

class ExpenseModel extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String category;
  final String? description;
  final DateTime expenseDate;
  final String paymentMethod;
  final String? merchant;
  final String? notes;
  final List<String> tags;
  final bool isRecurring;
  final Map<String, dynamic>? recurringRule;
  final String? source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    this.currency = 'INR',
    this.category = 'Other',
    this.description,
    required this.expenseDate,
    this.paymentMethod = 'UPI',
    this.merchant,
    this.notes,
    this.tags = const [],
    this.isRecurring = false,
    this.recurringRule,
    this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  ExpenseModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    String? category,
    String? description,
    DateTime? expenseDate,
    String? paymentMethod,
    String? merchant,
    String? notes,
    List<String>? tags,
    bool? isRecurring,
    Map<String, dynamic>? recurringRule,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      description: description ?? this.description,
      expenseDate: expenseDate ?? this.expenseDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      merchant: merchant ?? this.merchant,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringRule: recurringRule ?? this.recurringRule,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'INR',
      category: json['category'] ?? 'Other',
      description: json['description'],
      expenseDate: DateTime.tryParse(json['expense_date'] ?? '') ?? DateTime.now(),
      paymentMethod: json['payment_method'] ?? 'UPI',
      merchant: json['merchant'],
      notes: json['notes'],
      tags: List<String>.from(json['tags'] ?? []),
      isRecurring: json['is_recurring'] ?? false,
      recurringRule: json['recurring_rule'] is Map<String, dynamic> ? json['recurring_rule'] : null,
      source: json['source'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount.toStringAsFixed(2),
      'currency': currency,
      'category': category,
      'description': description,
      'expense_date': expenseDate.toIso8601String(),
      'payment_method': paymentMethod,
      'merchant': merchant,
      'notes': notes,
      'tags': tags,
      'is_recurring': isRecurring,
      'recurring_rule': recurringRule,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id, userId, amount, currency, category, description, expenseDate,
    paymentMethod, merchant, notes, tags, isRecurring, recurringRule,
    source, createdAt, updatedAt
  ];
}

class BudgetModel extends Equatable {
  final String id;
  final String userId;
  final String? category;
  final String period;
  final DateTime? startDate;
  final DateTime? endDate;
  final String currency;
  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetModel({
    required this.id,
    required this.userId,
    this.category,
    this.period = 'monthly',
    this.startDate,
    this.endDate,
    this.currency = 'INR',
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      category: json['category'],
      period: json['period'] ?? 'monthly',
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      currency: json['currency'] ?? 'INR',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'period': period,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'currency': currency,
      'amount': amount.toStringAsFixed(2),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id, userId, category, period, startDate, endDate, currency, amount, createdAt, updatedAt
  ];
}

class CategorySpendingModel extends Equatable {
  final String category;
  final double spent;
  final double? budget;
  final double? percentageUsed;
  final int transactionCount;

  const CategorySpendingModel({
    required this.category,
    required this.spent,
    this.budget,
    this.percentageUsed,
    required this.transactionCount,
  });

  factory CategorySpendingModel.fromJson(Map<String, dynamic> json) {
    return CategorySpendingModel(
      category: json['category'] ?? '',
      spent: (json['spent'] is num)
          ? (json['spent'] as num).toDouble()
          : double.tryParse(json['spent']?.toString() ?? '0') ?? 0.0,
      budget: json['budget'] != null
          ? ((json['budget'] is num)
              ? (json['budget'] as num).toDouble()
              : double.tryParse(json['budget'].toString()))
          : null,
      percentageUsed: json['percentage_used'] != null
          ? ((json['percentage_used'] is num)
              ? (json['percentage_used'] as num).toDouble()
              : double.tryParse(json['percentage_used'].toString()))
          : null,
      transactionCount: json['transaction_count'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [category, spent, budget, percentageUsed, transactionCount];
}

class FinancialInsightModel extends Equatable {
  final String type;
  final String title;
  final String description;
  final String severity;
  final Map<String, dynamic> supportingData;

  const FinancialInsightModel({
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    this.supportingData = const {},
  });

  factory FinancialInsightModel.fromJson(Map<String, dynamic> json) {
    return FinancialInsightModel(
      type: json['type'] ?? 'info',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'info',
      supportingData: json['supporting_data'] is Map<String, dynamic> ? json['supporting_data'] : {},
    );
  }

  @override
  List<Object?> get props => [type, title, description, severity, supportingData];
}

class FinancialSummaryModel extends Equatable {
  final String currency;
  final double todaySpent;
  final double weekSpent;
  final double monthSpent;
  final double? totalBudget;
  final double? remainingBudget;
  final double? budgetUsedPercentage;
  final double dailyAverage;
  final double projectedMonthSpent;
  final int daysElapsed;
  final int daysRemaining;
  final List<CategorySpendingModel> categoryBreakdown;
  final List<ExpenseModel> recentTransactions;
  final List<FinancialInsightModel> insights;

  const FinancialSummaryModel({
    this.currency = 'INR',
    required this.todaySpent,
    required this.weekSpent,
    required this.monthSpent,
    this.totalBudget,
    this.remainingBudget,
    this.budgetUsedPercentage,
    required this.dailyAverage,
    required this.projectedMonthSpent,
    required this.daysElapsed,
    required this.daysRemaining,
    this.categoryBreakdown = const [],
    this.recentTransactions = const [],
    this.insights = const [],
  });

  factory FinancialSummaryModel.fromJson(Map<String, dynamic> json) {
    return FinancialSummaryModel(
      currency: json['currency'] ?? 'INR',
      todaySpent: (json['today_spent'] is num) ? (json['today_spent'] as num).toDouble() : double.tryParse(json['today_spent']?.toString() ?? '0') ?? 0.0,
      weekSpent: (json['week_spent'] is num) ? (json['week_spent'] as num).toDouble() : double.tryParse(json['week_spent']?.toString() ?? '0') ?? 0.0,
      monthSpent: (json['month_spent'] is num) ? (json['month_spent'] as num).toDouble() : double.tryParse(json['month_spent']?.toString() ?? '0') ?? 0.0,
      totalBudget: json['total_budget'] != null ? ((json['total_budget'] is num) ? (json['total_budget'] as num).toDouble() : double.tryParse(json['total_budget'].toString())) : null,
      remainingBudget: json['remaining_budget'] != null ? ((json['remaining_budget'] is num) ? (json['remaining_budget'] as num).toDouble() : double.tryParse(json['remaining_budget'].toString())) : null,
      budgetUsedPercentage: json['budget_used_percentage'] != null ? ((json['budget_used_percentage'] is num) ? (json['budget_used_percentage'] as num).toDouble() : double.tryParse(json['budget_used_percentage'].toString())) : null,
      dailyAverage: (json['daily_average'] is num) ? (json['daily_average'] as num).toDouble() : double.tryParse(json['daily_average']?.toString() ?? '0') ?? 0.0,
      projectedMonthSpent: (json['projected_month_spent'] is num) ? (json['projected_month_spent'] as num).toDouble() : double.tryParse(json['projected_month_spent']?.toString() ?? '0') ?? 0.0,
      daysElapsed: json['days_elapsed'] ?? 1,
      daysRemaining: json['days_remaining'] ?? 0,
      categoryBreakdown: (json['category_breakdown'] as List? ?? []).map((x) => CategorySpendingModel.fromJson(x)).toList(),
      recentTransactions: (json['recent_transactions'] as List? ?? []).map((x) => ExpenseModel.fromJson(x)).toList(),
      insights: (json['insights'] as List? ?? []).map((x) => FinancialInsightModel.fromJson(x)).toList(),
    );
  }

  @override
  List<Object?> get props => [
    currency, todaySpent, weekSpent, monthSpent, totalBudget, remainingBudget,
    budgetUsedPercentage, dailyAverage, projectedMonthSpent, daysElapsed, daysRemaining,
    categoryBreakdown, recentTransactions, insights
  ];
}

// ==========================================
// PHASE 6 — WELLNESS MODELS
// ==========================================

class HabitModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String frequency;
  final int target;
  final String unit;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> reminderSettings;
  final String category;
  final bool active;
  final int currentStreak;
  final int longestStreak;
  final double completionRate;
  final bool completedToday;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.frequency = 'Daily',
    this.target = 1,
    this.unit = 'times',
    this.startDate,
    this.endDate,
    this.reminderSettings = const [],
    this.category = 'General',
    this.active = true,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completionRate = 0.0,
    this.completedToday = false,
    required this.createdAt,
    required this.updatedAt,
  });

  HabitModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? frequency,
    int? target,
    String? unit,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? reminderSettings,
    String? category,
    bool? active,
    int? currentStreak,
    int? longestStreak,
    double? completionRate,
    bool? completedToday,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      target: target ?? this.target,
      unit: unit ?? this.unit,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reminderSettings: reminderSettings ?? this.reminderSettings,
      category: category ?? this.category,
      active: active ?? this.active,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      completionRate: completionRate ?? this.completionRate,
      completedToday: completedToday ?? this.completedToday,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      frequency: json['frequency'] ?? 'Daily',
      target: json['target'] ?? 1,
      unit: json['unit'] ?? 'times',
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      reminderSettings: List<String>.from(json['reminder_settings'] ?? []),
      category: json['category'] ?? 'General',
      active: json['active'] ?? true,
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      completionRate: (json['completion_rate'] is num)
          ? (json['completion_rate'] as num).toDouble()
          : 0.0,
      completedToday: json['completed_today'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'frequency': frequency,
      'target': target,
      'unit': unit,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'reminder_settings': reminderSettings,
      'category': category,
      'active': active,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'completion_rate': completionRate,
      'completed_today': completedToday,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id, userId, name, description, frequency, target, unit,
    startDate, endDate, reminderSettings, category, active,
    currentStreak, longestStreak, completionRate, completedToday,
    createdAt, updatedAt
  ];
}

class SkincareProfileModel extends Equatable {
  final String id;
  final String userId;
  final String? skinType;
  final List<String> skinConcerns;
  final String sensitivityLevel;
  final String routineFrequency;
  final String? notes;

  const SkincareProfileModel({
    required this.id,
    required this.userId,
    this.skinType,
    this.skinConcerns = const [],
    this.sensitivityLevel = 'Normal',
    this.routineFrequency = 'Twice daily',
    this.notes,
  });

  factory SkincareProfileModel.fromJson(Map<String, dynamic> json) {
    return SkincareProfileModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      skinType: json['skin_type'],
      skinConcerns: List<String>.from(json['skin_concerns'] ?? []),
      sensitivityLevel: json['sensitivity_level'] ?? 'Normal',
      routineFrequency: json['routine_frequency'] ?? 'Twice daily',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'skin_type': skinType,
      'skin_concerns': skinConcerns,
      'sensitivity_level': sensitivityLevel,
      'routine_frequency': routineFrequency,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, userId, skinType, skinConcerns, sensitivityLevel, routineFrequency, notes];
}

class RoutineProductModel extends Equatable {
  final String id;
  final String userId;
  final String productName;
  final String category;
  final String? brand;
  final List<String> activeIngredients;
  final int routineStep;
  final String timeOfDay;
  final String frequency;
  final String? notes;
  final bool enabled;

  const RoutineProductModel({
    required this.id,
    required this.userId,
    required this.productName,
    this.category = 'Cleanser',
    this.brand,
    this.activeIngredients = const [],
    this.routineStep = 1,
    this.timeOfDay = 'morning',
    this.frequency = 'Daily',
    this.notes,
    this.enabled = true,
  });

  RoutineProductModel copyWith({
    String? id,
    String? userId,
    String? productName,
    String? category,
    String? brand,
    List<String>? activeIngredients,
    int? routineStep,
    String? timeOfDay,
    String? frequency,
    String? notes,
    bool? enabled,
  }) {
    return RoutineProductModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      activeIngredients: activeIngredients ?? this.activeIngredients,
      routineStep: routineStep ?? this.routineStep,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      frequency: frequency ?? this.frequency,
      notes: notes ?? this.notes,
      enabled: enabled ?? this.enabled,
    );
  }

  factory RoutineProductModel.fromJson(Map<String, dynamic> json) {
    return RoutineProductModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      productName: json['product_name'] ?? '',
      category: json['category'] ?? 'Cleanser',
      brand: json['brand'],
      activeIngredients: List<String>.from(json['active_ingredients'] ?? []),
      routineStep: json['routine_step'] ?? 1,
      timeOfDay: json['time_of_day'] ?? 'morning',
      frequency: json['frequency'] ?? 'Daily',
      notes: json['notes'],
      enabled: json['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_name': productName,
      'category': category,
      'brand': brand,
      'active_ingredients': activeIngredients,
      'routine_step': routineStep,
      'time_of_day': timeOfDay,
      'frequency': frequency,
      'notes': notes,
      'enabled': enabled,
    };
  }

  @override
  List<Object?> get props => [
    id, userId, productName, category, brand, activeIngredients,
    routineStep, timeOfDay, frequency, notes, enabled
  ];
}

class RoutineStepTodayModel extends Equatable {
  final String id;
  final String productName;
  final String category;
  final int routineStep;
  final String timeOfDay;
  final bool completed;

  const RoutineStepTodayModel({
    required this.id,
    required this.productName,
    required this.category,
    required this.routineStep,
    required this.timeOfDay,
    this.completed = false,
  });

  factory RoutineStepTodayModel.fromJson(Map<String, dynamic> json) {
    return RoutineStepTodayModel(
      id: json['id'] ?? '',
      productName: json['product_name'] ?? '',
      category: json['category'] ?? '',
      routineStep: json['routine_step'] ?? 1,
      timeOfDay: json['time_of_day'] ?? 'morning',
      completed: json['completed'] ?? false,
    );
  }

  @override
  List<Object?> get props => [id, productName, category, routineStep, timeOfDay, completed];
}

class WellnessInsightModel extends Equatable {
  final String type;
  final String title;
  final String description;
  final String severity;
  final Map<String, dynamic> supportingData;

  const WellnessInsightModel({
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    this.supportingData = const {},
  });

  factory WellnessInsightModel.fromJson(Map<String, dynamic> json) {
    return WellnessInsightModel(
      type: json['type'] ?? 'info',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'info',
      supportingData: json['supporting_data'] is Map<String, dynamic> ? json['supporting_data'] : {},
    );
  }

  @override
  List<Object?> get props => [type, title, description, severity, supportingData];
}

class TodayWellnessModel extends Equatable {
  final String date;
  final List<RoutineStepTodayModel> morningRoutine;
  final List<RoutineStepTodayModel> eveningRoutine;
  final List<HabitModel> habits;
  final int totalHabitsCount;
  final int completedHabitsCount;
  final List<WellnessInsightModel> insights;

  const TodayWellnessModel({
    required this.date,
    this.morningRoutine = const [],
    this.eveningRoutine = const [],
    this.habits = const [],
    this.totalHabitsCount = 0,
    this.completedHabitsCount = 0,
    this.insights = const [],
  });

  factory TodayWellnessModel.fromJson(Map<String, dynamic> json) {
    return TodayWellnessModel(
      date: json['date'] ?? '',
      morningRoutine: (json['morning_routine'] as List? ?? []).map((x) => RoutineStepTodayModel.fromJson(x)).toList(),
      eveningRoutine: (json['evening_routine'] as List? ?? []).map((x) => RoutineStepTodayModel.fromJson(x)).toList(),
      habits: (json['habits'] as List? ?? []).map((x) => HabitModel.fromJson(x)).toList(),
      totalHabitsCount: json['total_habits_count'] ?? 0,
      completedHabitsCount: json['completed_habits_count'] ?? 0,
      insights: (json['insights'] as List? ?? []).map((x) => WellnessInsightModel.fromJson(x)).toList(),
    );
  }

  @override
  List<Object?> get props => [
    date, morningRoutine, eveningRoutine, habits, totalHabitsCount, completedHabitsCount, insights
  ];
}

