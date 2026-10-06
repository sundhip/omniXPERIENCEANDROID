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
  final String? bodyType; // Slim, Athletic, Average, Broad, Prefer not to say
  final bool onboardingCompleted;

  // Phase 1 & 2 Style & Fit
  final List<String> stylePreferences;
  final String primaryStyle;
  final List<String> secondaryStyles;
  final String fitPreference;
  final String primaryFit;
  final String? secondaryFit;

  // Colors
  final List<String> preferredColors;
  final List<String> dislikedColors;
  final List<String> neutralColors;
  final List<String> colorsToExperiment;
  final double colorExperimentationScore; // 0.0 (avoids) to 1.0 (highly experimental)

  // Occasions & Routine
  final List<String> occasions;
  final List<String> topOccasions; // Top 3
  final Map<String, double> occasionFrequencies; // formal: 0.2, casual: 0.9, etc.
  final List<String> lifestyle;

  // Preferences & Priorities
  final double comfortAppearanceScore; // 0.0 (Comfort) <--> 1.0 (Appearance)
  final double experimentationScore; // 0.0 (Very Safe) to 1.0 (Very Experimental)
  final Map<String, double> priorities;
  final List<String> fashionPrioritiesRanked;
  final Map<String, double> fashionPriorityWeights;

  // Optional Brands & Budget
  final List<String> preferredBrands;
  final List<String> avoidedBrands;
  final String budgetTier; // Budget, Mid-range, Premium, No preference

  // Personal Style Profile (Structured & Deterministic)
  final Map<String, dynamic>? personalStyleProfile;
  final int personalizationVersion;
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
    this.primaryStyle = 'Casual',
    this.secondaryStyles = const [],
    this.fitPreference = 'Regular',
    this.primaryFit = 'Regular',
    this.secondaryFit,
    this.preferredColors = const [],
    this.dislikedColors = const [],
    this.neutralColors = const [],
    this.colorsToExperiment = const [],
    this.colorExperimentationScore = 0.5,
    this.occasions = const [],
    this.topOccasions = const [],
    this.occasionFrequencies = const {
      'casual': 0.9,
      'smart_casual': 0.6,
      'formal': 0.2,
      'sportswear': 0.4,
    },
    this.lifestyle = const [],
    this.comfortAppearanceScore = 0.5,
    this.experimentationScore = 0.5,
    this.priorities = const {
      'comfort': 0.8,
      'appearance': 0.8,
      'practicality': 0.7,
      'formality': 0.5,
    },
    this.fashionPrioritiesRanked = const [
      'comfort',
      'appearance',
      'practicality',
      'formality',
      'trendiness',
    ],
    this.fashionPriorityWeights = const {},
    this.preferredBrands = const [],
    this.avoidedBrands = const [],
    this.budgetTier = 'Mid-range',
    this.personalStyleProfile,
    this.personalizationVersion = 1,
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
    String? primaryStyle,
    List<String>? secondaryStyles,
    String? fitPreference,
    String? primaryFit,
    String? secondaryFit,
    List<String>? preferredColors,
    List<String>? dislikedColors,
    List<String>? neutralColors,
    List<String>? colorsToExperiment,
    double? colorExperimentationScore,
    List<String>? occasions,
    List<String>? topOccasions,
    Map<String, double>? occasionFrequencies,
    List<String>? lifestyle,
    double? comfortAppearanceScore,
    double? experimentationScore,
    Map<String, double>? priorities,
    List<String>? fashionPrioritiesRanked,
    Map<String, double>? fashionPriorityWeights,
    List<String>? preferredBrands,
    List<String>? avoidedBrands,
    String? budgetTier,
    Map<String, dynamic>? personalStyleProfile,
    int? personalizationVersion,
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
      primaryStyle: primaryStyle ?? this.primaryStyle,
      secondaryStyles: secondaryStyles ?? this.secondaryStyles,
      fitPreference: fitPreference ?? this.fitPreference,
      primaryFit: primaryFit ?? this.primaryFit,
      secondaryFit: secondaryFit ?? this.secondaryFit,
      preferredColors: preferredColors ?? this.preferredColors,
      dislikedColors: dislikedColors ?? this.dislikedColors,
      neutralColors: neutralColors ?? this.neutralColors,
      colorsToExperiment: colorsToExperiment ?? this.colorsToExperiment,
      colorExperimentationScore: colorExperimentationScore ?? this.colorExperimentationScore,
      occasions: occasions ?? this.occasions,
      topOccasions: topOccasions ?? this.topOccasions,
      occasionFrequencies: occasionFrequencies ?? this.occasionFrequencies,
      lifestyle: lifestyle ?? this.lifestyle,
      comfortAppearanceScore: comfortAppearanceScore ?? this.comfortAppearanceScore,
      experimentationScore: experimentationScore ?? this.experimentationScore,
      priorities: priorities ?? this.priorities,
      fashionPrioritiesRanked: fashionPrioritiesRanked ?? this.fashionPrioritiesRanked,
      fashionPriorityWeights: fashionPriorityWeights ?? this.fashionPriorityWeights,
      preferredBrands: preferredBrands ?? this.preferredBrands,
      avoidedBrands: avoidedBrands ?? this.avoidedBrands,
      budgetTier: budgetTier ?? this.budgetTier,
      personalStyleProfile: personalStyleProfile ?? this.personalStyleProfile,
      personalizationVersion: personalizationVersion ?? this.personalizationVersion,
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
      'primary_style': primaryStyle,
      'secondary_styles': secondaryStyles,
      'fit_preference': fitPreference,
      'primary_fit': primaryFit,
      'secondary_fit': secondaryFit,
      'preferred_colors': preferredColors,
      'disliked_colors': dislikedColors,
      'neutral_colors': neutralColors,
      'colors_to_experiment': colorsToExperiment,
      'color_experimentation_score': colorExperimentationScore,
      'occasions': occasions,
      'top_occasions': topOccasions,
      'occasion_frequencies': occasionFrequencies,
      'lifestyle': lifestyle,
      'comfort_appearance_score': comfortAppearanceScore,
      'experimentation_score': experimentationScore,
      'priorities': priorities,
      'fashion_priorities_ranked': fashionPrioritiesRanked,
      'fashion_priority_weights': fashionPriorityWeights,
      'preferred_brands': preferredBrands,
      'avoided_brands': avoidedBrands,
      'budget_tier': budgetTier,
      'personal_style_profile': personalStyleProfile ?? {},
      'personalization_version': personalizationVersion,
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

    Map<String, double> parsedOccasionFreqs = {};
    if (json['occasion_frequencies'] != null && json['occasion_frequencies'] is Map) {
      (json['occasion_frequencies'] as Map).forEach((k, v) {
        if (v is num) {
          parsedOccasionFreqs[k.toString()] = v.toDouble();
        }
      });
    }

    Map<String, double> parsedPriorityWeights = {};
    if (json['fashion_priority_weights'] != null && json['fashion_priority_weights'] is Map) {
      (json['fashion_priority_weights'] as Map).forEach((k, v) {
        if (v is num) {
          parsedPriorityWeights[k.toString()] = v.toDouble();
        }
      });
    }

    final pStyle = json['primary_style']?.toString() ??
        (json['style_preferences'] is List && (json['style_preferences'] as List).isNotEmpty
            ? (json['style_preferences'] as List).first.toString()
            : 'Casual');

    final sStyles = json['secondary_styles'] is List
        ? List<String>.from((json['secondary_styles'] as List).map((e) => e.toString()))
        : (json['style_preferences'] is List && (json['style_preferences'] as List).length > 1
            ? List<String>.from((json['style_preferences'] as List).skip(1).map((e) => e.toString()))
            : <String>[]);

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
          ? List<String>.from((json['style_preferences'] as List).map((e) => e.toString()))
          : const [],
      primaryStyle: pStyle,
      secondaryStyles: sStyles,
      fitPreference: json['fit_preference']?.toString() ?? 'Regular',
      primaryFit: json['primary_fit']?.toString() ?? (json['fit_preference']?.toString() ?? 'Regular'),
      secondaryFit: json['secondary_fit']?.toString(),
      preferredColors: json['preferred_colors'] is List
          ? List<String>.from((json['preferred_colors'] as List).map((e) => e.toString()))
          : const [],
      dislikedColors: json['disliked_colors'] is List
          ? List<String>.from((json['disliked_colors'] as List).map((e) => e.toString()))
          : const [],
      neutralColors: json['neutral_colors'] is List
          ? List<String>.from((json['neutral_colors'] as List).map((e) => e.toString()))
          : const [],
      colorsToExperiment: json['colors_to_experiment'] is List
          ? List<String>.from((json['colors_to_experiment'] as List).map((e) => e.toString()))
          : const [],
      colorExperimentationScore: json['color_experimentation_score'] is num
          ? (json['color_experimentation_score'] as num).toDouble()
          : 0.5,
      occasions: json['occasions'] is List
          ? List<String>.from((json['occasions'] as List).map((e) => e.toString()))
          : const [],
      topOccasions: json['top_occasions'] is List
          ? List<String>.from((json['top_occasions'] as List).map((e) => e.toString()))
          : const [],
      occasionFrequencies: parsedOccasionFreqs.isNotEmpty
          ? parsedOccasionFreqs
          : const {
              'casual': 0.9,
              'smart_casual': 0.6,
              'formal': 0.2,
              'sportswear': 0.4,
            },
      lifestyle: json['lifestyle'] is List
          ? List<String>.from((json['lifestyle'] as List).map((e) => e.toString()))
          : const [],
      comfortAppearanceScore: json['comfort_appearance_score'] is num
          ? (json['comfort_appearance_score'] as num).toDouble()
          : 0.5,
      experimentationScore: json['experimentation_score'] is num
          ? (json['experimentation_score'] as num).toDouble()
          : 0.5,
      priorities: parsedPriorities.isNotEmpty
          ? parsedPriorities
          : const {
              'comfort': 0.8,
              'appearance': 0.8,
              'practicality': 0.7,
              'formality': 0.5,
            },
      fashionPrioritiesRanked: json['fashion_priorities_ranked'] is List
          ? List<String>.from((json['fashion_priorities_ranked'] as List).map((e) => e.toString()))
          : const ['comfort', 'appearance', 'practicality', 'formality', 'trendiness'],
      fashionPriorityWeights: parsedPriorityWeights,
      preferredBrands: json['preferred_brands'] is List
          ? List<String>.from((json['preferred_brands'] as List).map((e) => e.toString()))
          : const [],
      avoidedBrands: json['avoided_brands'] is List
          ? List<String>.from((json['avoided_brands'] as List).map((e) => e.toString()))
          : const [],
      budgetTier: json['budget_tier']?.toString() ?? 'Mid-range',
      personalStyleProfile: json['personal_style_profile'] is Map<String, dynamic>
          ? json['personal_style_profile'] as Map<String, dynamic>
          : null,
      personalizationVersion: json['personalization_version'] is int
          ? json['personalization_version'] as int
          : 1,
      aiPersonalizationEnabled: json['ai_personalization_enabled'] != false,
    );
  }

  /// Deterministic profile completion calculation (0 - 100%)
  int calculateCompletionPercentage() {
    int score = 0;
    // 1. Identity & Demographics (15%)
    if (displayName.trim().isNotEmpty) score += 10;
    if (age != null || (location != null && location!.trim().isNotEmpty)) score += 5;
    
    // 2. Physical attributes (15%)
    if (heightCm != null || weightKg != null || (bodyType != null && bodyType!.isNotEmpty)) score += 15;
    
    // 3. Style (Primary & Secondary) (15%)
    if (primaryStyle.isNotEmpty || stylePreferences.isNotEmpty) score += 15;
    
    // 4. Fit Preferences (10%)
    if (primaryFit.isNotEmpty || fitPreference.isNotEmpty) score += 10;
    
    // 5. Color Palette & Openness (15%)
    if (preferredColors.isNotEmpty || neutralColors.isNotEmpty) score += 15;
    
    // 6. Occasions & Top Occasions (10%)
    if (occasions.isNotEmpty || topOccasions.isNotEmpty) score += 10;
    
    // 7. Lifestyle & Routine (10%)
    if (lifestyle.isNotEmpty) score += 10;
    
    // 8. Comfort/Appearance trade-off & Fashion Priorities (10%)
    if (fashionPrioritiesRanked.isNotEmpty || priorities.isNotEmpty) score += 10;
    
    return score.clamp(0, 100);
  }

  /// Deterministic summary text generation (mirroring backend service)
  String generateDeterministicSummary() {
    final sProfile = personalStyleProfile;
    if (sProfile != null && sProfile['summary_text'] is String && (sProfile['summary_text'] as String).isNotEmpty) {
      return sProfile['summary_text'] as String;
    }

    final pStyle = primaryStyle.isNotEmpty ? primaryStyle : 'Casual';
    final pFit = primaryFit.isNotEmpty ? primaryFit : 'Regular';
    final buffer = StringBuffer();
    buffer.write('Your profile leans toward $pStyle outfits with ${pFit.toLowerCase()} fits.');
    if (preferredColors.isNotEmpty) {
      buffer.write(' You favor ${preferredColors.length} preferred shades.');
    }
    if (comfortAppearanceScore < 0.4) {
      buffer.write(' You strongly prioritize comfort and ease of movement in daily wear.');
    } else if (comfortAppearanceScore > 0.6) {
      buffer.write(' You prioritize sharp visual appearance and statement styling.');
    } else {
      buffer.write(' You maintain an equal balance between all-day comfort and sharp presentation.');
    }
    if (topOccasions.isNotEmpty) {
      buffer.write(' You dress most frequently for ${topOccasions.take(3).join(', ')}.');
    }
    return buffer.toString();
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
        primaryStyle,
        secondaryStyles,
        fitPreference,
        primaryFit,
        secondaryFit,
        preferredColors,
        dislikedColors,
        neutralColors,
        colorsToExperiment,
        colorExperimentationScore,
        occasions,
        topOccasions,
        occasionFrequencies,
        lifestyle,
        comfortAppearanceScore,
        experimentationScore,
        priorities,
        fashionPrioritiesRanked,
        fashionPriorityWeights,
        preferredBrands,
        avoidedBrands,
        budgetTier,
        personalStyleProfile,
        personalizationVersion,
        aiPersonalizationEnabled,
      ];

  // Standard Constants
  static const List<Map<String, String>> availableStyles = [
    {'id': 'Casual', 'label': 'Casual'},
    {'id': 'Smart Casual', 'label': 'Smart Casual'},
    {'id': 'Minimal', 'label': 'Minimal'},
    {'id': 'Streetwear', 'label': 'Streetwear'},
    {'id': 'Formal', 'label': 'Formal'},
    {'id': 'Classic', 'label': 'Classic'},
    {'id': 'Sporty', 'label': 'Sporty'},
    {'id': 'Traditional', 'label': 'Traditional'},
    {'id': 'Trendy', 'label': 'Trendy'},
    {'id': 'Experimental', 'label': 'Experimental'},
  ];

  static const List<Map<String, dynamic>> experimentationLevels = [
    {'score': 0.0, 'label': 'Very Safe'},
    {'score': 0.25, 'label': 'Mostly Classic'},
    {'score': 0.5, 'label': 'Balanced'},
    {'score': 0.75, 'label': 'Somewhat Experimental'},
    {'score': 1.0, 'label': 'Very Experimental'},
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

  static const List<Map<String, dynamic>> neutralColorsList = [
    {'hex': '#000000', 'name': 'Black', 'color': 0xFF000000},
    {'hex': '#FFFFFF', 'name': 'White', 'color': 0xFFFFFFFF},
    {'hex': '#6B7280', 'name': 'Grey', 'color': 0xFF6B7280},
    {'hex': '#1E3A8A', 'name': 'Navy', 'color': 0xFF1E3A8A},
    {'hex': '#E5E7EB', 'name': 'Beige', 'color': 0xFFE5E7EB},
    {'hex': '#78350F', 'name': 'Tan / Camel', 'color': 0xFF78350F},
  ];

  static const List<Map<String, String>> availableOccasions = [
    {'id': 'College', 'label': 'College'},
    {'id': 'Office', 'label': 'Office'},
    {'id': 'Presentation', 'label': 'Presentation'},
    {'id': 'Interview', 'label': 'Interview'},
    {'id': 'Gym', 'label': 'Gym'},
    {'id': 'Travel', 'label': 'Travel'},
    {'id': 'Party', 'label': 'Party'},
    {'id': 'Date', 'label': 'Date'},
    {'id': 'Wedding', 'label': 'Wedding'},
    {'id': 'Family function', 'label': 'Family function'},
    {'id': 'Casual outing', 'label': 'Casual outing'},
    {'id': 'Formal event', 'label': 'Formal event'},
    {'id': 'Photography/content creation', 'label': 'Content creation'},
    {'id': 'Other', 'label': 'Other'},
  ];

  static const List<Map<String, String>> availableLifestyle = [
    {'id': 'College', 'label': 'College'},
    {'id': 'Work', 'label': 'Work'},
    {'id': 'Gym', 'label': 'Gym / Fitness'},
    {'id': 'Travel', 'label': 'Travel'},
    {'id': 'Sports', 'label': 'Sports'},
    {'id': 'Social events', 'label': 'Social events'},
    {'id': 'Outdoor activities', 'label': 'Outdoor activities'},
    {'id': 'Indoor activities', 'label': 'Indoor activities'},
    {'id': 'Content creation', 'label': 'Content creation'},
    {'id': 'Clubs/events', 'label': 'Clubs / Nightlife'},
  ];

  static const List<Map<String, String>> standardRankedPriorities = [
    {'key': 'comfort', 'label': 'Comfort'},
    {'key': 'appearance', 'label': 'Appearance'},
    {'key': 'color_coordination', 'label': 'Color Coordination'},
    {'key': 'occasion_suitability', 'label': 'Occasion Suitability'},
    {'key': 'practicality', 'label': 'Practicality'},
    {'key': 'trendiness', 'label': 'Trendiness'},
    {'key': 'uniqueness', 'label': 'Uniqueness'},
    {'key': 'weather_suitability', 'label': 'Weather Suitability'},
  ];

  static const List<String> budgetTierOptions = [
    'Budget',
    'Mid-range',
    'Premium',
    'No preference',
  ];
}
