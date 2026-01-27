import 'package:flutter/material.dart';

/// 主人称呼 Section
class OwnerNicknameSection extends StatelessWidget {
  final String selectedNickname;
  final Function(String) onSelected;

  const OwnerNicknameSection({
    Key? key,
    required this.selectedNickname,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final predefinedOptions = ['主人', '铲屎官', '爸爸', '妈妈'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🗣️ Ta希望怎么称呼你？',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '选择或自定义称呼',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...predefinedOptions.map((option) => _buildOptionChip(
                  option,
                  isSelected: selectedNickname == option,
                  onTap: () => onSelected(option),
                )),
            _buildOptionChip(
              '自定义...',
              isSelected: !predefinedOptions.contains(selectedNickname),
              onTap: () => _showCustomDialog(context),
            ),
          ],
        ),
        if (!predefinedOptions.contains(selectedNickname) &&
            selectedNickname.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B4513),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF8B4513)),
                const SizedBox(width: 8),
                Text(
                  '自定义称呼：$selectedNickname',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionChip(String label, {required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B4513) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B4513) : const Color(0xFFD2B48C),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
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
