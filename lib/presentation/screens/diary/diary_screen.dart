import 'dart:io';  // ← 必须有！用于 File 类
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_diary/presentation/screens/diary/diary_viewmodel.dart';
import 'package:pet_diary/presentation/screens/diary/widgets/diary_page_widget.dart';
import 'package:pet_diary/presentation/screens/diary/widgets/diary_empty_state_widget.dart';
import 'package:pet_diary/data/models/app_photo.dart';  // ← 必须有！用于 AppPhoto 类

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                          return _buildPhotoItem(photo, viewModel);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoItem(AppPhoto photo, DiaryViewModel viewModel) {
    return Stack(
      children: [
        // 照片
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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }
}