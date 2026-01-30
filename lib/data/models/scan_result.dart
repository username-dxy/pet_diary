import 'package:equatable/equatable.dart';

/// Result of a background pet photo scan
class ScanResult extends Equatable {
  final String assetId;
  final String tempFilePath;
  final DateTime? creationDate;
  final double? latitude;
  final double? longitude;
  final String animalType;
  final double confidence;

  const ScanResult({
    required this.assetId,
    required this.tempFilePath,
    this.creationDate,
    this.latitude,
    this.longitude,
    required this.animalType,
    required this.confidence,
  });

  factory ScanResult.fromMap(Map<dynamic, dynamic> map) {
    return ScanResult(
      assetId: map['assetId'] as String,
      tempFilePath: map['tempFilePath'] as String,
      creationDate: map['creationDate'] != null
          ? DateTime.parse(map['creationDate'] as String)
          : null,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      animalType: map['animalType'] as String,
      confidence: (map['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'tempFilePath': tempFilePath,
      'creationDate': creationDate?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'animalType': animalType,
      'confidence': confidence,
    };
  }

  ScanResult copyWith({
    String? assetId,
    String? tempFilePath,
    DateTime? creationDate,
    double? latitude,
    double? longitude,
    String? animalType,
    double? confidence,
  }) {
    return ScanResult(
      assetId: assetId ?? this.assetId,
      tempFilePath: tempFilePath ?? this.tempFilePath,
      creationDate: creationDate ?? this.creationDate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      animalType: animalType ?? this.animalType,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  List<Object?> get props => [
        assetId,
        tempFilePath,
        creationDate,
        latitude,
        longitude,
        animalType,
        confidence,
      ];
}
