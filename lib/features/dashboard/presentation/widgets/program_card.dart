import 'package:flutter/material.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

class ProgramCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const ProgramCard(this.title, this.icon, this.iconColor, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A33),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: AppFonts.dashHorizonStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 