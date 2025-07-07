import 'package:flutter/material.dart';
import 'package:hookaba/core/utils/enum.dart' show AnimationType;

class AnimationPickerModal extends StatelessWidget {
  final void Function(AnimationType) onSelected;
  const AnimationPickerModal({Key? key, required this.onSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = [
      _AnimationItem(AnimationType.showNow, Icons.remove_red_eye, 'Show now'),
      _AnimationItem(
          AnimationType.shiftLeft, Icons.keyboard_arrow_left, 'Shift left'),
      _AnimationItem(
          AnimationType.shiftRight, Icons.keyboard_arrow_right, 'Shift right'),
      _AnimationItem(AnimationType.moveUp, Icons.keyboard_arrow_up, 'Move up'),
      _AnimationItem(
          AnimationType.moveDown, Icons.keyboard_arrow_down, 'Move down'),
      _AnimationItem(AnimationType.snow, Icons.ac_unit, 'Snow'),
      _AnimationItem(AnimationType.bubble, Icons.bubble_chart, 'Bubble'),
      _AnimationItem(AnimationType.flicker, Icons.flash_on, 'Flicker'),
      _AnimationItem(
          AnimationType.continueLeftShift, Icons.sync, 'Continue left shift'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF112233),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 6,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const Text('ANIMATION',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              )),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 24,
            crossAxisSpacing: 8,
            physics: const NeverScrollableScrollPhysics(),
            children: items
                .map((item) => GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelected(item.type);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon, color: Colors.white, size: 36),
                          const SizedBox(height: 8),
                          Text(item.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              )),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}



class _AnimationItem {
  final AnimationType type;
  final IconData icon;
  final String label;
  _AnimationItem(this.type, this.icon, this.label);
}
