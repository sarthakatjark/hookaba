import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_bottom_nav_bar.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../cubit/split_screen_cubit.dart';
import '../cubit/split_screen_state.dart';
import '../widgets/split_screen_text_modal.dart';
import '../widgets/split_screen_upload_modal.dart';
import '../widgets/split_screen_view.dart';

class SplitScreenPreviewPage extends HookWidget {
  const SplitScreenPreviewPage({
    Key? key,
    required this.templateIndex,
    required this.initialRatio,
    required this.onUpload,
    required this.onText,
    required this.onClear,
  }) : super(key: key);

  final int templateIndex;
  final double initialRatio;
  final VoidCallback onUpload;
  final VoidCallback onText;
  final VoidCallback onClear;
  //final VoidCallback onConfirm;

  double getSplitRatio(int templateIndex, double customRatio) {
    switch (templateIndex) {
      case 0:
        return 0.5; // 1:1
      case 1:
        return 0.25; // 1:3
      case 2:
        return 0.75; // 3:1
      default:
        return customRatio; // Custom
    }
  }

  bool getIsCustom(int templateIndex) => templateIndex == 3;

  @override
  Widget build(BuildContext context) {
    final customRatio = useState(initialRatio);
    final focusedSplit = useState(0);
    final cubit = context.read<SplitScreenCubit>();
    final previewKey = useMemoized(() => GlobalKey(), []);

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final isGif = file.path.toLowerCase().endsWith('.gif');
        final imageProvider = FileImage(File(file.path));
        cubit.setSplitImage(focusedSplit.value, imageProvider, isGif: isGif);
      }
    }

    Future<void> pickText() async {
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF081122),
          title: Text('Enter Text',
              style: AppFonts.audiowideStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                hintText: 'Type here...',
                hintStyle: TextStyle(color: Colors.white38)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (result != null && result.trim().isNotEmpty) {
        cubit.setSplitText(focusedSplit.value, result.trim(),
            const TextStyle(color: Colors.white, fontSize: 24));
      }
    }

    Future<void> onConfirm() async {
      final dashboardCubit = context.read<DashboardCubit>();
      await cubit.handleSplitAndUpload(
        context,
        dashboardCubit,
        splitRatio: getSplitRatio(templateIndex, customRatio.value),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF081122),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/dashboard/split-screen'),
        ),
        title: Text(
          'SPLIT SCREEN',
          style: AppFonts.dashHorizonStyle(
              fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a format to split the LED screens in few sections.',
              style:
                  AppFonts.audiowideStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: RepaintBoundary(
                    key: previewKey,
                    child: BlocBuilder<SplitScreenCubit, SplitScreenState>(
                      builder: (context, state) {
                        return SplitScreenView(
                          mode: SplitScreenMode.dual,
                          splitRatio:
                              getSplitRatio(templateIndex, customRatio.value),
                          leftScreenColor: Colors.black,
                          rightScreenColor: Colors.blueGrey.shade900,
                          isLeftScreenActive: focusedSplit.value == 0,
                          brightness: 1.0,
                          onSplitRatioChanged: getIsCustom(templateIndex)
                              ? (r) => customRatio.value = r.clamp(0.1, 0.9)
                              : (_) {},
                          onScreenTapped: () {},
                          onSplitTapped: (index) {
                            focusedSplit.value = index;
                          },
                          splits: state.splits,
                          focusedIndex: focusedSplit.value,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF081122),
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      isScrollControlled: true,
                      builder: (ctx) {
                        return SplitScreenUploadModal(
                          onImageSelected: (file) {
                            if (file != null) {
                              final imageProvider = FileImage(File(file.path));
                              cubit.setSplitImage(
                                  focusedSplit.value, imageProvider);
                            }
                            //Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  },
                  icon: SvgPicture.asset('assets/images/upload.svg',
                      width: 28, height: 28, color: Colors.white),
                ),
                IconButton(
                  onPressed: () async {
                    final controller = TextEditingController();
                    await showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF081122),
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      isScrollControlled: true,
                      builder: (ctx) {
                        return SplitScreenTextModal(
                          textController: controller,
                          onApply: () {
                            final text = controller.text.trim();
                            if (text.isNotEmpty) {
                              cubit.setSplitText(
                                  focusedSplit.value,
                                  text,
                                  const TextStyle(
                                      color: Colors.white, fontSize: 24));
                            }
                            Navigator.of(ctx).pop();
                          },
                          onFormat: (style) {
                            // Optionally handle formatting here
                          },
                        );
                      },
                    );
                  },
                  icon: SvgPicture.asset('assets/images/text.svg',
                      width: 28, height: 28, color: Colors.white),
                ),
                IconButton(
                  onPressed: () => cubit.clearSplit(focusedSplit.value),
                  icon: SvgPicture.asset('assets/images/clear.svg',
                      width: 28, height: 28, color: Colors.redAccent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('Views', style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 4),
                    Text('3 loops', style: TextStyle(color: Colors.white)),
                  ],
                ),
                Column(
                  children: [
                    Text('Play time', style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 4),
                    Text('1.0 sec', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              onPressed: onConfirm,
              text: 'Confirm',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: PrimaryBottomNavBar(
        currentIndex: 0,
        onTap: (_) {},
      ),
    );
  }
}

Future<String?> _findLatestMergedGif() async {
  final dir = await getApplicationDocumentsDirectory();
  final files = Directory(dir.path)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.contains('merged_debug_') && f.path.endsWith('.gif'))
      .toList();
  if (files.isEmpty) return null;
  files.sort((a, b) => b.path.compareTo(a.path)); // newest first
  return files.first.path;
}
