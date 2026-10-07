import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class VisualProfileModel extends Equatable {
  final String id;
  final String userId;
  final bool faceDetected;
  final int faceCount;
  final bool imageQualityPassed;
  final List<String> qualityIssues;

  // Face Shape
  final String detectedFaceShape;
  final String? confirmedFaceShape;
  final double faceShapeConfidence;
  final Map<String, double> faceProportions;

  // Skin Tone & Undertone
  final String detectedSkinTone;
  final String? confirmedSkinTone;
  final double skinToneConfidence;
  final String? skinToneHex;
  final double? skinItaAngle;
  final String detectedUndertone;
  final String? confirmedUndertone;

  // Hair Analysis
  final String detectedHairType;
  final String? confirmedHairType;
  final double hairConfidence;
  final String? hairColor;

  // Confirmation & Metadata
  final bool isConfirmed;
  final bool hasImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VisualProfileModel({
    this.id = '',
    this.userId = '',
    this.faceDetected = false,
    this.faceCount = 0,
    this.imageQualityPassed = true,
    this.qualityIssues = const [],
    this.detectedFaceShape = 'Unknown',
    this.confirmedFaceShape,
    this.faceShapeConfidence = 0.0,
    this.faceProportions = const {},
    this.detectedSkinTone = 'Unknown',
    this.confirmedSkinTone,
    this.skinToneConfidence = 0.0,
    this.skinToneHex,
    this.skinItaAngle,
    this.detectedUndertone = 'Unknown',
    this.confirmedUndertone,
    this.detectedHairType = 'Unknown',
    this.confirmedHairType,
    this.hairConfidence = 0.0,
    this.hairColor,
    this.isConfirmed = false,
    this.hasImage = false,
    this.createdAt,
    this.updatedAt,
  });

  // Display getters prioritizing confirmed user values over algorithmic predictions
  String get displayFaceShape =>
      (confirmedFaceShape != null && confirmedFaceShape!.trim().isNotEmpty)
          ? confirmedFaceShape!
          : detectedFaceShape;

  String get displaySkinTone =>
      (confirmedSkinTone != null && confirmedSkinTone!.trim().isNotEmpty)
          ? confirmedSkinTone!
          : detectedSkinTone;

  String get displayUndertone =>
      (confirmedUndertone != null && confirmedUndertone!.trim().isNotEmpty)
          ? confirmedUndertone!
          : detectedUndertone;

  String get displayHairType =>
      (confirmedHairType != null && confirmedHairType!.trim().isNotEmpty)
          ? confirmedHairType!
          : detectedHairType;

  Color? get skinToneColor {
    if (skinToneHex == null || skinToneHex!.isEmpty) return null;
    try {
      final hex = skinToneHex!.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return null;
  }

  String get visualSummary {
    if (!faceDetected) return 'No face detected yet.';
    final buffer = StringBuffer();
    buffer.write('$displayFaceShape face');
    if (displaySkinTone != 'Unknown') {
      buffer.write(' • $displaySkinTone');
      if (displayUndertone != 'Unknown') {
        buffer.write(' ($displayUndertone undertone)');
      }
    }
    if (displayHairType != 'Unknown') {
      buffer.write(' • $displayHairType hair');
    }
    return buffer.toString();
  }

  VisualProfileModel copyWith({
    String? id,
    String? userId,
    bool? faceDetected,
    int? faceCount,
    bool? imageQualityPassed,
    List<String>? qualityIssues,
    String? detectedFaceShape,
    String? confirmedFaceShape,
    double? faceShapeConfidence,
    Map<String, double>? faceProportions,
    String? detectedSkinTone,
    String? confirmedSkinTone,
    double? skinToneConfidence,
    String? skinToneHex,
    double? skinItaAngle,
    String? detectedUndertone,
    String? confirmedUndertone,
    String? detectedHairType,
    String? confirmedHairType,
    double? hairConfidence,
    String? hairColor,
    bool? isConfirmed,
    bool? hasImage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VisualProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      faceDetected: faceDetected ?? this.faceDetected,
      faceCount: faceCount ?? this.faceCount,
      imageQualityPassed: imageQualityPassed ?? this.imageQualityPassed,
      qualityIssues: qualityIssues ?? this.qualityIssues,
      detectedFaceShape: detectedFaceShape ?? this.detectedFaceShape,
      confirmedFaceShape: confirmedFaceShape ?? this.confirmedFaceShape,
      faceShapeConfidence: faceShapeConfidence ?? this.faceShapeConfidence,
      faceProportions: faceProportions ?? this.faceProportions,
      detectedSkinTone: detectedSkinTone ?? this.detectedSkinTone,
      confirmedSkinTone: confirmedSkinTone ?? this.confirmedSkinTone,
      skinToneConfidence: skinToneConfidence ?? this.skinToneConfidence,
      skinToneHex: skinToneHex ?? this.skinToneHex,
      skinItaAngle: skinItaAngle ?? this.skinItaAngle,
      detectedUndertone: detectedUndertone ?? this.detectedUndertone,
      confirmedUndertone: confirmedUndertone ?? this.confirmedUndertone,
      detectedHairType: detectedHairType ?? this.detectedHairType,
      confirmedHairType: confirmedHairType ?? this.confirmedHairType,
      hairConfidence: hairConfidence ?? this.hairConfidence,
      hairColor: hairColor ?? this.hairColor,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      hasImage: hasImage ?? this.hasImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'face_detected': faceDetected,
      'face_count': faceCount,
      'image_quality_passed': imageQualityPassed,
      'quality_issues': qualityIssues,
      'detected_face_shape': detectedFaceShape,
      'confirmed_face_shape': confirmedFaceShape,
      'face_shape_confidence': faceShapeConfidence,
      'face_proportions': faceProportions,
      'detected_skin_tone': detectedSkinTone,
      'confirmed_skin_tone': confirmedSkinTone,
      'skin_tone_confidence': skinToneConfidence,
      'skin_tone_hex': skinToneHex,
      'skin_ita_angle': skinItaAngle,
      'detected_undertone': detectedUndertone,
      'confirmed_undertone': confirmedUndertone,
      'detected_hair_type': detectedHairType,
      'confirmed_hair_type': confirmedHairType,
      'hair_confidence': hairConfidence,
      'hair_color': hairColor,
      'is_confirmed': isConfirmed,
      'has_image': hasImage,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory VisualProfileModel.fromJson(Map<String, dynamic> json) {
    Map<String, double> parsedProportions = {};
    if (json['face_proportions'] != null && json['face_proportions'] is Map) {
      (json['face_proportions'] as Map).forEach((k, v) {
        if (v is num) parsedProportions[k.toString()] = v.toDouble();
      });
    }

    final imgQuality = json['image_quality'] is Map ? json['image_quality'] as Map : null;
    final hexCode = json['skin_tone_hex']?.toString() ?? imgQuality?['skin_tone_hex']?.toString();
    final itaAngle = (json['skin_ita_angle'] is num ? (json['skin_ita_angle'] as num).toDouble() : null) ??
        (imgQuality?['ita'] is num ? (imgQuality!['ita'] as num).toDouble() : null);

    return VisualProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      faceDetected: json['face_detected'] == true,
      faceCount: json['face_count'] is num ? (json['face_count'] as num).toInt() : 0,
      imageQualityPassed: json['image_quality_passed'] != false,
      qualityIssues: json['quality_issues'] is List
          ? List<String>.from((json['quality_issues'] as List).map((e) => e.toString()))
          : const [],
      detectedFaceShape: json['detected_face_shape']?.toString() ?? 'Unknown',
      confirmedFaceShape: json['confirmed_face_shape']?.toString(),
      faceShapeConfidence: json['face_shape_confidence'] is num
          ? (json['face_shape_confidence'] as num).toDouble()
          : 0.0,
      faceProportions: parsedProportions,
      detectedSkinTone: json['detected_skin_tone']?.toString() ?? 'Unknown',
      confirmedSkinTone: json['confirmed_skin_tone']?.toString(),
      skinToneConfidence: json['skin_tone_confidence'] is num
          ? (json['skin_tone_confidence'] as num).toDouble()
          : 0.0,
      skinToneHex: hexCode,
      skinItaAngle: itaAngle,
      detectedUndertone: json['detected_skin_undertone']?.toString() ?? json['detected_undertone']?.toString() ?? 'Unknown',
      confirmedUndertone: json['confirmed_skin_undertone']?.toString() ?? json['confirmed_undertone']?.toString(),
      detectedHairType: json['detected_hair_texture']?.toString() ?? json['detected_hair_type']?.toString() ?? 'Unknown',
      confirmedHairType: json['confirmed_hair_texture']?.toString() ?? json['confirmed_hair_type']?.toString(),
      hairConfidence: json['hair_confidence'] is num
          ? (json['hair_confidence'] as num).toDouble()
          : 0.0,
      hairColor: json['hair_color']?.toString(),
      isConfirmed: json['confirmed_by_user'] == true || json['is_confirmed'] == true,
      hasImage: json['has_image'] == true || json['source_image_id'] != null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        faceDetected,
        faceCount,
        imageQualityPassed,
        qualityIssues,
        detectedFaceShape,
        confirmedFaceShape,
        faceShapeConfidence,
        faceProportions,
        detectedSkinTone,
        confirmedSkinTone,
        skinToneConfidence,
        skinToneHex,
        skinItaAngle,
        detectedUndertone,
        confirmedUndertone,
        detectedHairType,
        confirmedHairType,
        hairConfidence,
        hairColor,
        isConfirmed,
        hasImage,
        createdAt,
        updatedAt,
      ];

  // Domain Constants for Review & Overrides
  static const List<String> availableFaceShapes = [
    'Oval',
    'Round',
    'Square',
    'Oblong',
    'Heart',
    'Diamond',
    'Triangle',
    'Unknown',
  ];

  static const List<String> availableSkinTones = [
    'Very Light',
    'Light',
    'Medium',
    'Tan',
    'Deep',
    'Unknown',
  ];

  static const List<String> availableUndertones = [
    'Warm',
    'Cool',
    'Neutral',
    'Unknown',
  ];

  static const List<String> availableHairTypes = [
    'Straight',
    'Wavy',
    'Curly',
    'Coily',
    'Unknown',
  ];
}
