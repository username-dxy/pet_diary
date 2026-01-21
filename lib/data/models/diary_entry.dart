import 'package:equatable/equatable.dart';

/// 日记条目
class DiaryEntry extends Equatable {
  final String id;
  final String petId;
  final DateTime date;
  final String content;              // 日记内容（AI生成）
  final bool isLocked;               // 是否锁定
  final String? emotionRecordId;     // 关联的情绪记录ID
  final DateTime createdAt;

  const DiaryEntry({
    required this.id,
    required this.petId,
    required this.date,
    required this.content,
    this.isLocked = false,
    this.emotionRecordId,
    required this.createdAt,
  });

  /// 从JSON创建
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      petId: json['petId'] as String,
      date: DateTime.parse(json['date'] as String),
      content: json['content'] as String,
      isLocked: json['isLocked'] as bool? ?? false,
      emotionRecordId: json['emotionRecordId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'date': date.toIso8601String(),
      'content': content,
      'isLocked': isLocked,
      'emotionRecordId': emotionRecordId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改
  DiaryEntry copyWith({
    String? content,
    bool? isLocked,
  }) {
    return DiaryEntry(
      id: id,
      petId: petId,
      date: date,
      content: content ?? this.content,
      isLocked: isLocked ?? this.isLocked,
      emotionRecordId: emotionRecordId,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, date, content, isLocked];
}