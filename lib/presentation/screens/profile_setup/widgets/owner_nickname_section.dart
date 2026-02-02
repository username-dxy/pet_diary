import 'package:flutter/material.dart';

/// 主人称呼 Section - Figma 木质风格
class OwnerNicknameSection extends StatelessWidget {
  final String selectedNickname;
  final Function(String) onSelected;
  final double iconSize;

  const OwnerNicknameSection({
    Key? key,
    required this.selectedNickname,
    required this.onSelected,
    this.iconSize = 40,
  }) : super(key: key);

  static const _predefinedOptions = ['主人', '铲屎官', '妈妈'];

  @override
  Widget build(BuildContext context) {
    final isCustom = selectedNickname.isNotEmpty &&
        !_predefinedOptions.contains(selectedNickname);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/profile_setup/icon_dialogue.png',
          width: iconSize,
          height: iconSize,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '希望TA怎么称呼您？',
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
                children: [
                  ..._predefinedOptions.map((option) {
                    return _WoodChip(
                      label: option,
                      isSelected: selectedNickname == option,
                      onTap: () => onSelected(option),
                    );
                  }),
                  _WoodChip(
                    label: isCustom ? selectedNickname : '自定义',
                    isSelected: isCustom,
                    onTap: () => _showCustomDialog(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showCustomDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自定义称呼'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入自定义称呼...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      onSelected(result);
    }
  }
}

/// 木质风格选项 Chip
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
