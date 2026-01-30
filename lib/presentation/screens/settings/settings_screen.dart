import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_diary/domain/services/background_scan_service.dart';
import 'package:pet_diary/presentation/screens/settings/settings_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel()..initialize(),
      child: const _SettingsScreenContent(),
    );
  }
}

class _SettingsScreenContent extends StatelessWidget {
  const _SettingsScreenContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        elevation: 0,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionHeader('后台扫描'),
                _buildBackgroundScanSection(context, vm),
                const SizedBox(height: 16),
                _buildSectionHeader('权限状态'),
                _buildPermissionSection(context, vm),
                const SizedBox(height: 16),
                _buildSectionHeader('手动扫描'),
                _buildManualScanSection(context, vm),
                if (vm.errorMessage != null) _buildErrorBanner(context, vm),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildBackgroundScanSection(
      BuildContext context, SettingsViewModel vm) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('后台宠物识别'),
            subtitle: Text(
              vm.isBackgroundScanEnabled
                  ? '已开启 - 将在后台自动扫描相册中的宠物照片'
                  : '已关闭 - 开启后将自动识别新的宠物照片',
            ),
            value: vm.isBackgroundScanEnabled,
            onChanged: vm.hasPermission
                ? (value) => vm.toggleBackgroundScan(value)
                : null,
          ),
          if (!vm.hasPermission)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                '需要先授权相册权限才能启用后台扫描',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          if (vm.lastScanTime != null)
            ListTile(
              leading: const Icon(Icons.access_time, size: 20),
              title: const Text('上次扫描'),
              subtitle: Text(_formatDateTime(vm.lastScanTime!)),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionSection(BuildContext context, SettingsViewModel vm) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              _getPermissionIcon(vm.permissionStatus),
              color: _getPermissionColor(vm.permissionStatus),
            ),
            title: const Text('相册访问权限'),
            subtitle: Text(vm.permissionStatusText),
            trailing: vm.permissionStatus == PhotoPermissionStatus.notDetermined
                ? TextButton(
                    onPressed: () => vm.requestPermission(),
                    child: const Text('请求权限'),
                  )
                : vm.permissionStatus == PhotoPermissionStatus.denied
                    ? TextButton(
                        onPressed: () => _openAppSettings(context),
                        child: const Text('去设置'),
                      )
                    : null,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '后台扫描需要"完全访问"或"选择的照片"权限。'
              '授权后，App可以在后台自动识别相册中的宠物照片并生成日记。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualScanSection(BuildContext context, SettingsViewModel vm) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.pets),
            title: const Text('立即扫描'),
            subtitle: const Text('手动扫描相册中的宠物照片'),
            trailing: vm.isScanning
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: vm.hasPermission
                        ? () => _performManualScan(context, vm)
                        : null,
                  ),
          ),
          if (vm.lastScanResults.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.photo_library, size: 20),
              title: Text('发现 ${vm.lastScanResults.length} 张宠物照片'),
              subtitle: const Text('点击查看详情'),
              onTap: () => _showScanResults(context, vm),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.refresh, size: 20),
            title: const Text('重置扫描记录'),
            subtitle: const Text('清除已处理照片记录，重新扫描所有照片'),
            onTap: () => _confirmReset(context, vm),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, SettingsViewModel vm) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              vm.errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => vm.clearError(),
            color: Colors.red[700],
          ),
        ],
      ),
    );
  }

  IconData _getPermissionIcon(PhotoPermissionStatus status) {
    switch (status) {
      case PhotoPermissionStatus.authorized:
        return Icons.check_circle;
      case PhotoPermissionStatus.limited:
        return Icons.check_circle_outline;
      case PhotoPermissionStatus.denied:
        return Icons.block;
      case PhotoPermissionStatus.restricted:
        return Icons.lock;
      default:
        return Icons.help_outline;
    }
  }

  Color _getPermissionColor(PhotoPermissionStatus status) {
    switch (status) {
      case PhotoPermissionStatus.authorized:
        return Colors.green;
      case PhotoPermissionStatus.limited:
        return Colors.orange;
      case PhotoPermissionStatus.denied:
      case PhotoPermissionStatus.restricted:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} 小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${dateTime.year}/${dateTime.month}/${dateTime.day} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _openAppSettings(BuildContext context) {
    // Show dialog to guide user to app settings
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('权限设置'),
        content: const Text('请在系统设置中允许Pet Diary访问您的相册。\n\n'
            '设置 > 隐私与安全性 > 照片 > Pet Diary'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _performManualScan(
      BuildContext context, SettingsViewModel vm) async {
    final results = await vm.performManualScan();

    if (!context.mounted) return;

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未发现新的宠物照片')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发现 ${results.length} 张宠物照片')),
      );
    }
  }

  void _showScanResults(BuildContext context, SettingsViewModel vm) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '扫描结果',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...vm.lastScanResults.map((result) => ListTile(
                  leading: const Icon(Icons.pets),
                  title: Text(result.animalType == 'Cat' ? '猫咪' : '狗狗'),
                  subtitle: Text(
                    '置信度: ${(result.confidence * 100).toStringAsFixed(1)}%\n'
                    '${result.creationDate != null ? '拍摄时间: ${_formatDateTime(result.creationDate!)}' : ''}',
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, SettingsViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置扫描记录'),
        content: const Text('确定要重置吗？这将清除所有已处理照片的记录，'
            '下次扫描时会重新处理所有照片。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              vm.resetProcessedPhotos();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已重置扫描记录')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
