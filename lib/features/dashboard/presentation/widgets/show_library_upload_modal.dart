import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hookaba/core/common_widgets/primary_snackbar.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/features/dashboard/data/models/library_item_model.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';

void showLibraryUploadModal(BuildContext context, LibraryItemModel item, DashboardCubit dashboardCubit) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF081122),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    isScrollControlled: true,
    builder: (context) {
      return HookBuilder(
        builder: (context) {
          final uploadStatus = useState<String>('idle'); // idle, uploading, success, error
          final errorMessage = useState<String?>('');
          final hasStartedUpload = useRef(false);

          useEffect(() {
            if (!hasStartedUpload.value) {
              hasStartedUpload.value = true;
              uploadStatus.value = 'uploading';
              errorMessage.value = '';
              dashboardCubit.uploadLibraryImageToBle(
                item,
              ).then((_) {
                uploadStatus.value = 'success';
                showPrimarySnackbar(context, 'Upload sent to device!');
              }).catchError((e) {
                uploadStatus.value = 'error';
                errorMessage.value = e.toString();
                showPrimarySnackbar(context, 'Upload failed: $e');
              });
            }
            return null;
          }, []);

          return BlocBuilder<DashboardCubit, DashboardState>(
            bloc: dashboardCubit,
            builder: (context, state) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 0,
                  right: 0,
                  top: 32,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          "SEND TO DEVICE",
                          style: AppFonts.dashHorizonStyle(fontSize: 22, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(item.imageUrl, height: 120, fit: BoxFit.cover)
                            : const Icon(Icons.image, size: 70, color: Colors.white24),
                      ),
                      const SizedBox(height: 16),
                      if (uploadStatus.value == 'uploading')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "Uploading to BLE device...",
                              style: AppFonts.audiowideStyle(fontSize: 14, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: state.uploadProgress,
                              color: Colors.blueAccent,
                              backgroundColor: Colors.white12,
                              minHeight: 8,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.uploadProgress != null
                                  ? "${(state.uploadProgress! * 100).toStringAsFixed(0)}%"
                                  : "0%",
                              style: AppFonts.audiowideStyle(fontSize: 14, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      else if (uploadStatus.value == 'success')
                        Column(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 40),
                            const SizedBox(height: 12),
                            Text("Upload complete!",
                                style: AppFonts.audiowideStyle(
                                    fontSize: 14, color: Colors.green)),
                          ],
                        )
                      else if (uploadStatus.value == 'error')
                        Column(
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 40),
                            const SizedBox(height: 12),
                            Text(errorMessage.value ?? "Upload failed",
                                style: AppFonts.audiowideStyle(
                                    fontSize: 14, color: Colors.red)),
                          ],
                        ),
                      // No button, upload starts automatically
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
} 