import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../cubit/split_screen_state.dart';

typedef SplitTapCallback = void Function(int index);

class SplitScreenView extends HookWidget {
  final SplitScreenMode mode;
  final double splitRatio;
  final Color leftScreenColor;
  final Color rightScreenColor;
  final bool isLeftScreenActive;
  final double brightness;
  final ValueChanged<double> onSplitRatioChanged;
  final VoidCallback onScreenTapped;
  final SplitTapCallback? onSplitTapped;
  final List<SplitScreenItem>? splits;
  final int? focusedIndex;

  const SplitScreenView({
    super.key,
    required this.mode,
    required this.splitRatio,
    required this.leftScreenColor,
    required this.rightScreenColor,
    required this.isLeftScreenActive,
    required this.brightness,
    required this.onSplitRatioChanged,
    required this.onScreenTapped,
    this.onSplitTapped,
    this.splits,
    this.focusedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDragging = useState(false);
    return GestureDetector(
      onTapUp: (_) => onScreenTapped(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final width = constraints.maxWidth;
            final splitPosition = height * splitRatio;
            return Stack(
              children: [
                // Top split
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  height: mode == SplitScreenMode.single ? height : splitPosition,
                  child: GestureDetector(
                    onTap: () => onSplitTapped?.call(0),
                    child: _buildSplit(
                      context,
                      index: 0,
                      item: splits != null && splits!.length > 0 ? splits![0] : null,
                      color: leftScreenColor,
                      isActive: focusedIndex == 0,
                      brightness: brightness,
                      isTop: true,
                    ),
                  ),
                ),
                // Bottom split
                if (mode == SplitScreenMode.dual)
                  Positioned(
                    left: 0,
                    top: splitPosition,
                    right: 0,
                    height: height - splitPosition,
                    child: GestureDetector(
                      onTap: () => onSplitTapped?.call(1),
                      child: _buildSplit(
                        context,
                        index: 1,
                        item: splits != null && splits!.length > 1 ? splits![1] : null,
                        color: rightScreenColor,
                        isActive: focusedIndex == 1,
                        brightness: brightness,
                        isTop: false,
                      ),
                    ),
                  ),
                // Split handle
                if (mode == SplitScreenMode.dual)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: splitPosition - 12,
                    height: 24,
                    child: GestureDetector(
                      onVerticalDragStart: (_) => isDragging.value = true,
                      onVerticalDragEnd: (_) => isDragging.value = false,
                      onVerticalDragUpdate: (details) {
                        final newRatio = (splitPosition + details.delta.dy) / height;
                        onSplitRatioChanged(newRatio);
                      },
                      child: Container(
                        color: isDragging.value
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.transparent,
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSplit(
    BuildContext context, {
    required int index,
    SplitScreenItem? item,
    required Color color,
    required bool isActive,
    required double brightness,
    required bool isTop,
  }) {
    final borderRadius = BorderRadius.only(
      topLeft: isTop ? const Radius.circular(12) : Radius.zero,
      topRight: isTop ? const Radius.circular(12) : Radius.zero,
      bottomLeft: !isTop ? const Radius.circular(12) : Radius.zero,
      bottomRight: !isTop ? const Radius.circular(12) : Radius.zero,
    );
    Widget content = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
      child: item == null
          ? _defaultSplitContent(index)
          : (item.image != null
              ? ClipRRect(
                  borderRadius: borderRadius,
                  child: Image(
                    image: item.image!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : (item.text != null
                  ? Center(
                      child: Text(
                        item.text!,
                        style: item.textStyle ?? const TextStyle(color: Colors.white, fontSize: 32),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _defaultSplitContent(index))),
    );
    if (isActive) {
      content = CustomPaint(
        painter: _DottedBorderPainter(color: Colors.blue, isActive: true),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _defaultSplitContent(int index) {
    return Center(
      child: Text(
        (index + 1).toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final bool isActive;
  _DottedBorderPainter({required this.color, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(isActive ? 0.8 : 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ));
    _drawDashedPath(canvas, path, paint, dashWidth, dashSpace);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashWidth, double dashSpace) {
    final PathMetrics pathMetrics = path.computeMetrics();
    for (final PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final double next = distance + dashWidth;
        canvas.drawPath(
          pathMetric.extractPath(distance, next),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 