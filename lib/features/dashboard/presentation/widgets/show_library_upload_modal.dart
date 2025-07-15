import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookaba/core/common_widgets/primary_snackbar.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/core/utils/enum.dart';
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
      return BlocBuilder<DashboardCubit, DashboardState>(
        bloc: dashboardCubit,
        builder: (context, state) {
          final isUploading = state.status == DashboardStatus.loading;
          final isSuccess = state.status == DashboardStatus.success;
          final isError = state.status == DashboardStatus.error;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("SEND TO DEVICE",
                    style: AppFonts.dashHorizonStyle(
                        fontSize: 22, color: Colors.white)),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(item.imageUrl, height: 120, fit: BoxFit.cover)
                      : const Icon(Icons.image, size: 70, color: Colors.white24),
                ),
                const SizedBox(height: 16),
                if (isUploading)
                  Column(
                    children: [
                      const CircularProgressIndicator(color: Colors.blueAccent),
                      const SizedBox(height: 12),
                      Text("Uploading to BLE device...",
                          style: AppFonts.audiowideStyle(
                              fontSize: 14, color: Colors.white)),
                    ],
                  )
                else if (isSuccess)
                  Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 40),
                      const SizedBox(height: 12),
                      Text("Upload complete!",
                          style: AppFonts.audiowideStyle(
                              fontSize: 14, color: Colors.green)),
                    ],
                  )
                else if (isError)
                  Column(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 40),
                      const SizedBox(height: 12),
                      Text(state.errorMessage ?? "Upload failed",
                          style: AppFonts.audiowideStyle(
                              fontSize: 14, color: Colors.red)),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await dashboardCubit.uploadLibraryImageToBle(item);
                        showPrimarySnackbar(context, 'Upload sent to device!');
                      } catch (e) {
                        showPrimarySnackbar(context, 'Upload failed: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      "Send to Device",
                      style: AppFonts.dashHorizonStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );
    },
  );
} 