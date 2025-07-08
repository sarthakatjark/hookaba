import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:image_picker/image_picker.dart';

class SplitScreenUploadModal extends StatelessWidget {
  const SplitScreenUploadModal({
    Key? key,
    required this.onImageSelected,
  }) : super(key: key);

  final void Function(XFile?) onImageSelected;

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<XFile?> pickedFile = ValueNotifier<XFile?>(null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("UPLOAD",
              style: AppFonts.dashHorizonStyle(
                  fontSize: 22, color: Colors.white)),
          const SizedBox(height: 24),
          DottedBorder(
            options: const RoundedRectDottedBorderOptions(
              dashPattern: [5, 5],
              strokeWidth: 1,
              padding: EdgeInsets.all(16),
              radius: Radius.circular(16),
              color: Colors.blueAccent,
            ),
            child: Column(
              children: [
                ValueListenableBuilder<XFile?>(
                  valueListenable: pickedFile,
                  builder: (context, file, _) {
                    if (file != null) {
                      final lower = file.path.toLowerCase();
                      if (lower.endsWith('.png') ||
                          lower.endsWith('.jpg') ||
                          lower.endsWith('.jpeg') ||
                          lower.endsWith('.gif')) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Image.file(
                            File(file.path),
                            height: 50,
                            fit: BoxFit.contain,
                          ),
                        );
                      }
                    }
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Icon(Icons.folder,
                          size: 48, color: Colors.blueAccent),
                    );
                  },
                ),
                Text(
                  "Upload your images/videos/animations",
                  style: AppFonts.audiowideStyle(
                      fontSize: 14, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Please upload files up to 8MB in size.",
                  style: AppFonts.audiowideStyle(
                      fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<XFile?>(
                  valueListenable: pickedFile,
                  builder: (context, file, _) => ElevatedButton(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final file = await picker.pickImage(
                          source: ImageSource.gallery);
                      if (file != null) {
                        pickedFile.value = file;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected: ${file.name}'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      file == null ? "Browse File" : "Change File",
                      style: AppFonts.dashHorizonStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ValueListenableBuilder<XFile?>(
            valueListenable: pickedFile,
            builder: (context, file, _) => PrimaryButton(
              onPressed: file == null
                  ? () {}
                  : () {
                      onImageSelected(file);
                      Navigator.of(context).pop();
                    },
              text: 'Apply',
              loading: false,
            ),
          ),
        ],
      ),
    );
  }
} 