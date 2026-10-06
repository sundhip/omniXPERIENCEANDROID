import 'package:equatable/equatable.dart';

class UserProfileModel extends Equatable {
  final String id;
  final String userId;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final int? age;
  final String? gender;
  final String? location;
  final double? heightCm;
  final double? weightKg;
  final String? bodyType; // slim, athletic, average, broad, prefer_not_to_say
  final bool onboardingCompleted;
  final List<String> stylePreferences;
  final String fitPreference; // slim, regular, relaxed, oversized, mixed
  final List<String> preferredColors;
  final List<String> dislikedColors;
  final List<String> occasions;
  final List<String> lifestyle;
  final Map<String, double> priorities;
  final bool aiPersonalizationEnabled;

  const UserProfileModel({
    this.id = '',
    this.userId = '',
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.age,
    this.gender,
    this.location,
    this.heightCm,
    this.weightKg,
    this.bodyType,
    this.onboardingCompleted = false,
    this.stylePreferences = const [],
    this.fitPreference = 'Regular',
    this.preferredColors = const [],
    this.dislikedColors = const [],
    this.occasions = const [],
    this.lifestyle = const [],
    this.priorities = const {
      'comfort': 0.8,
      'appearance': 0.8,
      'practicality': 0.7,
      'formality': 0.5,
    },
    this.aiPersonalizationEnabled = true,
  });

  UserProfileModel copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? email,
    String? avatarUrl,
    int? age,
    String? gender,
    String? location,
    double? heightCm,
    double? weightKg,
    String? bodyType,
    bool? onboardingCompleted,
    List<String>? stylePreferences,
    String? fitPreference,
    List<String>? preferredColors,
    List<String>? dislikedColors,
    List<String>? occasions,
    List<String>? lifestyle,
    Map<String, double>? priorities,
    bool? aiPersonalizationEnabled,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bodyType: bodyType ?? this.bodyType,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      stylePreferences: stylePreferences ?? this.stylePreferences,
      fitPreference: fitPreference ?? this.fitPreference,
      preferredColors: preferredColors ?? this.preferredColors,
      dislikedColors: dislikedColors ?? this.dislikedColors,
      occasions: occasions ?? this.occasions,
      lifestyle: lifestyle ?? this.lifestyle,
      priorities: priorities ?? this.priorities,
      aiPersonalizationEnabled: aiPersonalizationEnabled ?? this.aiPersonalizationEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'email': email,
      'avatar_url': avatarUrl,
      'age': age,
      'gender': gender,
      'location': location,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'body_type': bodyType,
      'onboarding_completed': onboardingCompleted,
      'style_preferences': stylePreferences,
      'fit_preference': fitPreference,
      'preferred_colors': preferredColors,
      'disliked_colors': dislikedColors,
      'occasions': occasions,
      'lifestyle': lifestyle,
      'priorities': priorities,
      'ai_personalization_enabled': aiPersonalizationEnabled,
    };
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    Map<String, double> parsedPriorities = {};
    if (json['priorities'] != null && json['priorities'] is Map) {
      (json['priorities'] as Map).forEach((k, v) {
        if (v is num) {
          parsedPriorities[k.toString()] = v.toDouble();
        }
      });
    }

    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'User',
      email: json['email']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      age: json['age'] is num ? (json['age'] as num).toInt() : null,
      gender: json['gender']?.toString(),
      location: json['location']?.toString(),
      heightCm: json['height_cm'] is num ? (json['height_cm'] as num).toDouble() : null,
      weightKg: json['weight_kg'] is num ? (json['weight_kg'] as num).toDouble() : null,
      bodyType: json['body_type']?.toString(),
      onboardingCompleted: json['onboarding_completed'] == true,
      stylePreferences: json['style_preferences'] is List
          ? List<String>.from(json['style_preferences'].map((e) => e.toString()))
          : const [],
      fitPreference: json['fit_preference']?.toString() ?? 'Regular',
      preferredColors: json['preferred_colors'] is List
          ? List<String>.from(json['preferred_colors'].map((e) => e.toString()))
          : const [],
      dislikedColors: json['disliked_colors'] is List
          ? List<String>.from(json['disliked_colors'].map((e) => e.toString()))
          : const [],
      occasions: json['occasions'] is List
          ? List<String>.from(json['occasions'].map((e) => e.toString()))
          : const [],
      lifestyle: json['lifestyle'] is List
          ? List<String>.from(json['lifestyle'].map((e) => e.toString()))
          : const [],
      priorities: parsedPriorities.isNotEmpty
          ? parsedPriorities
          : const {
              'comfort': 0.8,
              'appearance': 0.8,
              'practicality': 0.7,
              'formality': 0.5,
            },
      aiPersonalizationEnabled: json['ai_personalization_enabled'] != false,
    );
  }

  /// Deterministic profile completion calculation (0 - 100)
  int calculateCompletionPercentage() {
    int score = 0;
    if (displayName.trim().isNotEmpty) score += 15;
    if (age != null || (location != null && location!.trim().isNotEmpty)) score += 10;
    if (heightCm != null || weightKg != null || (bodyType != null && bodyType!.isNotEmpty)) score += 15;
    if (stylePreferences.isNotEmpty) score += 15;
    if (fitPreference.isNotEmpty) score += 10;
    if (preferredColors.isNotEmpty) score += 15;
    if (occasions.isNotEmpty || lifestyle.isNotEmpty) score += 10;
    if (priorities.isNotEmpty) score += 10;
    return score.clamp(0, 100);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        displayName,
        email,
        avatarUrl,
        age,
        gender,
        location,
        heightCm,
        weightKg,
        bodyType,
        onboardingCompleted,
        stylePreferences,
        fitPreference,
        preferredColors,
        dislikedColors,
        occasions,
        lifestyle,
        priorities,
        aiPersonalizationEnabled,
      ];

  // Standard constants for UI selections
  static const List<Map<String, String>> availableStyles = [
    {'id': 'Casual', 'label': 'Casual'},
    {'id': 'Smart Casual', 'label': 'Smart Casual'},
    {'id': 'Formal', 'label': 'Formal'},
    {'id': 'Streetwear', 'label': 'Streetwear'},
    {'id': 'Minimal', 'label': 'Minimal'},
    {'id': 'Sporty', 'label': 'Sporty'},
    {'id': 'Traditional', 'label': 'Traditional'},
    {'id': 'Classic', 'label': 'Classic'},
    {'id': 'Experimental', 'label': 'Experimental'},
    {'id': 'Other', 'label': 'Other'},
  ];

  static const List<Map<String, String>> availableFits = [
    {'id': 'Slim', 'label': 'Slim'},
    {'id': 'Regular', 'label': 'Regular'},
    {'id': 'Relaxed', 'label': 'Relaxed'},
    {'id': 'Oversized', 'label': 'Oversized'},
    {'id': 'Mixed', 'label': 'Mixed'},
  ];

  static const List<Map<String, String>> availableBodyTypes = [
    {'id': 'Slim', 'label': 'Slim'},
    {'id': 'Athletic', 'label': 'Athletic'},
    {'id': 'Average', 'label': 'Average'},
    {'id': 'Broad', 'label': 'Broad'},
    {'id': 'Prefer not to say', 'label': 'Prefer not to say'},
  ];

  static const List<Map<String, dynamic>> standardColors = [
    {'hex': '#000000', 'name': 'Black', 'color': 0xFF000000},
    {'hex': '#FFFFFF', 'name': 'White', 'color': 0xFFFFFFFF},
    {'hex': '#1E3A8A', 'name': 'Navy Blue', 'color': 0xFF1E3A8A},
    {'hex': '#6B7280', 'name': 'Grey', 'color': 0xFF6B7280},
    {'hex': '#1F2937', 'name': 'Charcoal', 'color': 0xFF1F2937},
    {'hex': '#78350F', 'name': 'Brown / Tan', 'color': 0xFF78350F},
    {'hex': '#881337', 'name': 'Burgundy', 'color': 0xFF881337},
    {'hex': '#14532D', 'name': 'Forest Green', 'color': 0xFF14532D},
    {'hex': '#E5E7EB', 'name': 'Beige / Cream', 'color': 0xFFE5E7EB},
    {'hex': '#3B82F6', 'name': 'Cobalt Blue', 'color': 0xFF3B82F6},
    {'hex': '#E11D48', 'name': 'Red', 'color': 0xFFE11D48},
    {'hex': '#F59E0B', 'name': 'Mustard / Amber', 'color': 0xFFF59E0B},
  ];

  static const List<Map<String, String>> availableOccasions = [
    {'id': 'College', 'label': 'College'},
    {'id': 'Office', 'label': 'Office'},
    {'id': 'Presentation', 'label': 'Presentation'},
    {'id': 'Interview', 'label': 'Interview'},
    {'id': 'Party', 'label': 'Party'},
    {'id': 'Date', 'label': 'Date'},
    {'id': 'Wedding', 'label': 'Wedding'},
    {'id': 'Travel', 'label': 'Travel'},
    {'id': 'Gym', 'label': 'Gym'},
    {'id': 'Casual Outing', 'label': 'Casual Outing'},
    {'id': 'Formal Event', 'label': 'Formal Event'},
    {'id': 'Other', 'label': 'Other'},
  ];

  static const List<Map<String, String>> availableLifestyle = [
    {'id': 'College', 'label': 'College'},
    {'id': 'Work', 'label': 'Work'},
    {'id': 'Gym', 'label': 'Gym / Fitness'},
    {'id': 'Travel', 'label': 'Travel'},
    {'id': 'Events', 'label': 'Events & Parties'},
    {'id': 'Outdoor', 'label': 'Outdoor Activities'},
    {'id': 'Social', 'label': 'Social Outings'},
  ];

  static const List<Map<String, String>> availablePriorityKeys = [
    {'key': 'comfort', 'label': 'Comfort'},
    {'key': 'appearance', 'label': 'Appearance'},
    {'key': 'practicality', 'label': 'Practicality'},
    {'key': 'formality', 'label': 'Formality'},
    {'key': 'trendiness', 'label': 'Trendiness'},
    {'key': 'color_coordination', 'label': 'Color Coordination'},
    {'key': 'uniqueness', 'label': 'Uniqueness'},
  ];
}
