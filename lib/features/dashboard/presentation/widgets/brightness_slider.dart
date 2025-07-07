import 'package:flutter/material.dart';

class BrightnessSlider extends StatelessWidget {
  const BrightnessSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.brightness_low, color: Colors.white),
        Expanded(
          child: Slider(
            value: 0.5,
            onChanged: (value) {},
            activeColor: Colors.blue,
            inactiveColor: Colors.grey[700],
          ),
        ),
      ],
    );
  }
} 