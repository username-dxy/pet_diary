import 'package:flutter/material.dart';
import '../../../../data/models/pet.dart';

/// 性别选择 Section
class GenderSelectorSection extends StatelessWidget {
  final PetGender selectedGender;
  final Function(PetGender) onSelected;

  const GenderSelectorSection({
    Key? key,
    required this.selectedGender,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚧️ Ta是男孩还是女孩？',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '选择Ta的性别',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildGenderCard(
                context,
                PetGender.male,
                '♂️',
                '男孩',
                Colors.blue[100]!,
                Colors.blue[700]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderCard(
                context,
                PetGender.female,
                '♀️',
                '女孩',
                Colors.pink[100]!,
                Colors.pink[700]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderCard(
                context,
                PetGender.unknown,
                '⚧️',
                '保密',
                Colors.grey[200]!,
                Colors.grey[700]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard(
    BuildContext context,
    PetGender gender,
    String icon,
    String label,
    Color bgColor,
    Color activeColor,
  ) {
    final isSelected = selectedGender == gender;

    return GestureDetector(
      onTap: () => onSelected(gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFD2B48C),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
