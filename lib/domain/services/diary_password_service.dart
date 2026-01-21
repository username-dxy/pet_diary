import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// 日记密码管理服务
class DiaryPasswordService {
  static const String _hasEnteredKey = 'diary_has_entered';
  static const String _lastExitTimeKey = 'diary_last_exit_time';
  static const int _sessionTimeoutMinutes = 5; // 5分钟内无需重新输入密码

  /// 记录进入日记本
  Future<void> markEntered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasEnteredKey, true);
    await prefs.setString(_lastExitTimeKey, DateTime.now().toIso8601String());
    debugPrint('✅ 已记录进入日记本');
  }

  /// 检查是否需要密码验证
  Future<bool> needsPasswordVerification() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 检查是否首次进入
    final hasEntered = prefs.getBool(_hasEnteredKey) ?? false;
    if (!hasEntered) {
      debugPrint('ℹ️ 首次进入，无需密码');
      return false;
    }

    // 检查上次退出时间
    final lastExitTimeStr = prefs.getString(_lastExitTimeKey);
    if (lastExitTimeStr != null) {
      final lastExitTime = DateTime.parse(lastExitTimeStr);
      final now = DateTime.now();
      final difference = now.difference(lastExitTime).inMinutes;

      if (difference < _sessionTimeoutMinutes) {
        debugPrint('ℹ️ 会话未过期（${difference}分钟），无需密码');
        return false;
      }
    }

    debugPrint('🔒 需要密码验证');
    return true;
  }

  /// 清除会话（用于退出登录等场景）
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastExitTimeKey);
    debugPrint('✅ 已清除会话');
  }

  /// 重置密码记录（测试用）
  Future<void> resetPasswordRecord() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasEnteredKey);
    await prefs.remove(_lastExitTimeKey);
    debugPrint('✅ 已重置密码记录');
  }
}