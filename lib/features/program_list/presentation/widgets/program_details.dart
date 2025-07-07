import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cubit/program_list_state.dart';

class ProgramDetails extends HookWidget {
  final Program program;
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
    final loops = useState(program.loops);
    final playTime = useState(program.playTime);

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
                  child: Center(
                    child: Text(
                      program.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
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
                      'Loop',
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
                  'Views',
                  style: TextStyle(color: Colors.white),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white),
                      onPressed: () {
                        if (loops.value > 1) {
                          loops.value--;
                          onUpdateSettings(loops.value, playTime.value);
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1A33),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${loops.value} loops',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        loops.value++;
                        onUpdateSettings(loops.value, playTime.value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Play Time',
                  style: TextStyle(color: Colors.white),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white),
                      onPressed: () {
                        if (playTime.value > 1) {
                          playTime.value--;
                          onUpdateSettings(loops.value, playTime.value);
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1A33),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${playTime.value} sec',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        playTime.value++;
                        onUpdateSettings(loops.value, playTime.value);
                      },
                    ),
                  ],
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
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onUpdateSettings(loops.value, playTime.value);
                      onClose();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Confirm'),
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