import 'package:equatable/equatable.dart';

/// 日记条目
class DiaryEntry extends Equatable {
  final String id;
  final String petId;
  final DateTime date;
  final String content;
  final String? imagePath;           // ← 添加这个字段
  final bool isLocked;
  final String? emotionRecordId;
  final DateTime createdAt;

  const DiaryEntry({
    required this.id,
    required this.petId,
    required this.date,
    required this.content,
    this.imagePath,                  // ← 添加这个参数
    this.isLocked = false,
    this.emotionRecordId,
    required this.createdAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      petId: json['petId'] as String,
      date: DateTime.parse(json['date'] as String),
      content: json['content'] as String,
      imagePath: json['imagePath'] as String?,  // ← 添加这行
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
      'imagePath': imagePath,  // ← 添加这行
      'isLocked': isLocked,
      'emotionRecordId': emotionRecordId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  DiaryEntry copyWith({
    String? content,
    String? imagePath,  // ← 添加这个参数
    bool? isLocked,
  }) {
    return DiaryEntry(
      id: id,
      petId: petId,
      date: date,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,  // ← 添加这行
      isLocked: isLocked ?? this.isLocked,
      emotionRecordId: emotionRecordId,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, date, content, imagePath, isLocked];
}