import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pet_diary/presentation/screens/calendar/calendar_viewmodel.dart';
import 'package:pet_diary/presentation/screens/calendar/widgets/month_grid_widget.dart';
import 'package:pet_diary/presentation/screens/calendar/widgets/processing_dialog.dart';
import 'package:pet_diary/presentation/screens/calendar/widgets/emotion_selector_widget.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarViewModel()..loadMonth(),
      child: const _CalendarScreenContent(),
    );
  }
}

class _CalendarScreenContent extends StatelessWidget {
  const _CalendarScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CalendarViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${viewModel.currentYear}年${viewModel.currentMonth}月',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => viewModel.changeMonth(-1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () => viewModel.changeMonth(1),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: Image.asset(
              'assets/images/room/room_calendar_expanded.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 内容
          SafeArea(
            child: Column(
              children: [
                // 星期标题
                _buildWeekHeader(),

                // 月度网格
                Expanded(
                  child: MonthGridWidget(
                    year: viewModel.currentYear,
                    month: viewModel.currentMonth,
                    records: viewModel.monthRecords,
                    onDayTap: (date) {
                      _handleDayTap(context, viewModel, date);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // 添加按钮
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => _handleAddEmotion(context, viewModel),
        child: const Icon(Icons.add, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildWeekHeader() {
    const weekDays = ['日', '一', '二', '三', '四', '五', '六'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((day) {
          return SizedBox(
            width: 40,
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleDayTap(BuildContext context, CalendarViewModel viewModel, DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    final record = viewModel.monthRecords[dateKey];

    if (record != null) {
      // 已有记录，显示情绪选择器
      showModalBottomSheet(
        context: context,
        builder: (_) => ChangeNotifierProvider.value(
          value: viewModel,
          child: EmotionSelectorWidget(
            currentEmotion: record.selectedEmotion,
            onEmotionSelected: (emotion) async {
              Navigator.pop(context);
              await viewModel.updateRecordEmotion(date, emotion);
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleAddEmotion(BuildContext context, CalendarViewModel viewModel) async {
    debugPrint('🎯 开始添加情绪');
    
    // 1. 选择照片
    await viewModel.pickImage();

    // 2. 直接从 viewModel 检查（不依赖 context.watch）
    if (viewModel.selectedImage == null) {
      debugPrint('❌ 照片未选择');
      
      if (viewModel.permissionError != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.permissionError!),
            action: SnackBarAction(
              label: '去设置',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    debugPrint('✅ 照片已选择: ${viewModel.selectedImage!.path}');

    // 3. 显示处理对话框
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const ProcessingDialog(),
      ),
    );

    // 4. 开始处理
    debugPrint('🔄 开始处理照片');
    await viewModel.processImageSimple();
  }

  /// 显示权限错误对话框
  void _showPermissionDialog(BuildContext context, CalendarViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要相册权限'),
        content: Text(viewModel.permissionError ?? '无法访问相册'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          if (viewModel.permissionError?.contains('永久拒绝') == true)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                viewModel.openSystemSettings(); // 打开系统设置
              },
              child: const Text('去设置'),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _handleAddEmotion(context, viewModel); // 重新尝试
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
}