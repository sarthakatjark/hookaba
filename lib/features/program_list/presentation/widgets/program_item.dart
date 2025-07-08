import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

import '../cubit/program_list_state.dart';

class ProgramItem extends StatelessWidget {
  final Program program;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProgramItem({
    super.key,
    required this.program,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A33),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      program.icon,
                      style: AppFonts.dashHorizonStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    program.name,
                    style: AppFonts.dashHorizonStyle(
                      fontSize: 25,
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/images/edit.svg',
                    width: 22,
                    height: 22,
                  ),
                  onPressed: onTap,
                ),
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/images/delete.svg',
                    width: 22,
                    height: 22,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 