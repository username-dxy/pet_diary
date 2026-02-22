import 'package:flutter/foundation.dart';
import 'package:pet_diary/data/models/quota_status.dart';
import 'package:pet_diary/data/repositories/quota_repository.dart';
import 'package:pet_diary/domain/services/membership_service.dart';

/// AI 日记配额服务
///
/// 管理 AI 日记生成的配额检查和使用记录
class QuotaService {
  final QuotaRepository _quotaRepository;
  final MembershipService _membershipService;

  QuotaService({
    QuotaRepository? quotaRepository,
    MembershipService? membershipService,
  })  : _quotaRepository = quotaRepository ?? QuotaRepository(),
        _membershipService = membershipService ?? MockMembershipService();

  /// 检查是否可以使用 AI 生成日记
  Future<bool> canGenerateAI() async {
    // 会员可以无限使用
    if (await _membershipService.isPremium()) {
      debugPrint('📊 [Quota] 会员用户，可无限生成');
      return true;
    }

    // 检查免费配额
    final status = await _quotaRepository.getQuotaStatus();
    final canGenerate = status.freeQuotaRemaining > 0;

    debugPrint('📊 [Quota] 免费配额: ${status.freeQuotaRemaining}/${status.freeQuotaTotal}');
    return canGenerate;
  }

  /// 记录一次 AI 使用
  Future<QuotaStatus> recordAIUsage() async {
    // 会员不消耗配额
    if (await _membershipService.isPremium()) {
      debugPrint('📊 [Quota] 会员用户，不消耗配额');
      return await _quotaRepository.getQuotaStatus();
    }

    final updated = await _quotaRepository.incrementUsage();
    debugPrint('📊 [Quota] 已使用配额: ${updated.freeQuotaUsed}/${updated.freeQuotaTotal}');
    return updated;
  }

  /// 获取当前配额状态
  Future<QuotaStatus> getQuotaStatus() async {
    final status = await _quotaRepository.getQuotaStatus();

    // 同步会员状态
    final isPremium = await _membershipService.isPremium();
    if (status.isPremium != isPremium) {
      final expiry = await _membershipService.premiumExpiry;
      return await _quotaRepository.setPremiumStatus(
        isPremium: isPremium,
        expiry: expiry,
      );
    }

    return status;
  }

  /// 重置配额（用于测试）
  Future<QuotaStatus> resetQuota() async {
    debugPrint('📊 [Quota] 重置配额');
    return await _quotaRepository.resetQuota();
  }

  /// 清除所有配额数据
  Future<void> clearQuotaData() async {
    debugPrint('📊 [Quota] 清除配额数据');
    await _quotaRepository.clearQuotaStatus();
  }
}
