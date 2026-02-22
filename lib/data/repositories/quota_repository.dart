import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quota_status.dart';

/// AI 配额本地存储仓库
class QuotaRepository {
  static const String _key = 'ai_quota_status';

  /// 获取配额状态
  Future<QuotaStatus> getQuotaStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) {
      return const QuotaStatus();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return QuotaStatus.fromJson(json);
    } catch (e) {
      return const QuotaStatus();
    }
  }

  /// 保存配额状态
  Future<void> saveQuotaStatus(QuotaStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(status.toJson());
    await prefs.setString(_key, jsonString);
  }

  /// 增加使用次数
  Future<QuotaStatus> incrementUsage() async {
    final current = await getQuotaStatus();
    final nextUsed = current.freeQuotaUsed >= current.freeQuotaTotal
        ? current.freeQuotaTotal
        : current.freeQuotaUsed + 1;
    final updated = current.copyWith(
      freeQuotaUsed: nextUsed,
      firstUsedAt: current.firstUsedAt ?? DateTime.now(),
    );
    await saveQuotaStatus(updated);
    return updated;
  }

  /// 重置配额（用于测试或特殊场景）
  Future<QuotaStatus> resetQuota() async {
    final current = await getQuotaStatus();
    final updated = current.copyWith(
      freeQuotaUsed: 0,
    );
    await saveQuotaStatus(updated);
    return updated;
  }

  /// 设置会员状态
  Future<QuotaStatus> setPremiumStatus({
    required bool isPremium,
    DateTime? expiry,
  }) async {
    final current = await getQuotaStatus();
    final updated = current.copyWith(
      isPremium: isPremium,
      premiumExpiry: expiry,
    );
    await saveQuotaStatus(updated);
    return updated;
  }

  /// 清除配额数据（用于用户登出或重置）
  Future<void> clearQuotaStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
