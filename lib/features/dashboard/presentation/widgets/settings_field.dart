import 'package:flutter/material.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

class SettingsField extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double step;
  final int decimals;

  const SettingsField({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
    this.step = 1.0,
    this.decimals = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.audiowideStyle(
            color: const Color(0xFFB0B8C1),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1929),
            border: Border.all(
              color: const Color(0xFF1E5AFF),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                onPressed: () => onChanged((value - step).clamp(min, max)),
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                value.toStringAsFixed(decimals),
                style: AppFonts.audiowideStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                onPressed: () => onChanged((value + step).clamp(min, max)),
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 