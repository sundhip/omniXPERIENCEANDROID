import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:omnipresence/features/profile/models/user_profile_model.dart';
import 'package:omnipresence/features/profile/profile_bloc.dart';
import 'package:omnipresence/features/profile/profile_repository.dart';
import 'package:omnipresence/core/network/api_client.dart';

class FakeProfileRepository extends ProfileRepository {
  UserProfileModel _profile;

  FakeProfileRepository({required UserProfileModel initialProfile})
      : _profile = initialProfile,
        super(apiClient: ApiClient());

  @override
  Future<UserProfileModel> getFullProfile() async {
    return _profile;
  }

  @override
  Future<UserProfileModel> updateFullProfile(UserProfileModel profile) async {
    _profile = profile;
    return _profile;
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('UserProfileModel Tests', () {
    test('calculateCompletionPercentage calculates deterministically', () {
      const emptyProfile = UserProfileModel(
        displayName: '',
        fitPreference: '',
        priorities: {},
      );
      expect(emptyProfile.calculateCompletionPercentage(), equals(0));

      const minimalProfile = UserProfileModel(displayName: 'Test User');
      final minimalPct = minimalProfile.calculateCompletionPercentage();
      expect(minimalPct, equals(35)); // Name (15) + Default Fit (10) + Priorities (10)

      const fullProfile = UserProfileModel(
        displayName: 'Alice Designer',
        age: 28,
        gender: 'Female',
        location: 'San Francisco',
        heightCm: 168.0,
        weightKg: 58.0,
        bodyType: 'Athletic',
        stylePreferences: ['Minimal', 'Smart Casual'],
        fitPreference: 'Relaxed',
        preferredColors: ['#1E3A8A', '#FFFFFF'],
        dislikedColors: ['#FFFF00'],
        occasions: ['Office', 'Casual Outing'],
        lifestyle: ['Work', 'Gym'],
        priorities: {'comfort': 0.8, 'appearance': 0.9},
      );
      final fullPct = fullProfile.calculateCompletionPercentage();
      expect(fullPct, equals(100)); // All sections filled
    });

    test('toJson and fromJson preserves all attributes', () {
      const original = UserProfileModel(
        id: 'prof_123',
        userId: 'user_456',
        displayName: 'Bob Builder',
        email: 'bob@example.com',
        age: 32,
        gender: 'Male',
        location: 'New York',
        heightCm: 180.0,
        weightKg: 78.5,
        bodyType: 'Broad',
        onboardingCompleted: true,
        stylePreferences: ['Streetwear', 'Casual'],
        fitPreference: 'Oversized',
        preferredColors: ['#000000', '#6B7280'],
        dislikedColors: ['#E11D48'],
        occasions: ['College', 'Party'],
        lifestyle: ['Work', 'Travel'],
        priorities: {'comfort': 0.9, 'trendiness': 0.7},
      );

      final jsonMap = original.toJson();
      final reconstructed = UserProfileModel.fromJson(jsonMap);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.userId, equals(original.userId));
      expect(reconstructed.displayName, equals(original.displayName));
      expect(reconstructed.email, equals(original.email));
      expect(reconstructed.age, equals(original.age));
      expect(reconstructed.heightCm, equals(original.heightCm));
      expect(reconstructed.weightKg, equals(original.weightKg));
      expect(reconstructed.bodyType, equals(original.bodyType));
      expect(reconstructed.onboardingCompleted, isTrue);
      expect(reconstructed.stylePreferences, equals(original.stylePreferences));
      expect(reconstructed.fitPreference, equals(original.fitPreference));
      expect(reconstructed.preferredColors, equals(original.preferredColors));
      expect(reconstructed.dislikedColors, equals(original.dislikedColors));
      expect(reconstructed.occasions, equals(original.occasions));
      expect(reconstructed.lifestyle, equals(original.lifestyle));
      expect(reconstructed.priorities['comfort'], equals(0.9));
    });
  });

  group('ProfileBloc Unit Tests', () {
    late FakeProfileRepository repo;
    late ProfileBloc bloc;
    const testProfile = UserProfileModel(
      id: 'prof_1',
      displayName: 'Alex Chen',
      stylePreferences: ['Minimal'],
      fitPreference: 'Regular',
    );

    setUp(() {
      repo = FakeProfileRepository(initialProfile: testProfile);
      bloc = ProfileBloc(repository: repo);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is ProfileInitial', () {
      expect(bloc.state, isA<ProfileInitial>());
    });

    test('LoadProfileRequested emits ProfileLoading then ProfileLoaded', () async {
      final expectedStates = [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>().having((s) => s.profile.displayName, 'displayName', 'Alex Chen'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(LoadProfileRequested());
    });

    test('UpdateProfileRequested emits ProfileUpdating then ProfileLoaded with message', () async {
      final updatedProfile = testProfile.copyWith(
        displayName: 'Alexander Chen',
        stylePreferences: ['Minimal', 'Smart Casual'],
      );

      final expectedStates = [
        isA<ProfileUpdating>(),
        isA<ProfileLoaded>()
            .having((s) => s.profile.displayName, 'displayName', 'Alexander Chen')
            .having((s) => s.successMessage, 'successMessage', contains('successfully')),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(UpdateProfileRequested(updatedProfile));
    });

    test('SaveOnboardingProfileRequested sets onboardingCompleted and emits ProfileLoaded', () async {
      final onboardingProfile = testProfile.copyWith(displayName: 'Alex Onboarded');

      final expectedStates = [
        isA<ProfileUpdating>(),
        isA<ProfileLoaded>()
            .having((s) => s.profile.onboardingCompleted, 'onboardingCompleted', isTrue)
            .having((s) => s.profile.displayName, 'displayName', 'Alex Onboarded'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(SaveOnboardingProfileRequested(onboardingProfile));
    });

    test('ResetProfileRequested resets state to ProfileInitial', () async {
      bloc.emit(const ProfileLoaded(profile: testProfile));
      expectLater(bloc.stream, emits(isA<ProfileInitial>()));
      bloc.add(ResetProfileRequested());
    });
  });
}
