import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/pet.dart';
import '../../profile_setup/widgets/photo_upload_section.dart';
import '../../profile_setup/widgets/name_input_section.dart';
import '../../profile_setup/widgets/owner_nickname_section.dart';
import '../../profile_setup/widgets/birthday_picker_section.dart';
import '../../profile_setup/widgets/gender_selector_section.dart';
import '../../profile_setup/widgets/personality_selector_section.dart';
import 'edit_profile_viewmodel.dart';

/// 编辑档案对话框
class EditProfileDialog extends StatelessWidget {
  final Pet pet;

  const EditProfileDialog({
    Key? key,
    required this.pet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditProfileViewModel(initialPet: pet),
      child: _EditProfileDialogContent(pet: pet),
    );
  }
}

class _EditProfileDialogContent extends StatelessWidget {
  final Pet pet;

  const _EditProfileDialogContent({required this.pet});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditProfileViewModel>();

    return Dialog(
      backgroundColor: const Color(0xFFFFF8DC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头部
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '编辑档案',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),

            // 表单内容
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 照片上传
                    PhotoUploadSection(
                      photo: vm.profilePhoto,
                      onTap: vm.pickPhoto,
                      errorMessage: vm.photoError,
                    ),
                    const SizedBox(height: 24),

                    // 名称输入
                    NameInputSection(
                      initialValue: vm.name,
                      onChanged: vm.setName,
                    ),
                    const SizedBox(height: 24),

                    // 主人称呼
                    OwnerNicknameSection(
                      selectedNickname: vm.ownerNickname,
                      onSelected: vm.setOwnerNickname,
                    ),
                    const SizedBox(height: 24),

                    // 生日选择
                    BirthdayPickerSection(
                      selectedDate: vm.birthday,
                      onDateSelected: vm.setBirthday,
                    ),
                    const SizedBox(height: 24),

                    // 性别选择
                    GenderSelectorSection(
                      selectedGender: vm.gender,
                      onSelected: vm.setGender,
                    ),
                    const SizedBox(height: 24),

                    // 性格选择
                    PersonalitySelectorSection(
                      selectedPersonality: vm.personality,
                      onSelected: vm.setPersonality,
                    ),
                  ],
                ),
              ),
            ),

            // 底部按钮
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: vm.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF8B4513)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: vm.isValid && !vm.isSubmitting
                          ? () => _handleSave(context, vm)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                              '保存',
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
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave(
    BuildContext context,
    EditProfileViewModel vm,
  ) async {
    final updatedPet = await vm.saveProfile();

    if (updatedPet != null && context.mounted) {
      Navigator.of(context).pop(updatedPet);
    }
  }
}
