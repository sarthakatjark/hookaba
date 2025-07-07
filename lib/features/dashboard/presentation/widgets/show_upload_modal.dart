import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/utils/app_colors.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:image_picker/image_picker.dart';

void showUploadModal(
    BuildContext context,
    BluetoothDevice device,
    Future<void> Function(BluetoothDevice) sendPowerOffSequence,
    DashboardCubit dashboardCubit) {
  final ValueNotifier<XFile?> pickedFile = ValueNotifier<XFile?>(null);
  final ValueNotifier<bool> isUploading = ValueNotifier<bool>(false);

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF081122),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    isScrollControlled: true,
    builder: (context) {
      return BlocBuilder<DashboardCubit, DashboardState>(
        bloc: dashboardCubit,
        builder: (context, state) {
          final isUploadingProgress =
              state.uploadProgress != null && state.uploadProgress! < 1.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("UPLOAD",
                    style: AppFonts.dashHorizonStyle(
                        fontSize: 22, color: Colors.white)),
                const SizedBox(height: 24),
                if (isUploadingProgress)
                  DottedBorder(
                    options: const RoundedRectDottedBorderOptions(
                      dashPattern: [5, 5],
                      strokeWidth: 1,
                      padding: EdgeInsets.all(16),
                      radius: Radius.circular(16),
                      color: Colors.blueAccent,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bringing your vibe to life...",
                          style: AppFonts.orbitron(
                              fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "${(state.uploadProgress! * 100).toStringAsFixed(0)}%",
                              style: AppFonts.orbitron(
                                  fontSize: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ": 30 seconds remaining",
                              style: AppFonts.orbitron(
                                  fontSize: 14, color: Colors.white),
                            ),
                            const Spacer(),
                            const IconButton(
                              icon: Icon(Icons.pause, color: Colors.white),
                              onPressed: null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: state.uploadProgress, color: Colors.blueAccent,),
                      ],
                    ),
                  )
                else ...[
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
                          style: AppFonts.orbitron(
                              fontSize: 14, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Please upload files up to 8MB in size.",
                          style: AppFonts.orbitron(
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
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ValueListenableBuilder<bool>(
                  valueListenable: isUploading,
                  builder: (context, uploading, _) => Builder(
                    builder: (innerContext) => PrimaryButton(
                      loading: uploading || isUploadingProgress,
                      text: "Apply",
                      onPressed: uploading || isUploadingProgress
                          ? () {}
                          : () {
                              if (pickedFile.value == null) {
                                ScaffoldMessenger.of(innerContext).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Please select a file first')),
                                );
                                return;
                              }
                              isUploading.value = true;
                              (() async {
                                try {
                                  await dashboardCubit
                                      .uploadImageOrGif(pickedFile.value!);
                                  ScaffoldMessenger.of(innerContext)
                                      .showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Upload sent to device!')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(innerContext)
                                      .showSnackBar(
                                    SnackBar(
                                        content: Text('Upload failed: $e')),
                                  );
                                } finally {
                                  isUploading.value = false;
                                }
                              })();
                            },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
