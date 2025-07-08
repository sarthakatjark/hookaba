import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart'
    show DashboardCubit;
import 'package:hookaba/features/dashboard/presentation/widgets/color_picker_row.dart';

class DrawScreen extends HookWidget {
  const DrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedColor = useState(Colors.white);
    final strokeWidth = useState(5.0);
    final points = useState<List<Offset>>([]);
    final canvasKey = useMemoized(() => GlobalKey());
    const gridSize = 64;
    const cellSize = 5.0; // 320 / 64

    // Clear BLE device and local canvas when screen opens
    useEffect(() {
      Future.microtask(() async {
        await context.read<DashboardCubit>().sendBlankCanvas();
        await Future.delayed(const Duration(milliseconds: 100));
        points.value = [];
      });
      return null;
    }, []);

    return Scaffold(
      backgroundColor: const Color(0xFF081122),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding:
                  const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DRAW',
                    style: AppFonts.dashHorizonStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Canvas with grid and border
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E5AFF), width: 1.5),
              ),
              width: 340,
              height: 340,
              child: GestureDetector(
                key: canvasKey,
                onPanUpdate: (details) async {
                  final renderBox = canvasKey.currentContext?.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final localPosition = renderBox.globalToLocal(details.globalPosition);
                    int x = (localPosition.dx / cellSize).floor().clamp(0, gridSize - 1);
                    int y = (localPosition.dy / cellSize).floor().clamp(0, gridSize - 1);

                    points.value = List.from(points.value)..add(Offset(x.toDouble(), y.toDouble()));

                    // Send immediately to BLE (now batched)
                    final color = context.read<DashboardCubit>().colorToBleInt(selectedColor.value);
                    context.read<DashboardCubit>().enqueueDrawPixel(x, y, color);
                  }
                },
                child: CustomPaint(
                  painter: DrawingPainter(
                    points: points.value,
                    color: selectedColor.value,
                    strokeWidth: strokeWidth.value,
                    showGrid: true,
                    cellSize: cellSize,
                  ),
                  size: const Size(320, 320),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Debug button for BLE RTDraw
            
            // Current Color and Color options (replaced with ColorPickerRow)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ColorPickerRow(
                label: 'Current Color',
                colors: const [
                  Colors.black,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.red,
                  Colors.purple,
                  Colors.white,
                ],
                selectedColor: selectedColor.value,
                onColorSelected: (color) => selectedColor.value = color,
                onAddColor: () {/* custom color logic */},
                colorSize: 28,
                spacing: 8,
                showLabel: true,
                showSelectedIndicator: true,
              ),
            ),
            const SizedBox(height: 32),
            // Action buttons
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DrawActionButton(
                      icon: Icons.cleaning_services,
                      label: 'Clean',
                      onTap: () async {
                        await context.read<DashboardCubit>().sendBlankCanvas();
                        await Future.delayed(const Duration(milliseconds: 100));
                        points.value = [];
                      }),
                  _DrawActionButton(
                      icon: Icons.edit_off,
                      label: 'Erase',
                      onTap: () {/* erase logic */}),
                  _DrawActionButton(
                      icon: Icons.save,
                      label: 'Preserve',
                      onTap: () {/* preserve logic */}),
                  _DrawActionButton(
                      icon: Icons.send,
                      label: 'Send',
                      onTap: () {/* send logic */}),
                ],
              ),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool showGrid;
  final double cellSize;

  DrawingPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.showGrid = false,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      final gridPaint = Paint()
        ..color = const Color(0xFF222C3A)
        ..strokeWidth = 0.5;
      const gridSize = 16.0;
      for (double x = 0; x <= size.width; x += cellSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y <= size.height; y += cellSize) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawRect(
        Rect.fromLTWH(point.dx * cellSize, point.dy * cellSize, cellSize, cellSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.showGrid != showGrid ||
      oldDelegate.cellSize != cellSize;
}

class _DrawActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  String? _svgAssetForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'clean':
        return 'assets/images/clean.svg';
      case 'erase':
        return 'assets/images/eraser.svg';
      case 'preserve':
        return 'assets/images/cloud-upload.svg';
      case 'send':
        return 'assets/images/folder.svg';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final svgAsset = _svgAssetForLabel(label);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          if (svgAsset != null)
            SvgPicture.asset(
              svgAsset,
              width: 28,
              height: 28,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            )
          else
            Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppFonts.audiowideStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
