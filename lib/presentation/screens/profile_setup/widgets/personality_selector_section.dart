import 'package:flutter/material.dart';
import '../../../../data/models/pet.dart';

/// 性格选择 Section
class PersonalitySelectorSection extends StatelessWidget {
  final PetPersonality? selectedPersonality;
  final Function(PetPersonality) onSelected;

  const PersonalitySelectorSection({
    Key? key,
    required this.selectedPersonality,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✨ Ta的性格是？',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '选择最符合Ta的性格',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: PetPersonality.values.map((personality) {
            return _buildPersonalityCard(personality);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPersonalityCard(PetPersonality personality) {
    final isSelected = selectedPersonality == personality;

    return GestureDetector(
      onTap: () => onSelected(personality),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B4513).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B4513) : const Color(0xFFD2B48C),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              personality.icon,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              personality.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF8B4513) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
