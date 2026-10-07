import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:omnipresence/features/profile/models/visual_profile_model.dart';
import 'package:omnipresence/features/profile/models/user_profile_model.dart';
import 'package:omnipresence/features/profile/visual_profile_bloc.dart';
import 'package:omnipresence/features/profile/visual_profile_repository.dart';
import 'package:omnipresence/core/network/api_client.dart';

class FakeVisualProfileRepository extends VisualProfileRepository {
  VisualProfileModel? _stored;

  FakeVisualProfileRepository({VisualProfileModel? initial})
      : _stored = initial,
        super(apiClient: ApiClient());

  @override
  Future<VisualProfileModel?> getVisualProfile() async {
    return _stored;
  }

  @override
  Future<VisualProfileModel> analyzeImage(String filePath) async {
    const result = VisualProfileModel(
      id: 'vp-test-1',
      userId: 'user-1',
      faceDetected: true,
      faceCount: 1,
      imageQualityPassed: true,
      detectedFaceShape: 'Oval',
      faceShapeConfidence: 0.88,
      faceProportions: {'length_to_width': 1.35, 'jaw_to_forehead': 0.85},
      detectedSkinTone: 'Medium',
      skinToneConfidence: 0.91,
      skinToneHex: '#B5835A',
      skinItaAngle: 24.5,
      detectedUndertone: 'Warm',
      detectedHairType: 'Wavy',
      hairConfidence: 0.82,
      isConfirmed: false,
    );
    _stored = result;
    return result;
  }

  @override
  Future<VisualProfileModel> confirmVisualProfile({
    String? confirmedFaceShape,
    String? confirmedSkinTone,
    String? confirmedUndertone,
    String? confirmedHairType,
    String? hairColor,
  }) async {
    final current = _stored ?? const VisualProfileModel();
    final updated = current.copyWith(
      confirmedFaceShape: confirmedFaceShape,
      confirmedSkinTone: confirmedSkinTone,
      confirmedUndertone: confirmedUndertone,
      confirmedHairType: confirmedHairType,
      isConfirmed: true,
    );
    _stored = updated;
    return updated;
  }

  @override
  Future<void> deleteVisualProfile() async {
    _stored = null;
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('VisualProfileModel Tests', () {
    test('JSON serialization & deserialization works accurately', () {
      const model = VisualProfileModel(
        id: 'test-vp-1',
        userId: 'user-42',
        faceDetected: true,
        faceCount: 1,
        imageQualityPassed: true,
        detectedFaceShape: 'Oval',
        confirmedFaceShape: 'Heart',
        faceShapeConfidence: 0.89,
        faceProportions: {'length_to_width': 1.34},
        detectedSkinTone: 'Medium',
        confirmedSkinTone: 'Tan',
        skinToneConfidence: 0.92,
        skinToneHex: '#B5835A',
        skinItaAngle: 25.4,
        detectedUndertone: 'Neutral',
        confirmedUndertone: 'Warm',
        detectedHairType: 'Wavy',
        confirmedHairType: 'Curly',
        hairConfidence: 0.84,
        isConfirmed: true,
      );

      final json = model.toJson();
      final roundtrip = VisualProfileModel.fromJson(json);

      expect(roundtrip.id, equals('test-vp-1'));
      expect(roundtrip.faceDetected, isTrue);
      expect(roundtrip.faceCount, equals(1));
      // Confirmed values override detected values for display
      expect(roundtrip.displayFaceShape, equals('Heart'));
      expect(roundtrip.displaySkinTone, equals('Tan'));
      expect(roundtrip.displayUndertone, equals('Warm'));
      expect(roundtrip.displayHairType, equals('Curly'));
      expect(roundtrip.skinToneColor, isNotNull);
      expect(roundtrip.visualSummary, contains('Heart face'));
      expect(roundtrip.visualSummary, contains('Tan'));
      expect(roundtrip.visualSummary, contains('Curly hair'));
    });

    test('Falls back to detected when confirmed values are null', () {
      const model = VisualProfileModel(
        faceDetected: true,
        detectedFaceShape: 'Round',
        detectedSkinTone: 'Light',
        detectedUndertone: 'Cool',
        detectedHairType: 'Straight',
      );

      expect(model.displayFaceShape, equals('Round'));
      expect(model.displaySkinTone, equals('Light'));
      expect(model.displayUndertone, equals('Cool'));
      expect(model.displayHairType, equals('Straight'));
    });

    test('Integrates seamlessly into UserProfileModel', () {
      const vp = VisualProfileModel(
        faceDetected: true,
        detectedFaceShape: 'Oval',
        detectedSkinTone: 'Medium',
        detectedUndertone: 'Warm',
        detectedHairType: 'Wavy',
        isConfirmed: true,
      );

      const profile = UserProfileModel(
        displayName: 'Test User',
        visualProfile: vp,
      );

      final summary = profile.generateDeterministicSummary();
      expect(summary, contains('Visual appearance:'));
      expect(summary, contains('Oval face'));

      final json = profile.toJson();
      expect(json['visual_profile'], isNotNull);
      final fromJson = UserProfileModel.fromJson(json);
      expect(fromJson.visualProfile, isNotNull);
      expect(fromJson.visualProfile!.displayFaceShape, equals('Oval'));
    });
  });

  group('VisualProfileBloc Tests', () {
    test('Initial -> Analyze -> Review -> Confirm flow works', () async {
      final repo = FakeVisualProfileRepository();
      final bloc = VisualProfileBloc(repository: repo);

      expect(bloc.state, isA<VisualProfileInitial>());

      bloc.add(const AnalyzeVisualProfileEvent(imagePath: '/mock/path/selfie.jpg'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<VisualProfileAnalyzing>(),
          predicate<VisualProfileReviewing>((state) =>
              state.analyzedProfile.detectedFaceShape == 'Oval' &&
              state.analyzedProfile.detectedSkinTone == 'Medium'),
        ]),
      );

      // Confirm with manual override on hair type
      bloc.add(const ConfirmVisualProfileEvent(
        faceShape: 'Oval',
        skinTone: 'Medium',
        undertone: 'Warm',
        hairType: 'Curly', // overridden
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<VisualProfileLoading>(),
          predicate<VisualProfileLoaded>((state) =>
              state.profile.isConfirmed == true &&
              state.profile.displayHairType == 'Curly'),
        ]),
      );

      // Delete flow
      bloc.add(DeleteVisualProfileEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<VisualProfileLoading>(),
          isA<VisualProfileInitial>(),
        ]),
      );

      bloc.close();
    });
  });
}
