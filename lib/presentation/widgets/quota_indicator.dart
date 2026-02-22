import 'package:flutter/material.dart';
import 'package:pet_diary/data/models/quota_status.dart';

/// AI 配额指示器组件
///
/// 显示剩余 AI 日记生成次数或会员状态
class QuotaIndicator extends StatelessWidget {
  final QuotaStatus quotaStatus;
  final VoidCallback? onTap;

  const QuotaIndicator({
    super.key,
    required this.quotaStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: 16,
              color: _textColor,
            ),
            const SizedBox(width: 6),
            Text(
              _displayText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon {
    if (quotaStatus.isPremium) {
      return Icons.workspace_premium;
    } else if (quotaStatus.isQuotaExhausted) {
      return Icons.warning_amber_rounded;
    } else {
      return Icons.auto_awesome;
    }
  }

  String get _displayText {
    if (quotaStatus.isPremium) {
      return '会员';
    } else if (quotaStatus.isQuotaExhausted) {
      return '升级解锁';
    } else {
      return 'AI ${quotaStatus.freeQuotaRemaining}/${quotaStatus.freeQuotaTotal}';
    }
  }

  Color get _backgroundColor {
    if (quotaStatus.isPremium) {
      return const Color(0xFFFFF3E0); // 金色背景
    } else if (quotaStatus.isQuotaExhausted) {
      return const Color(0xFFFFEBEE); // 红色背景
    } else {
      return const Color(0xFFE3F2FD); // 蓝色背景
    }
  }

  Color get _borderColor {
    if (quotaStatus.isPremium) {
      return const Color(0xFFFFB74D); // 金色边框
    } else if (quotaStatus.isQuotaExhausted) {
      return const Color(0xFFE57373); // 红色边框
    } else {
      return const Color(0xFF64B5F6); // 蓝色边框
    }
  }

  Color get _textColor {
    if (quotaStatus.isPremium) {
      return const Color(0xFFE65100); // 金色文字
    } else if (quotaStatus.isQuotaExhausted) {
      return const Color(0xFFC62828); // 红色文字
    } else {
      return const Color(0xFF1565C0); // 蓝色文字
    }
  }
}

/// 紧凑版配额指示器
///
/// 用于空间较小的场景，只显示数字
class QuotaIndicatorCompact extends StatelessWidget {
  final QuotaStatus quotaStatus;
  final VoidCallback? onTap;

  const QuotaIndicatorCompact({
    super.key,
    required this.quotaStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Text(
          _displayText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
      ),
    );
  }

  String get _displayText {
    if (quotaStatus.isPremium) {
      return 'V';
    } else {
      return '${quotaStatus.freeQuotaRemaining}';
    }
  }

  Color get _backgroundColor {
    if (quotaStatus.isPremium) {
      return const Color(0xFFFFB74D);
    } else if (quotaStatus.isQuotaExhausted) {
      return const Color(0xFFE57373);
    } else {
      return const Color(0xFF64B5F6);
    }
  }

  Color get _textColor {
    return Colors.white;
  }
}
