import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

class ActionCard extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDisabled;

  const ActionCard({
    super.key,
    required this.title,
    required this.color,
    this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDisabled ? color.withOpacity(0.5) : color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    title == "Draw"
                        ? 'assets/images/paint-board.svg'
                        : 'assets/images/${title.toLowerCase()}.svg',
                    width: 28,
                    height: 28,
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: AppFonts.audiowideStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 