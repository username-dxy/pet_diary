import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../data/models/pet.dart';

/// Profile 头部组件
class ProfileHeaderWidget extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onEditTap;

  const ProfileHeaderWidget({
    Key? key,
    required this.pet,
    this.onEditTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          // 头像和编辑按钮行
          Row(
            children: [
              // 头像
              _buildAvatar(),
              const SizedBox(width: 20),
              // 名称和物种
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSpeciesText(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 编辑按钮
              if (onEditTap != null)
                IconButton(
                  onPressed: onEditTap,
                  icon: const Icon(Icons.edit_outlined),
                  color: const Color(0xFF8B4513),
                  iconSize: 24,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar() {
    if (pet.profilePhotoPath != null && pet.profilePhotoPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.file(
          File(pet.profilePhotoPath!),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderAvatar();
          },
        ),
      );
    }

    return _buildPlaceholderAvatar();
  }

  /// 构建占位头像
  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFD2B48C).withOpacity(0.3),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: const Color(0xFFD2B48C),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.pets,
        size: 50,
        color: Color(0xFF8B4513),
      ),
    );
  }

  /// 获取物种文本
  String _getSpeciesText() {
    final speciesMap = {
      'cat': '猫咪',
      'dog': '狗狗',
    };

    final speciesText = speciesMap[pet.species] ?? pet.species;

    if (pet.breed != null && pet.breed!.isNotEmpty) {
      return '$speciesText · ${pet.breed}';
    }

    return speciesText;
  }
}
