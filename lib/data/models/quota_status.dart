import 'package:equatable/equatable.dart';

/// AI 日记生成配额状态
class QuotaStatus extends Equatable {
  /// 免费配额总量
  final int freeQuotaTotal;

  /// 已使用的免费配额
  final int freeQuotaUsed;

  /// 是否为高级会员
  final bool isPremium;

  /// 首次使用 AI 生成的时间
  final DateTime? firstUsedAt;

  /// 会员到期时间（预留）
  final DateTime? premiumExpiry;

  const QuotaStatus({
    this.freeQuotaTotal = 3,
    this.freeQuotaUsed = 0,
    this.isPremium = false,
    this.firstUsedAt,
    this.premiumExpiry,
  });

  /// 剩余免费配额
  int get freeQuotaRemaining {
    final remaining = freeQuotaTotal - freeQuotaUsed;
    return remaining < 0 ? 0 : remaining;
  }

  /// 是否可以使用 AI 生成日记
  bool get canGenerateAI => isPremium || freeQuotaRemaining > 0;

  /// 是否已用完免费配额
  bool get isQuotaExhausted => !isPremium && freeQuotaRemaining <= 0;

  factory QuotaStatus.fromJson(Map<String, dynamic> json) {
    return QuotaStatus(
      freeQuotaTotal: json['freeQuotaTotal'] as int? ?? 3,
      freeQuotaUsed: json['freeQuotaUsed'] as int? ?? 0,
      isPremium: json['isPremium'] as bool? ?? false,
      firstUsedAt: json['firstUsedAt'] != null
          ? DateTime.parse(json['firstUsedAt'] as String)
          : null,
      premiumExpiry: json['premiumExpiry'] != null
          ? DateTime.parse(json['premiumExpiry'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'freeQuotaTotal': freeQuotaTotal,
      'freeQuotaUsed': freeQuotaUsed,
      'isPremium': isPremium,
      'firstUsedAt': firstUsedAt?.toIso8601String(),
      'premiumExpiry': premiumExpiry?.toIso8601String(),
    };
  }

  QuotaStatus copyWith({
    int? freeQuotaTotal,
    int? freeQuotaUsed,
    bool? isPremium,
    DateTime? firstUsedAt,
    DateTime? premiumExpiry,
  }) {
    return QuotaStatus(
      freeQuotaTotal: freeQuotaTotal ?? this.freeQuotaTotal,
      freeQuotaUsed: freeQuotaUsed ?? this.freeQuotaUsed,
      isPremium: isPremium ?? this.isPremium,
      firstUsedAt: firstUsedAt ?? this.firstUsedAt,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
    );
  }

  @override
  List<Object?> get props => [
        freeQuotaTotal,
        freeQuotaUsed,
        isPremium,
        firstUsedAt,
        premiumExpiry,
      ];
}
