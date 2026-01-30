import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 生日选择 Section - Figma 木质风格
class BirthdayPickerSection extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final double iconSize;

  const BirthdayPickerSection({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    this.iconSize = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/profile_setup/icon_birthday.png',
          width: iconSize,
          height: iconSize,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TA的生日是？',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C3D1A),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showBirthdayPicker(context),
                child: SizedBox(
                  height: 33,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/images/profile_setup/input_field.jpg',
                          width: double.infinity,
                          height: 33,
                          fit: BoxFit.fill,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          selectedDate != null
                              ? DateFormat('yyyy年MM月dd日').format(selectedDate!)
                              : '点击选择生日',
                          style: TextStyle(
                            fontSize: 13,
                            color: selectedDate != null
                                ? const Color(0xFF5C3D1A)
                                : const Color(0xFFAA8866),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showBirthdayPicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(now.year - 1),
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B4513),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }
}
