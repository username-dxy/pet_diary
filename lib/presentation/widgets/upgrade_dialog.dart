import 'package:flutter/material.dart';

/// 会员升级弹窗
///
/// 当配额用完时显示，引导用户升级会员
class UpgradeDialog extends StatelessWidget {
  /// 升级按钮点击回调
  final VoidCallback? onUpgrade;

  /// 关闭按钮点击回调
  final VoidCallback? onClose;

  const UpgradeDialog({
    super.key,
    this.onUpgrade,
    this.onClose,
  });

  /// 显示升级弹窗
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => UpgradeDialog(
        onUpgrade: () {
          Navigator.of(context).pop(true);
        },
        onClose: () {
          Navigator.of(context).pop(false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8DC),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 皇冠图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 45,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // 标题
            const Text(
              'AI 日记次数已用完',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),

            const SizedBox(height: 12),

            // 副标题
            Text(
              '升级会员，解锁无限 AI 日记生成',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // 会员权益列表
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD2B48C),
                  width: 1,
                ),
              ),
              child: const Column(
                children: [
                  _BenefitRow(
                    icon: Icons.auto_awesome,
                    text: '无限 AI 日记生成',
                  ),
                  SizedBox(height: 12),
                  _BenefitRow(
                    icon: Icons.palette,
                    text: '专属贴纸风格',
                  ),
                  SizedBox(height: 12),
                  _BenefitRow(
                    icon: Icons.cloud_upload,
                    text: '云端备份同步',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 升级按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB74D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.workspace_premium, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '升级会员',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 提示文字
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '您仍可手动编写日记',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 稍后再说按钮
            TextButton(
              onPressed: onClose,
              child: Text(
                '稍后再说',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 权益行组件
class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFFFFB74D),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF5D4037),
          ),
        ),
        const Spacer(),
        const Icon(
          Icons.check_circle,
          size: 18,
          color: Color(0xFF4CAF50),
        ),
      ],
    );
  }
}
