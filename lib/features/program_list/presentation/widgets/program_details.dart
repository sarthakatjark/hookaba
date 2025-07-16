import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/features/program_list/data/models/local_program_model.dart';

class ProgramDetails extends HookWidget {
  final LocalProgramModel program;
  final VoidCallback onClose;
  final void Function(int loops, int playTime) onUpdateSettings;

  const ProgramDetails({
    super.key,
    required this.program,
    required this.onClose,
    required this.onUpdateSettings,
  });

  @override
  Widget build(BuildContext context) {
    // No loops/playTime in LocalProgramModel, so just show details
    return Container(
      color: const Color(0xFF081122),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      // Display a placeholder icon or the image from bmpBytes
                      child: Icon(Icons.apps, size: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.name,
                        style: AppFonts.dashHorizonStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Program',
                        style: AppFonts.audiowideStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: AppFonts.dashHorizonStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${program.id}',
                    style: AppFonts.audiowideStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'JSON Command: ${program.jsonCommand}',
                    style: AppFonts.audiowideStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onClose,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: AppFonts.audiowideStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 