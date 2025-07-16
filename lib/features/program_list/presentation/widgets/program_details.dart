import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
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
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      'Program',
                      style: TextStyle(color: Colors.grey[400]),
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
                const Text(
                  'Details',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${program.id}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'JSON Command: ${program.jsonCommand}',
                  style: const TextStyle(color: Colors.white),
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
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 