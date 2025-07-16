import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

class ProgramCard extends StatelessWidget {
  final String title;
  final Uint8List? imageBytes;
  final String? gifBase64;

  const ProgramCard({
    super.key,
    required this.title,
    required this.imageBytes,
    this.gifBase64,
  });

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
            child: (gifBase64 != null && gifBase64!.isNotEmpty)
                ? Image.memory(
                    base64Decode(gifBase64!),
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  )
                : (imageBytes != null && imageBytes!.isNotEmpty)
                    ? Image.memory(
                        imageBytes!,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.apps, color: Colors.white, size: 28),
          ),
          Expanded(
            child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: AppFonts.dashHorizonStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 