import 'package:flutter/material.dart';
import 'package:hookaba/core/utils/app_colors.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color? color;
  final TextStyle? textStyle;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.color,
    this.textStyle,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: loading
              ? const CircularProgressIndicator(color: AppColors.text)
              : Text(
                  text,
                  style: textStyle ?? AppFonts.dashHorizonStyle(
                    fontSize: 18,
                    color: AppColors.text,
                  ),
                ),
        ),
      ),
    );
  }
} 