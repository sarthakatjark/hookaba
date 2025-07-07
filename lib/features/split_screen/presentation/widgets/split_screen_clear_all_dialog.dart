import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplitScreenClearAllDialog extends StatelessWidget {
  const SplitScreenClearAllDialog({Key? key, required this.onConfirm, required this.onCancel}) : super(key: key);

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF081122),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text(
              'CLEAR ALL',
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 20),
             Text(
              'Are you sure you want to clear the added section?',
              style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onCancel,
                  child: Text('No', style: GoogleFonts.orbitron(color: Colors.blue, fontSize: 16)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onConfirm,
                  child: Text('Yes', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 