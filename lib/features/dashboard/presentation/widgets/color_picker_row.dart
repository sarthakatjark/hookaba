import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

class ColorPickerRow extends StatelessWidget {
  final String label;
  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback? onAddColor;
  final double colorSize;
  final double spacing;
  final bool showLabel;
  final bool showSelectedIndicator;

  const ColorPickerRow({
    super.key,
    required this.label,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
    this.onAddColor,
    this.colorSize = 28,
    this.spacing = 8,
    this.showLabel = true,
    this.showSelectedIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Text(
            label,
            style: AppFonts.audiowideStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        if (showLabel) SizedBox(height: spacing),
        Row(
          children: [
            if (showSelectedIndicator)
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ...colors.map((color) => GestureDetector(
                  onTap: () => onColorSelected(color),
                  child: Container(
                    margin: EdgeInsets.only(right: spacing),
                    width: colorSize,
                    height: colorSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == color
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                )),
            GestureDetector(
              onTap: () async {
                final Color? picked = await showColorPickerDialog(
                  context,
                  selectedColor,
                  title: const Text('Pick a color'),
                  showColorCode: true,
                  colorCodeHasColor: true,
                  pickersEnabled: const <ColorPickerType, bool>{
                    ColorPickerType.wheel: true,
                  },
                );
                if (picked != null && picked != selectedColor) {
                  onColorSelected(picked);
                }
              },
              child: Container(
                width: colorSize,
                height: colorSize,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 