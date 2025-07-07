import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ColorPicker extends HookWidget {
  final Color selectedColor;
  final List<Color> colors;
  final ValueChanged<Color> onColorSelected;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.colors,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0D1A33),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = color == selectedColor;

          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 