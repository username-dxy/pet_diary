import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/pet.dart';
import 'profile_viewmodel.dart';
import 'widgets/profile_header_widget.dart';
import 'widgets/profile_info_row_widget.dart';
import 'widgets/edit_profile_dialog.dart';

/// Profile 页面
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: const _ProfileScreenContent(),
    );
  }
}

/// Profile 页面内容
class _ProfileScreenContent extends StatelessWidget {
  const _ProfileScreenContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8DC),
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFF8DC),
        elevation: 0,
        actions: [
          // 同步按钮
          if (vm.pet != null)
            IconButton(
              onPressed: vm.isSyncing ? null : vm.manualSync,
              icon: vm.isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF8B4513),
                      ),
                    )
                  : const Icon(Icons.sync),
              color: const Color(0xFF8B4513),
              tooltip: '同步到服务器',
            ),
        ],
      ),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, ProfileViewModel vm) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8B4513),
        ),
      );
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              vm.errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: vm.refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
              ),
              child: const Text(
                '重试',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (vm.pet == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pets,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              '还没有宠物档案',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/profile-setup');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
              ),
              child: const Text(
                '创建档案',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.refresh,
      color: const Color(0xFF8B4513),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部卡片
            ProfileHeaderWidget(
              pet: vm.pet!,
              onEditTap: () => _showEditDialog(context, vm),
            ),
            const SizedBox(height: 24),

            // 同步状态
            if (vm.lastSyncTime != null || vm.isSyncing)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(
                      vm.isSyncing ? Icons.sync : Icons.cloud_done,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      vm.getSyncStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

            // 基本信息卡片
            _buildInfoCard(
              title: '基本信息',
              children: [
                ProfileInfoRowWidget(
                  icon: Icons.person_outline,
                  label: '主人称呼',
                  value: vm.pet!.ownerNickname ?? '未设置',
                ),
                if (vm.pet!.birthday != null)
                  ProfileInfoRowWidget(
                    icon: Icons.cake_outlined,
                    label: '生日',
                    value:
                        '${DateFormat('yyyy年MM月dd日').format(vm.pet!.birthday!)} (${vm.getAgeText()})',
                  ),
                ProfileInfoRowWidget(
                  icon: Icons.wc_outlined,
                  label: '性别',
                  value: vm.pet!.gender?.displayName ?? '未知',
                  iconColor: _getGenderColor(vm.pet!.gender),
                ),
                if (vm.pet!.personality != null)
                  ProfileInfoRowWidget(
                    icon: Icons.emoji_emotions_outlined,
                    label: '性格',
                    value: '${vm.pet!.personality!.icon} ${vm.pet!.personality!.displayName}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建信息卡片
  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  /// 获取性别颜色
  Color _getGenderColor(PetGender? gender) {
    switch (gender) {
      case PetGender.male:
        return Colors.blue;
      case PetGender.female:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  /// 显示编辑对话框
  Future<void> _showEditDialog(
    BuildContext context,
    ProfileViewModel vm,
  ) async {
    final updatedPet = await showDialog(
      context: context,
      builder: (context) => EditProfileDialog(pet: vm.pet!),
    );

    if (updatedPet != null) {
      await vm.updateProfile(updatedPet);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('档案更新成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}