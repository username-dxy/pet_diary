import 'package:flutter/material.dart';
import '../../../../data/models/pet.dart';

/// 性别选择 Section - Figma 木质风格
class GenderSelectorSection extends StatelessWidget {
  final PetGender selectedGender;
  final Function(PetGender) onSelected;
  final double iconSize;

  const GenderSelectorSection({
    Key? key,
    required this.selectedGender,
    required this.onSelected,
    this.iconSize = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/profile_setup/icon_sex.png',
          width: iconSize,
          height: iconSize,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TA是男孩还是女孩？',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C3D1A),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PetGender.values.map((gender) {
                  final isSelected = selectedGender == gender;
                  return _WoodChip(
                    label: gender.displayName,
                    isSelected: isSelected,
                    onTap: () => onSelected(gender),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WoodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _WoodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        height: 33,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                isSelected
                    ? 'assets/images/profile_setup/chip_selected.jpg'
                    : 'assets/images/profile_setup/chip_unselected.jpg',
                width: 60,
                height: 33,
                fit: BoxFit.fill,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: const Color(0xFF5C3D1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
