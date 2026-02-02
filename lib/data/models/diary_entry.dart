import 'package:equatable/equatable.dart';

/// 日记条目
class DiaryEntry extends Equatable {
  final String id;
  final String petId;
  final DateTime date;
  final String content;
  final String? imagePath;
  final List<String> imageUrls;
  final bool isLocked;
  final String? emotionRecordId;
  final DateTime createdAt;

  const DiaryEntry({
    required this.id,
    required this.petId,
    required this.date,
    required this.content,
    this.imagePath,
    this.imageUrls = const [],
    this.isLocked = false,
    this.emotionRecordId,
    required this.createdAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    final rawImageUrls = json['imageUrls'] as List<dynamic>?;
    return DiaryEntry(
      id: json['id'] as String,
      petId: json['petId'] as String,
      date: DateTime.parse(json['date'] as String),
      content: json['content'] as String,
      imagePath: json['imagePath'] as String?,
      imageUrls: rawImageUrls?.map((e) => e.toString()).toList() ?? const [],
      isLocked: json['isLocked'] as bool? ?? false,
      emotionRecordId: json['emotionRecordId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'date': date.toIso8601String(),
      'content': content,
      'imagePath': imagePath,
      'imageUrls': imageUrls,
      'isLocked': isLocked,
      'emotionRecordId': emotionRecordId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  DiaryEntry copyWith({
    String? content,
    String? imagePath,
    List<String>? imageUrls,
    bool? isLocked,
  }) {
    return DiaryEntry(
      id: id,
      petId: petId,
      date: date,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      imageUrls: imageUrls ?? this.imageUrls,
      isLocked: isLocked ?? this.isLocked,
      emotionRecordId: emotionRecordId,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, date, content, imagePath, imageUrls, isLocked];
}
