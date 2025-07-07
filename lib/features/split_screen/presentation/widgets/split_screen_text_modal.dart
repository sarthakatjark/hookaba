import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';

class SplitScreenTextModal extends StatelessWidget {
  const SplitScreenTextModal({Key? key, required this.textController, required this.onApply, required this.onFormat}) : super(key: key);

  final TextEditingController textController;
  final VoidCallback onApply;
  final void Function(TextStyle style) onFormat;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('TEXT', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 20),
            DottedBorder(
              options: const RoundedRectDottedBorderOptions(
                dashPattern: [5, 5],
                strokeWidth: 1,
                padding: EdgeInsets.zero,
                radius: Radius.circular(16),
                color: Colors.blueAccent,
              ),
              child:
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF112244),
              ),
              child: TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                maxLines: 2,
                decoration:  InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Write your text here...',
                  hintStyle: GoogleFonts.orbitron(color: Colors.white38),
                ),
              ),
            ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.format_italic, color: Colors.white),
                  onPressed: () => onFormat(const TextStyle(fontStyle: FontStyle.italic)),
                ),
                IconButton(
                  icon: const Icon(Icons.format_bold, color: Colors.white),
                  onPressed: () => onFormat(const TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.format_underline, color: Colors.white),
                  onPressed: () => onFormat(const TextStyle(decoration: TextDecoration.underline)),
                ),
                IconButton(
                  icon: const Icon(Icons.format_align_left, color: Colors.white),
                  onPressed: () => onFormat(const TextStyle()),
                ),
                IconButton(
                  icon: const Icon(Icons.format_align_center, color: Colors.white),
                  onPressed: () => onFormat(const TextStyle()),
                ),
                IconButton(
                  icon: const Icon(Icons.format_align_right, color: Colors.white),
                  onPressed: () => onFormat(const TextStyle()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: onApply,
              text: 'Apply',
            ),
          ],
        ),
      ),
    );
  }
} 