import 'package:pet_diary/data/models/emotion_record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 情绪记录仓库
class EmotionRepository {
  static const String _key = 'emotion_records';

  /// 获取今日记录
  Future<EmotionRecord?> getTodayRecord() async {
    final today = DateTime.now();
    final records = await getMonthRecords(today.year, today.month);
    
    final dateKey = DateTime(today.year, today.month, today.day);
    return records[dateKey];
  }

  /// 获取月度记录
  Future<Map<DateTime, EmotionRecord>> getMonthRecords(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    
    if (jsonString == null) return {};

    final List<dynamic> jsonList = json.decode(jsonString);
    final allRecords = jsonList
        .map((json) => EmotionRecord.fromJson(json as Map<String, dynamic>))
        .toList();

    // 过滤当月记录
    final monthRecords = <DateTime, EmotionRecord>{};
    for (var record in allRecords) {
      if (record.date.year == year && record.date.month == month) {
        final dateKey = DateTime(record.date.year, record.date.month, record.date.day);
        monthRecords[dateKey] = record;
      }
    }

    return monthRecords;
  }

  /// 保存记录
  Future<void> saveRecord(EmotionRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    
    List<EmotionRecord> allRecords = [];
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      allRecords = jsonList
          .map((json) => EmotionRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    // 移除同一天的旧记录（一天只能有一条）
    allRecords.removeWhere((r) =>
        r.date.year == record.date.year &&
        r.date.month == record.date.month &&
        r.date.day == record.date.day);

    // 添加新记录
    allRecords.add(record);

    // 保存
    final jsonList = allRecords.map((r) => r.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }

  /// 删除记录
  Future<void> deleteRecord(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    
    if (jsonString == null) return;

    final List<dynamic> jsonList = json.decode(jsonString);
    final allRecords = jsonList
        .map((json) => EmotionRecord.fromJson(json as Map<String, dynamic>))
        .toList();

    allRecords.removeWhere((r) => r.id == recordId);

    final newJsonList = allRecords.map((r) => r.toJson()).toList();
    await prefs.setString(_key, json.encode(newJsonList));
  }
}