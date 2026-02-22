import 'package:pet_diary/data/repositories/quota_repository.dart';

/// 会员服务抽象接口
///
/// 后续对接 IAP 时，替换为真实实现
abstract class MembershipService {
  /// 是否为高级会员
  Future<bool> isPremium();

  /// 会员到期时间
  Future<DateTime?> get premiumExpiry;

  /// 恢复购买（预留）
  Future<bool> restorePurchases();

  /// 购买会员（预留）
  Future<bool> purchasePremium();

  /// 刷新会员状态
  Future<void> refreshStatus();
}

/// Mock 会员服务实现
///
/// MVP 阶段使用本地存储模拟会员状态
class MockMembershipService implements MembershipService {
  final QuotaRepository _quotaRepository;

  MockMembershipService({QuotaRepository? quotaRepository})
      : _quotaRepository = quotaRepository ?? QuotaRepository();

  @override
  Future<bool> isPremium() async {
    final status = await _quotaRepository.getQuotaStatus();

    // 检查会员是否过期
    if (status.isPremium && status.premiumExpiry != null) {
      if (status.premiumExpiry!.isBefore(DateTime.now())) {
        // 会员已过期，更新状态
        await _quotaRepository.setPremiumStatus(isPremium: false);
        return false;
      }
    }

    return status.isPremium;
  }

  @override
  Future<DateTime?> get premiumExpiry async {
    final status = await _quotaRepository.getQuotaStatus();
    return status.premiumExpiry;
  }

  @override
  Future<bool> restorePurchases() async {
    // 预留：后续对接 IAP 恢复购买
    // 目前返回 false 表示无可恢复的购买
    return false;
  }

  @override
  Future<bool> purchasePremium() async {
    // 预留：后续对接 IAP 购买流程
    // 目前返回 false 表示购买未实现
    return false;
  }

  @override
  Future<void> refreshStatus() async {
    // 预留：后续从服务端刷新会员状态
    // 目前无需操作
  }

  /// 模拟设置会员状态（仅用于测试）
  Future<void> setMockPremiumStatus({
    required bool isPremium,
    Duration? duration,
  }) async {
    DateTime? expiry;
    if (isPremium && duration != null) {
      expiry = DateTime.now().add(duration);
    }
    await _quotaRepository.setPremiumStatus(
      isPremium: isPremium,
      expiry: expiry,
    );
  }
}
