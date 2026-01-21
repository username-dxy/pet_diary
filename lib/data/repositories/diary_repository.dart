import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/diary_entry.dart';

/// 日记仓库
class DiaryRepository {
  static const String _key = 'diary_entries';

  /// 获取所有日记
  Future<List<DiaryEntry>> getAllEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map((json) => DiaryEntry.fromJson(json as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // 按日期倒序
  }

  /// 获取特定日期的日记
  Future<DiaryEntry?> getEntryByDate(DateTime date) async {
    final entries = await getAllEntries();
    try {
      return entries.firstWhere(
        (entry) =>
            entry.date.year == date.year &&
            entry.date.month == date.month &&
            entry.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }

  /// 获取最近N条日记
  Future<List<DiaryEntry>> getRecentEntries({int limit = 30}) async {
    final entries = await getAllEntries();
    return entries.take(limit).toList();
  }

  /// 保存日记
  Future<void> saveEntry(DiaryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getAllEntries();

    // 移除同一天的旧日记
    entries.removeWhere(
      (e) =>
          e.date.year == entry.date.year &&
          e.date.month == entry.date.month &&
          e.date.day == entry.date.day,
    );

    // 添加新日记
    entries.add(entry);

    // 保存
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }

  /// 删除日记
  Future<void> deleteEntry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getAllEntries();

    entries.removeWhere((e) => e.id == id);

    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }

  /// 获取日记总数
  Future<int> getEntryCount() async {
    final entries = await getAllEntries();
    return entries.length;
  }
}
