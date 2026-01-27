import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_setup_viewmodel.dart';
import 'widgets/photo_upload_section.dart';
import 'widgets/name_input_section.dart';
import 'widgets/owner_nickname_section.dart';
import 'widgets/birthday_picker_section.dart';
import 'widgets/gender_selector_section.dart';
import 'widgets/personality_selector_section.dart';

/// Profile 设置页面
class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileSetupViewModel(),
      child: const _ProfileSetupScreenContent(),
    );
  }
}

/// Profile 设置页面内容
class _ProfileSetupScreenContent extends StatelessWidget {
  const _ProfileSetupScreenContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileSetupViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8DC), // 米黄色背景
      appBar: AppBar(
        title: const Text('创建宠物档案'),
        backgroundColor: const Color(0xFFFFF8DC),
        elevation: 0,
        automaticallyImplyLeading: false, // 隐藏返回按钮
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 进度指示器
                _buildProgressIndicator(vm.progressPercentage),
                const SizedBox(height: 24),

                // 欢迎文案
                const Text(
                  '让我们更了解你的宠物',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '填写以下信息，创建专属档案',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // 1. 照片上传
                PhotoUploadSection(
                  photo: vm.profilePhoto,
                  onTap: vm.pickPhoto,
                  errorMessage: vm.photoError,
                ),
                const SizedBox(height: 32),

                // 2. 名称输入
                NameInputSection(
                  initialValue: vm.name,
                  onChanged: vm.setName,
                ),
                const SizedBox(height: 32),

                // 3. 主人称呼
                OwnerNicknameSection(
                  selectedNickname: vm.ownerNickname,
                  onSelected: vm.setOwnerNickname,
                ),
                const SizedBox(height: 32),

                // 4. 生日选择
                BirthdayPickerSection(
                  selectedDate: vm.birthday,
                  onDateSelected: vm.setBirthday,
                ),
                const SizedBox(height: 32),

                // 5. 性别选择
                GenderSelectorSection(
                  selectedGender: vm.gender,
                  onSelected: vm.setGender,
                ),
                const SizedBox(height: 32),

                // 6. 性格选择
                PersonalitySelectorSection(
                  selectedPersonality: vm.personality,
                  onSelected: vm.setPersonality,
                ),

                const SizedBox(height: 120), // 为底部按钮留空间
              ],
            ),
          ),

          // 底部提交按钮
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vm.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              vm.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: vm.isValid && !vm.isSubmitting
                          ? () => _handleSubmit(context, vm)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: vm.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '完成设置',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 进度指示器
  Widget _buildProgressIndicator(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '完成度',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8B4513),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  /// 处理提交
  Future<void> _handleSubmit(
    BuildContext context,
    ProfileSetupViewModel vm,
  ) async {
    final success = await vm.submitProfile();

    if (success && context.mounted) {
      // 跳转到主页
      Navigator.of(context).pushReplacementNamed('/home');

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('档案创建成功！'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
