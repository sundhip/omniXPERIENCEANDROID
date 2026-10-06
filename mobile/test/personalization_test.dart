import 'package:flutter_test/flutter_test.dart';
import 'package:omnipresence/features/profile/models/user_profile_model.dart';

void main() {
  group('Phase 2 Personalization Tests', () {
    test('Personal style profile model serialization and deserialization', () {
      const model = UserProfileModel(
        id: 'prof_test_1',
        userId: 'usr_test_1',
        displayName: 'Jordan Vane',
        primaryStyle: 'Smart Casual',
        secondaryStyles: ['Minimal', 'Classic'],
        primaryFit: 'Relaxed',
        secondaryFit: 'Regular',
        preferredColors: ['#1E3A8A', '#FFFFFF', '#000000'],
        neutralColors: ['#6B7280', '#E5E7EB'],
        dislikedColors: ['#F59E0B'],
        colorsToExperiment: ['#881337'],
        colorExperimentationScore: 0.70,
        occasions: ['Office', 'College', 'Party'],
        topOccasions: ['Office', 'College'],
        occasionFrequencies: {
          'casual': 0.90,
          'smart_casual': 0.80,
          'formal': 0.25,
          'sportswear': 0.40,
        },
        lifestyle: ['Work', 'Gym', 'Travel'],
        comfortAppearanceScore: 0.35,
        experimentationScore: 0.75,
        fashionPrioritiesRanked: ['comfort', 'appearance', 'practicality', 'trendiness'],
        fashionPriorityWeights: {
          'comfort': 1.0,
          'appearance': 0.73,
          'practicality': 0.47,
          'trendiness': 0.20,
        },
        preferredBrands: ['Uniqlo', 'Zara'],
        budgetTier: 'Mid-range',
        personalStyleProfile: {
          'version': 1,
          'primary_style': 'Smart Casual',
          'summary_text': 'Your profile leans toward Smart Casual outfits with relaxed fits.',
        },
      );

      final json = model.toJson();
      final restored = UserProfileModel.fromJson(json);

      expect(restored.primaryStyle, equals('Smart Casual'));
      expect(restored.secondaryStyles, equals(['Minimal', 'Classic']));
      expect(restored.primaryFit, equals('Relaxed'));
      expect(restored.secondaryFit, equals('Regular'));
      expect(restored.colorExperimentationScore, equals(0.70));
      expect(restored.comfortAppearanceScore, equals(0.35));
      expect(restored.experimentationScore, equals(0.75));
      expect(restored.fashionPrioritiesRanked, equals(['comfort', 'appearance', 'practicality', 'trendiness']));
      expect(restored.fashionPriorityWeights['comfort'], equals(1.0));
      expect(restored.preferredBrands, equals(['Uniqlo', 'Zara']));
      expect(restored.budgetTier, equals('Mid-range'));
      expect(restored.personalStyleProfile?['primary_style'], equals('Smart Casual'));
    });

    test('Deterministic summary text generation', () {
      const model = UserProfileModel(
        displayName: 'Jordan Vane',
        primaryStyle: 'Smart Casual',
        primaryFit: 'Relaxed',
        preferredColors: ['#1E3A8A', '#FFFFFF'],
        topOccasions: ['Office', 'College'],
        comfortAppearanceScore: 0.30,
        experimentationScore: 0.75,
      );

      final summary = model.generateDeterministicSummary();
      expect(summary.contains('Smart Casual'), isTrue);
      expect(summary.toLowerCase().contains('relaxed'), isTrue);
      expect(summary.toLowerCase().contains('comfort'), isTrue);
      expect(summary.contains('Office, College'), isTrue);
    });

    test('calculateCompletionPercentage evaluates all 8 personalization dimensions', () {
      const emptyModel = UserProfileModel(
        displayName: '',
        primaryStyle: '',
        stylePreferences: [],
        primaryFit: '',
        fitPreference: '',
        priorities: {},
        fashionPrioritiesRanked: [],
      );
      expect(emptyModel.calculateCompletionPercentage(), equals(0));

      const fullModel = UserProfileModel(
        displayName: 'Jordan Vane',
        age: 28,
        location: 'San Francisco',
        heightCm: 180.0,
        weightKg: 75.0,
        bodyType: 'Athletic',
        primaryStyle: 'Smart Casual',
        stylePreferences: ['Smart Casual', 'Minimal'],
        primaryFit: 'Relaxed',
        fitPreference: 'Relaxed',
        preferredColors: ['#1E3A8A', '#FFFFFF'],
        neutralColors: ['#6B7280'],
        occasions: ['Office', 'College'],
        topOccasions: ['Office'],
        lifestyle: ['Work', 'Gym'],
        comfortAppearanceScore: 0.40,
        experimentationScore: 0.75,
        fashionPrioritiesRanked: ['comfort', 'appearance', 'practicality'],
        priorities: {'comfort': 1.0, 'appearance': 0.75},
      );
      expect(fullModel.calculateCompletionPercentage(), equals(100));
    });
  });
}
