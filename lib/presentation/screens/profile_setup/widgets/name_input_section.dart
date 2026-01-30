import 'package:flutter/material.dart';

/// 名称输入 Section - Figma 木质风格
class NameInputSection extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final double iconSize;

  const NameInputSection({
    Key? key,
    required this.initialValue,
    required this.onChanged,
    this.iconSize = 40,
  }) : super(key: key);

  @override
  State<NameInputSection> createState() => _NameInputSectionState();
}

class _NameInputSectionState extends State<NameInputSection> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/profile_setup/icon_tag.png',
          width: widget.iconSize,
          height: widget.iconSize,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '宠物叫什么名字？',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C3D1A),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 33,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/images/profile_setup/input_field.jpg',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: TextField(
                        controller: _controller,
                        onChanged: widget.onChanged,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5C3D1A),
                        ),
                        decoration: const InputDecoration(
                          hintText: '输入宠物名称...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFAA8866),
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
