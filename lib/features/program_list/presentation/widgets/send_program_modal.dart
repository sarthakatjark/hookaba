import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/common_widgets/primary_snackbar.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/features/program_list/data/models/local_program_model.dart';
import 'package:hookaba/features/program_list/presentation/cubit/program_list_cubit.dart';

class SendProgramModal extends HookWidget {
  final LocalProgramModel program;
  const SendProgramModal({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    final loading = useState(false);
    final uploadProgress = context.select<ProgramListCubit, double?>((cubit) => cubit.state.uploadProgress);
    // Estimate time remaining (fake: 1.0 = 60s, 0.0 = 0s)
    final secondsRemaining = uploadProgress != null ? max(0, (60 * (1 - uploadProgress)).round()) : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (uploadProgress != null && uploadProgress > 0 && uploadProgress < 1)
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                painter: _DashedBorderPainter(color: Colors.blueAccent, borderRadius: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPLOAD',
                        style: AppFonts.audiowideStyle(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if ((program.gifBase64 != null && program.gifBase64!.isNotEmpty))
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Image.memory(
                                base64Decode(program.gifBase64!),
                                height: 48,
                                width: 48,
                                fit: BoxFit.contain,
                              ),
                            )
                          else if (program.bmpBytes.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Image.memory(
                                program.bmpBytes,
                                height: 48,
                                width: 48,
                                fit: BoxFit.contain,
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bringing your vibe to life...',
                                  style: AppFonts.dashHorizonStyle(fontSize: 16, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(uploadProgress * 100).toStringAsFixed(0)}%  B7 $secondsRemaining seconds remaining',
                                  style: AppFonts.audiowideStyle(fontSize: 13, color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: uploadProgress,
                                  minHeight: 5,
                                  backgroundColor: Colors.grey[800],
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Column(
                            children: [
                              Icon(Icons.pause_circle_filled, color: Colors.white70, size: 28),
                              SizedBox(height: 8),
                              Icon(Icons.cancel, color: Colors.redAccent, size: 28),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (uploadProgress == null || uploadProgress == 0 || uploadProgress >= 1)
            Column(
              children: [
                if ((program.gifBase64 != null && program.gifBase64!.isNotEmpty))
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Image.memory(
                      base64Decode(program.gifBase64!),
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  )
                else if (program.bmpBytes.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Image.memory(
                      program.bmpBytes,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                Text(
                  program.name,
                  style: AppFonts.dashHorizonStyle(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
              ],
            ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: uploadProgress != null && uploadProgress > 0 && uploadProgress < 1 ? 'Uploading...' : 'Apply',
            loading: loading.value,
            onPressed: loading.value || (uploadProgress != null && uploadProgress > 0 && uploadProgress < 1)
                ? null
                : () async {
                    loading.value = true;
                    //Navigator.of(context).pop();
                    try {
                      await context.read<ProgramListCubit>().sendProgramToDevice(program);
                      if (!context.mounted) return;
                      showPrimarySnackbar(context, 'Program sent to device!');
                    } catch (e) {
                      if (!context.mounted) return;
                      showPrimarySnackbar(context, 'Failed to send: $e', colorTint: Colors.red, icon: Icons.error);
                    } finally {
                      loading.value = false;
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    this.strokeWidth = 1.5,
    this.dashLength = 6,
    this.gapLength = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    _drawDashedRRect(canvas, rrect, paint);
  }

  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint) {
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = dashLength;
        final next = distance + len;
        final extractLen = next < metric.length ? len : metric.length - distance;
        canvas.drawPath(
          metric.extractPath(distance, distance + extractLen),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 