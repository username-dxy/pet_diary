import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_diary/presentation/screens/diary/diary_viewmodel.dart';
import 'package:pet_diary/presentation/screens/diary/widgets/diary_page_widget.dart';
import 'package:pet_diary/presentation/screens/diary/widgets/diary_empty_state_widget.dart';
import 'package:pet_diary/presentation/screens/diary/widgets/diary_password_dialog.dart';
import 'package:pet_diary/data/models/app_photo.dart';
import 'package:pet_diary/domain/services/diary_password_service.dart';
import 'package:pet_diary/presentation/screens/diary/widgets/photo_info_dialog.dart';
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
      return Scaffold(
        backgroundColor: const Color(0xFFF5E6D3),
        body: const Center(),
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
          // 相册管理按钮
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.photo_library),
                if (viewModel.albumPhotoCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${viewModel.albumPhotoCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showAlbumManagement(context, viewModel),
          ),
          // 调试菜单
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'check_exif':
                  _showExifCheckDialog(context, viewModel);
                  break;
                case 'clear_diary':
                  _confirmClearAllDiaries(context, viewModel);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'check_exif',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text('检查EXIF信息'),
                  ],
                ),
              ),
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
      floatingActionButton: _buildFloatingButton(context, viewModel),
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
      return DiaryEmptyStateWidget(
        onPickPhotos: () => viewModel.pickPhotosToAlbum(),
      );
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
            return DiaryPageWidget(entry: entry);
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

  Widget? _buildFloatingButton(BuildContext context, DiaryViewModel viewModel) {
    if (!viewModel.hasPhotosInAlbum) {
      return null; // 没有照片时不显示生成按钮
    }

    return FloatingActionButton.extended(
      onPressed: viewModel.isGenerating ? null : () => viewModel.generateDiary(),
      icon: viewModel.isGenerating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.auto_awesome),
      label: Text(viewModel.isGenerating ? '生成中...' : '生成日记'),
      backgroundColor: const Color(0xFF8B4513),
    );
  }

  /// 显示相册管理弹窗
  void _showAlbumManagement(BuildContext context, DiaryViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const _AlbumManagementSheet(),
      ),
    );
  }
  /// 显示EXIF检查对话框
  void _showExifCheckDialog(BuildContext context, DiaryViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📸 EXIF信息检查'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('相册照片总数: ${viewModel.albumPhotoCount}'),
              const SizedBox(height: 16),
              ...viewModel.albumPhotos.map((photo) {
                final hasExif = photo.photoTakenAt != null;
                final hasLocation = photo.location != null;
                
                return Card(
                  child: ListTile(
                    leading: Icon(
                      hasExif ? Icons.check_circle : Icons.cancel,
                      color: hasExif ? Colors.green : Colors.red,
                    ),
                    title: Text('照片 ${photo.id.substring(0, 8)}...'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('拍摄时间: ${photo.photoTakenAt ?? "❌ 未读取"}'),
                        Text('地理位置: ${photo.location ?? "❌ 未读取"}'),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => PhotoInfoDialog(photo: photo),
                      );
                    },
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💡 点击照片可查看详细信息\n'
                  '如果没有EXIF信息，建议：\n'
                  '• 使用相机原图\n'
                  '• 避免使用截图或编辑过的图片',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 确认清空所有日记
  void _confirmClearAllDiaries(BuildContext context, DiaryViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 清空日记'),
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

/// 相册管理底部表单
class _AlbumManagementSheet extends StatelessWidget {
  const _AlbumManagementSheet();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DiaryViewModel>();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5E6D3),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      'App相册 (${viewModel.albumPhotoCount})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 添加照片按钮
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await viewModel.pickPhotosToAlbum();
                  },
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('添加照片'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),

              // 照片网格
              Expanded(
                child: viewModel.albumPhotos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              '相册中还没有照片',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: viewModel.albumPhotos.length,
                        itemBuilder: (context, index) {
                          final photo = viewModel.albumPhotos[index];
                          return _buildPhotoItem(context, photo, viewModel);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoItem(BuildContext context, AppPhoto photo, DiaryViewModel viewModel) {
    return GestureDetector(
      onTap: () {
        // 点击照片查看详细信息
        showDialog(
          context: context,
          builder: (context) => PhotoInfoDialog(photo: photo),
        );
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(photo.localPath),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          
          // 删除按钮
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => viewModel.deletePhotoFromAlbum(photo.id),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          
          // EXIF信息指示器
          if (photo.photoTakenAt != null || photo.location != null)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'EXIF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '无EXIF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

}