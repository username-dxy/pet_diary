import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_diary/presentation/screens/calendar/calendar_viewmodel.dart';
import 'package:pet_diary/domain/services/asset_manager.dart';

/// AI处理进度对话框
class ProcessingDialog extends StatelessWidget {
  const ProcessingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CalendarViewModel>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!viewModel.isComplete) ...[
              // 处理中
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                viewModel.currentStep,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: viewModel.progress,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Text(
                '${(viewModel.progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ] else ...[
              // 完成
              const Icon(Icons.check_circle, size: 60, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                viewModel.currentStep,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 显示照片预览
              if (viewModel.selectedImage != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    viewModel.selectedImage!,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 显示识别结果
              if (viewModel.recognizedEmotion != null) ...[
                Text(
                  '识别情绪：${AssetManager.instance.getEmotionName(viewModel.recognizedEmotion!)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                AssetManager.instance.getEmotionSticker(
                  viewModel.recognizedEmotion!,
                  size: 60,
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        // 显示情绪选择器
                        _showEmotionSelector(context, viewModel);
                      },
                      child: const Text('切换情绪'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await viewModel.saveRecord();
                        if (context.mounted) {
                          Navigator.of(context).pop(); // 关闭对话框
                        }
                      },
                      child: const Text('确认'),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showEmotionSelector(BuildContext context, CalendarViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: Consumer<CalendarViewModel>(
          builder: (context, vm, _) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '选择情绪',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: Emotion.values.map((emotion) {
                      final isSelected = emotion == vm.recognizedEmotion;
                      return GestureDetector(
                        onTap: () async {
                          Navigator.pop(context); // 关闭选择器
                          await vm.switchEmotion(emotion);
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: AssetManager.instance.getEmotionSticker(
                                  emotion,
                                  size: 36,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AssetManager.instance.getEmotionName(emotion),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.blue : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}