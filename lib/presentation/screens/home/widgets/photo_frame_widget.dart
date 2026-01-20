import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pet_diary/data/models/pet.dart';

/// 相框（我的页面入口）
class PhotoFrameWidget extends StatelessWidget {
  final Pet? pet;

  const PhotoFrameWidget({
    super.key,
    this.pet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildPetPhoto(),
      ),
    );
  }

  Widget _buildPetPhoto() {
    if (pet?.profilePhotoPath != null) {
      return Image.file(
        File(pet!.profilePhotoPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return const Icon(
      Icons.pets,
      size: 40,
      color: Colors.grey,
    );
  }
}