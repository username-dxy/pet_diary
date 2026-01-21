import 'package:equatable/equatable.dart';

/// App相册中的照片
class AppPhoto extends Equatable {
  final String id;
  final String petId;
  final String localPath;          // 本地文件路径
  final DateTime addedAt;          // 添加到相册的时间
  final DateTime? photoTakenAt;    // 照片拍摄时间（从EXIF读取）
  final String? location;          // 照片拍摄地点（从EXIF读取）
  final double? latitude;          // 纬度
  final double? longitude;         // 经度

  const AppPhoto({
    required this.id,
    required this.petId,
    required this.localPath,
    required this.addedAt,
    this.photoTakenAt,
    this.location,
    this.latitude,
    this.longitude,
  });

  factory AppPhoto.fromJson(Map<String, dynamic> json) {
    return AppPhoto(
      id: json['id'] as String,
      petId: json['petId'] as String,
      localPath: json['localPath'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
      photoTakenAt: json['photoTakenAt'] != null
          ? DateTime.parse(json['photoTakenAt'] as String)
          : null,
      location: json['location'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'localPath': localPath,
      'addedAt': addedAt.toIso8601String(),
      'photoTakenAt': photoTakenAt?.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  AppPhoto copyWith({
    DateTime? photoTakenAt,
    String? location,
    double? latitude,
    double? longitude,
  }) {
    return AppPhoto(
      id: id,
      petId: petId,
      localPath: localPath,
      addedAt: addedAt,
      photoTakenAt: photoTakenAt ?? this.photoTakenAt,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props => [id, localPath, addedAt];
}