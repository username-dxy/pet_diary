import 'package:flutter/material.dart';

/// 抽屉（日记本入口）
class DrawerWidget extends StatelessWidget {
  final bool hasNewDiary;

  const DrawerWidget({
    super.key,
    required this.hasNewDiary,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 抽屉本体
        Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.brown.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.lock,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),

        // 新日记红点提示
        if (hasNewDiary)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}