import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

class HookabaSnackbar extends HookWidget {
  final String message;
  final Color colorTint;
  final IconData icon;
  final double topPadding;
  final Duration duration;

  const HookabaSnackbar({
    Key? key,
    required this.message,
    this.colorTint = const Color(0xFFFFD600),
    this.icon = Icons.warning_amber_rounded,
    this.topPadding = 48.0,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 400),
    );
    final fadeAnim = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
    final slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    ));

    useEffect(() {
      controller.forward();
      final timer = Future.delayed(duration, () async {
        await controller.reverse();
      });
      return null;
    }, const []);

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(
          position: slideAnim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: colorTint.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        icon,
                        color: colorTint,
                        size: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      message,
                      style: AppFonts.audiowideStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showPrimarySnackbar(BuildContext context, String message, {Color colorTint = const Color(0xFFFFD600), IconData icon = Icons.warning_amber_rounded, double topPadding = 125.0, Duration duration = const Duration(seconds: 3)}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) => HookabaSnackbar(
      message: message,
      colorTint: colorTint,
      icon: icon,
      topPadding: topPadding,
      duration: duration,
    ),
  );
  overlay.insert(overlayEntry);
  Future.delayed(duration + const Duration(milliseconds: 500), () => overlayEntry.remove());
} 