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

  // 背景图原始比例 (786 x 1966 @2x → 393 x 983 逻辑)
  static const double _bgAspectRatio = 786.0 / 1966.0;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileSetupViewModel>();
    final screenWidth = MediaQuery.of(context).size.width;
    // 背景图按屏幕宽度等比铺满，高度自适应
    final bgHeight = screenWidth / _bgAspectRatio;

    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: screenWidth,
          height: bgHeight,
          child: Stack(
            children: [
              // 背景图：宽度撑满，高度按比例
              Positioned.fill(
                child: Image.asset(
                  'assets/images/profile_setup/profile_background.jpg',
                  fit: BoxFit.fill,
                ),
              ),

              // 表单内容
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: _buildFormContent(context, vm, screenWidth),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(
    BuildContext context,
    ProfileSetupViewModel vm,
    double screenWidth,
  ) {
    // 自适应内边距：约 13% 屏幕宽度
    final horizontalPadding = screenWidth * 0.13;
    // 图标尺寸自适应
    final iconSize = screenWidth * 0.11;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              '创建宠物档案',
              style: TextStyle(
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFF8DC),
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 1. 照片上传
          PhotoUploadSection(
            photo: vm.profilePhoto,
            onTap: vm.pickPhoto,
            errorMessage: vm.photoError,
            frameSize: screenWidth * 0.5,
          ),

          const SizedBox(height: 28),

          // 2. 名称输入
          NameInputSection(
            initialValue: vm.name,
            onChanged: vm.setName,
            iconSize: iconSize,
          ),

          const SizedBox(height: 28),

          // 3. 主人称呼
          OwnerNicknameSection(
            selectedNickname: vm.ownerNickname,
            onSelected: vm.setOwnerNickname,
            iconSize: iconSize,
          ),

          const SizedBox(height: 28),

          // 4. 生日选择
          BirthdayPickerSection(
            selectedDate: vm.birthday,
            onDateSelected: vm.setBirthday,
            iconSize: iconSize,
          ),

          const SizedBox(height: 28),

          // 5. 性别选择
          GenderSelectorSection(
            selectedGender: vm.gender,
            onSelected: vm.setGender,
            iconSize: iconSize,
          ),

          const SizedBox(height: 28),

          // 6. 性格选择
          PersonalitySelectorSection(
            selectedPersonality: vm.personality,
            onSelected: vm.setPersonality,
            iconSize: iconSize,
          ),

          const SizedBox(height: 32),

          // 7. 提交按钮
          _buildSubmitButton(context, vm, screenWidth),
        ],
      ),
    );
  }

  /// 提交按钮
  Widget _buildSubmitButton(
    BuildContext context,
    ProfileSetupViewModel vm,
    double screenWidth,
  ) {
    final bool canSubmit = vm.isValid && !vm.isSubmitting;
    final btnWidth = screenWidth * 0.35;
    final btnHeight = btnWidth * (66 / 270); // 保持素材比例

    return GestureDetector(
      onTap: canSubmit ? () => _handleSubmit(context, vm) : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            canSubmit
                ? 'assets/images/profile_setup/btn_submit_active.jpg'
                : 'assets/images/profile_setup/btn_submit_disabled.jpg',
            width: btnWidth,
            height: btnHeight,
            fit: BoxFit.contain,
          ),
          if (vm.isSubmitting)
            SizedBox(
              width: btnHeight * 0.6,
              height: btnHeight * 0.6,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else
            Text(
              '完成设置',
              style: TextStyle(
                fontSize: screenWidth * 0.033,
                fontWeight: FontWeight.bold,
                color: canSubmit
                    ? const Color(0xFFFFF8DC)
                    : const Color(0xFFB0A080),
              ),
            ),
        ],
      ),
    );
  }

  /// 处理提交
  Future<void> _handleSubmit(
    BuildContext context,
    ProfileSetupViewModel vm,
  ) async {
    final success = await vm.submitProfile();

    if (success && context.mounted) {
      Navigator.of(context).pushReplacementNamed('/home');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('档案创建成功！'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
