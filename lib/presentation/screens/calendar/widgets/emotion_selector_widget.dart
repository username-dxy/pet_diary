import 'package:flutter/material.dart';
import 'package:pet_diary/domain/services/asset_manager.dart';

/// 情绪选择器（底部弹出）
class EmotionSelectorWidget extends StatelessWidget {
  final Emotion currentEmotion;
  final Function(Emotion) onEmotionSelected;

  const EmotionSelectorWidget({
    super.key,
    required this.currentEmotion,
    required this.onEmotionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '选择宠物今日情绪',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // 6种情绪横向排列
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: Emotion.values.map((emotion) {
              final isSelected = emotion == currentEmotion;
              return GestureDetector(
                onTap: () => onEmotionSelected(emotion),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: AssetManager.instance.getEmotionSticker(
                          emotion,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AssetManager.instance.getEmotionName(emotion),
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.blue : Colors.grey,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          
          // 当前情绪提示
          Text(
            '当前：${AssetManager.instance.getEmotionName(currentEmotion)}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
