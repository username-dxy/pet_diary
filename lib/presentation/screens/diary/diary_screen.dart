import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_diary/presentation/screens/diary/diary_viewmodel.dart';
import 'package:pet_diary/presentation/screens/diary/widgets/diary_page_widget.dart';
import 'package:pet_diary/presentation/screens/diary/widgets/diary_empty_state_widget.dart';
import 'package:pet_diary/presentation/screens/diary/widgets/diary_password_dialog.dart';
import 'package:pet_diary/domain/services/diary_password_service.dart';
import 'package:pet_diary/presentation/widgets/upgrade_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final DiaryPasswordService _passwordService = DiaryPasswordService();
  bool _isVerified = false;
  bool _isCheckingPassword = true;

  @override
  void initState() {
    super.initState();
    _checkPasswordVerification();
  }

  /// 检查密码验证
  Future<void> _checkPasswordVerification() async {
    final needsPassword = await _passwordService.needsPasswordVerification();

    if (!needsPassword) {
      // 无需密码，直接进入
      await _passwordService.markEntered();
      setState(() {
        _isVerified = true;
        _isCheckingPassword = false;
      });
      return;
    }

    setState(() {
      _isCheckingPassword = false;
    });

    // 需要密码验证，延迟一下显示对话框
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // 显示密码对话框
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DiaryPasswordDialog(),
    );

    if (verified == true) {
      await _passwordService.markEntered();
      setState(() {
        _isVerified = true;
      });
    } else {
      // 用户取消，返回上一页
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPassword) {
      // 检查密码中
      return Scaffold(
        backgroundColor: const Color(0xFFF5E6D3),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
              ),
              const SizedBox(height: 20),
              Text(
                '打开日记本中...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isVerified) {
      // 密码未验证，显示空白页
      return const Scaffold(
        backgroundColor: Color(0xFFF5E6D3),
        body: Center(),
      );
    }

    // 密码验证通过，显示日记内容
    return ChangeNotifierProvider(
      create: (_) => DiaryViewModel()..init(),
      child: const _DiaryScreenContent(),
    );
  }
}

class _DiaryScreenContent extends StatelessWidget {
  const _DiaryScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DiaryViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        title: Text('${viewModel.currentPet?.name ?? '宠物'}的日记本'),
        centerTitle: true,
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        actions: [
          // 调试菜单
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'clear_diary':
                  _confirmClearAllDiaries(context, viewModel);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_diary',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 8),
                    Text('清空所有日记'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context, viewModel),
    );
  }

  Widget _buildContent(BuildContext context, DiaryViewModel viewModel) {
    // 如果有错误
    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => viewModel.loadData(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 如果没有日记，显示空状态
    if (viewModel.entries.isEmpty) {
      return const DiaryEmptyStateWidget();
    }

    // 显示日记
    return Stack(
      children: [
        // 日记内容
        PageView.builder(
          itemCount: viewModel.entries.length,
          controller: PageController(initialPage: viewModel.currentIndex),
          onPageChanged: (index) => viewModel.jumpToIndex(index),
          itemBuilder: (context, index) {
            final entry = viewModel.entries[index];
            return DiaryPageWidget(
              entry: entry,
              petName: viewModel.currentPet?.name ?? 'TA',
              onUpgradeTap: () => UpgradeDialog.show(context),
            );
          },
        ),

        // 翻页指示器
        if (viewModel.entries.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed:
                      viewModel.hasPrevious ? () => viewModel.previousPage() : null,
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 32,
                  color: viewModel.hasPrevious
                      ? const Color(0xFF8B4513)
                      : Colors.grey,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${viewModel.currentIndex + 1} / ${viewModel.entries.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: viewModel.hasNext ? () => viewModel.nextPage() : null,
                  icon: const Icon(Icons.chevron_right),
                  iconSize: 32,
                  color: viewModel.hasNext ? const Color(0xFF8B4513) : Colors.grey,
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 确认清空所有日记
  void _confirmClearAllDiaries(BuildContext context, DiaryViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空日记'),
        content: const Text('确定要删除所有日记吗？此操作不可撤销！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 清空日记
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('diary_entries');
              await viewModel.loadData();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('所有日记已清空')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定删除'),
          ),
        ],
      ),
    );
  }
}
