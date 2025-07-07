import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'split_screen_state.dart';

class SplitScreenCubit extends Cubit<SplitScreenState> {
  SplitScreenCubit() : super(const SplitScreenState());

  void toggleMode() {
    emit(state.copyWith(
      mode: state.mode == SplitScreenMode.single
          ? SplitScreenMode.dual
          : SplitScreenMode.single,
    ));
  }

  void updateSplitRatio(double ratio) {
    emit(state.copyWith(splitRatio: ratio.clamp(0.1, 0.9)));
  }

  void updateLeftScreenColor(Color color) {
    emit(state.copyWith(leftScreenColor: color));
  }

  void updateRightScreenColor(Color color) {
    emit(state.copyWith(rightScreenColor: color));
  }

  void toggleActiveScreen() {
    emit(state.copyWith(isLeftScreenActive: !state.isLeftScreenActive));
  }

  void updateBrightness(double brightness) {
    emit(state.copyWith(brightness: brightness.clamp(0.0, 1.0)));
  }

  void updateActiveScreenColor(Color color) {
    if (state.isLeftScreenActive) {
      updateLeftScreenColor(color);
    } else {
      updateRightScreenColor(color);
    }
  }

  // --- Split content logic ---
  void setSplitImage(int index, ImageProvider image, {bool isGif = false}) {
    final updated = List<SplitScreenItem>.from(state.splits);
    updated[index] = SplitScreenItem(image: image, isGif: isGif);
    emit(state.copyWith(splits: updated));
  }

  void setSplitText(int index, String text, TextStyle style) {
    final updated = List<SplitScreenItem>.from(state.splits);
    updated[index] = SplitScreenItem(text: text, textStyle: style);
    emit(state.copyWith(splits: updated));
  }

  void clearSplit(int index) {
    final updated = List<SplitScreenItem>.from(state.splits);
    updated[index] = const SplitScreenItem();
    emit(state.copyWith(splits: updated));
  }

  /// Handles smart split upload logic: GIF+GIF, GIF+Image, GIF+Text → GIF; Image+Image, Image+Text → BMP; Text+Text → sendTextToBle
  Future<void> handleSplitAndUpload(
      BuildContext context, DashboardCubit dashboardCubit,
      {double? splitRatio}) async {
    final splits = state.splits;
    final left = splits[0];
    final right = splits[1];
    final hasGif = left.isGif || right.isGif;
    final hasText = left.text != null || right.text != null;
    final hasImage = left.image != null || right.image != null;
    final ratio = splitRatio ?? state.splitRatio;
    final topHeight = (64 * ratio).round();
    final bottomHeight = 64 - topHeight;

    try {
      if (hasGif) {
        await _combineAndUploadGif(
            splits, dashboardCubit, context, topHeight, bottomHeight);
      } else if (hasImage || hasText) {
        await _combineAndUploadBmp(
            splits, dashboardCubit, context, topHeight, bottomHeight);
      } else if (left.text != null && right.text != null) {
        final combined = "${left.text!}\n${right.text!}";
        await dashboardCubit.sendTextToBle(
          text: combined,
          color: 255,
          size: 16,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Sent text to BLE!')),
        );
      }
    } catch (e, st) {
      print('[ERROR] handleSplitAndUpload failed: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to send: $e')),
      );
    }
  }

  /// Helper to composite two images vertically (top, bottom) with dynamic heights
  img.Image _compositeVertically(
      img.Image top, img.Image bottom, int topHeight, int bottomHeight) {
    final merged = img.Image(width: 64, height: topHeight + bottomHeight);
    // Copy top
    for (int y = 0; y < topHeight; y++) {
      for (int x = 0; x < 64; x++) {
        merged.setPixel(x, y, top.getPixel(x, y));
      }
    }
    // Copy bottom
    for (int y = 0; y < bottomHeight; y++) {
      for (int x = 0; x < 64; x++) {
        merged.setPixel(x, y + topHeight, bottom.getPixel(x, y));
      }
    }
    return merged;
  }

  /// Combines two splits as GIF (vertical stack, text below if present) and uploads as GIF
  Future<void> _combineAndUploadGif(
      List<SplitScreenItem> splits,
      DashboardCubit dashboardCubit,
      BuildContext context,
      int topHeight,
      int bottomHeight) async {
    // Helper to get GIF frames or static image as frames
    Future<List<img.Image>> getFrames(SplitScreenItem item, int height) async {
      if (item.isGif && item.image is FileImage) {
        final file = (item.image as FileImage).file;
        final bytes = await file.readAsBytes();
        final decoder = img.GifDecoder();
        final info = decoder.startDecode(bytes);
        if (info != null) {
          final frameCount = decoder.numFrames();
          final frames = <img.Image>[];
          for (int i = 0; i < frameCount; i++) {
            final frame = decoder.decodeFrame(i);
            if (frame != null) {
              frames.add(img.copyResize(frame, width: 64, height: height));
            }
          }
          return frames;
        }
      } else if (item.image != null) {
        final bytes = await _imageBytesFromProvider(item.image!);
        if (bytes != null) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            return [img.copyResize(decoded, width: 64, height: height)];
          }
        }
      } else if (item.text != null) {
        final blank = img.Image(width: 64, height: height);
        return [
          _drawTextOnImage(blank, item.text!,
              fontSize: (height * 0.5).toInt(), yOffset: (height / 4).toInt())
        ];
      }
      // Blank frame if nothing
      return [img.Image(width: 64, height: height)];
    }

    // Get frames for both splits
    final leftFrames = await getFrames(splits[0], topHeight);
    final rightFrames = await getFrames(splits[1], bottomHeight);
    final frameCount = leftFrames.length > rightFrames.length
        ? leftFrames.length
        : rightFrames.length;
    final List<img.Image> combinedFrames = [];
    for (int i = 0; i < frameCount; i++) {
      final top = leftFrames[i % leftFrames.length];
      final bottom = rightFrames[i % rightFrames.length];
      final merged = _compositeVertically(top, bottom, topHeight, bottomHeight);
      combinedFrames.add(merged);
    }
    // Debug: Print GIF properties
    print(
        '[DEBUG] Combined GIF: frame count =  [32m${combinedFrames.length} [0m, size =  [32m${combinedFrames[0].width}x${combinedFrames[0].height} [0m');
    // Check palette type
    final hasGlobalPalette = combinedFrames.every((f) => f.palette != null);
    print('[DEBUG] All frames have palette: $hasGlobalPalette');
    // Force global palette and set frame delay
    final encoder = img.GifEncoder(
      repeat: 0, // infinite loop
      numColors: 256,
    );
    for (var frame in combinedFrames) {
      encoder.addFrame(frame, duration: 20); // 20 = ~2fps, adjust as needed
    }
    final gifBytes = Uint8List.fromList(encoder.finish()!);
    // Save to temp file for XFile
    final temp = File(
        '${Directory.systemTemp.path}/combined_${DateTime.now().millisecondsSinceEpoch}.gif');
    await temp.writeAsBytes(gifBytes);
    // Debug: Also save to Documents for inspection
    try {
      // Use path_provider to get the Documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final docsPath =
          '${docsDir.path}/merged_debug_${DateTime.now().millisecondsSinceEpoch}.gif';
      final debugFile = File(docsPath);
      await debugFile.writeAsBytes(gifBytes);
      print('[DEBUG] Merged GIF saved for inspection: $docsPath');
    } catch (e) {
      // Fallback: Save to systemTemp if Documents fails
      try {
        final fallbackPath =
            '${Directory.systemTemp.path}/merged_debug_${DateTime.now().millisecondsSinceEpoch}.gif';
        final fallbackFile = File(fallbackPath);
        await fallbackFile.writeAsBytes(gifBytes);
        print('[DEBUG] Merged GIF saved to temp: $fallbackPath');
      } catch (e2) {
        print('[DEBUG] Failed to save debug GIF: $e2');
      }
    }
    await dashboardCubit.uploadImageOrGif(XFile(temp.path));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Sent GIF to BLE!')),
    );
  }

  /// Draws text directly onto an img.Image using the image package
  img.Image _drawTextOnImage(img.Image base, String text,
      {int fontSize = 18, int yOffset = 0}) {
    // Use arial14 font from image package or fallback
    final font = img.arial14;
    // Estimate x for centering (since measureText is not available)
    const x = 4; // Small left margin, or adjust as needed
    final y = yOffset;
    img.drawString(
      base,
      text,
      font: font,
      x: x,
      y: y,
      color: img.ColorRgb8(255, 255, 255),
    );
    return base;
  }

  /// Returns a BMP Uint8List of the current split's combined preview (image+image, image+text, or text+text)
  Future<Uint8List> getCombinedPreviewBmp({double? splitRatio}) async {
    final splits = state.splits;
    final ratio = splitRatio ?? state.splitRatio;
    final topHeight = (64 * ratio).round();
    final bottomHeight = 64 - topHeight;
    Future<img.Image> getBmp(SplitScreenItem item, int height) async {
      if (item.image != null && item.text == null) {
        final bytes = await _imageBytesFromProvider(item.image!);
        if (bytes != null) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            return img.copyResize(decoded, width: 64, height: height);
          }
        }
      } else if (item.image != null && item.text != null) {
        // Draw text directly onto image
        final bytes = await _imageBytesFromProvider(item.image!);
        if (bytes != null) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            final resized = img.copyResize(decoded, width: 64, height: height);
            return _drawTextOnImage(resized, item.text!,
                fontSize: (height * 0.5).toInt(),
                yOffset: (height / 4).toInt());
          }
        }
      } else if (item.text != null) {
        // Fallback: render text as image
        final blank = img.Image(width: 64, height: height);
        return _drawTextOnImage(blank, item.text!,
            fontSize: (height * 0.5).toInt(), yOffset: (height / 4).toInt());
      }
      return img.Image(width: 64, height: height);
    }

    final top = await getBmp(splits[0], topHeight);
    final bottom = await getBmp(splits[1], bottomHeight);
    final merged = _compositeVertically(top, bottom, topHeight, bottomHeight);
    return Uint8List.fromList(img.encodeBmp(merged));
  }

  /// Returns a PNG Uint8List of the current split's combined preview (image+image, image+text, or text+text)
  Future<Uint8List> getCombinedPreviewPng({double? splitRatio}) async {
    final splits = state.splits;
    final ratio = splitRatio ?? state.splitRatio;
    final topHeight = (64 * ratio).round();
    final bottomHeight = 64 - topHeight;
    Future<img.Image> getBmp(SplitScreenItem item, int height) async {
      if (item.image != null) {
        final bytes = await _imageBytesFromProvider(item.image!);
        if (bytes != null) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            return img.copyResize(decoded, width: 64, height: height);
          }
        }
      } else if (item.text != null) {
        final blank = img.Image(width: 64, height: height);
        return _drawTextOnImage(blank, item.text!,
            fontSize: (height * 0.5).toInt(), yOffset: (height / 4).toInt());
      }
      return img.Image(width: 64, height: height);
    }

    final top = await getBmp(splits[0], topHeight);
    final bottom = await getBmp(splits[1], bottomHeight);
    final merged = _compositeVertically(top, bottom, topHeight, bottomHeight);
    return Uint8List.fromList(img.encodePng(merged));
  }

  /// Combines two splits as BMP (vertical stack, text below if present) and uploads as BMP
  Future<void> _combineAndUploadBmp(
      List<SplitScreenItem> splits,
      DashboardCubit dashboardCubit,
      BuildContext context,
      int topHeight,
      int bottomHeight) async {
    Future<img.Image> getBmp(SplitScreenItem item, int height) async {
      if (item.image != null && item.text == null) {
        final bytes = await _imageBytesFromProvider(item.image!);
        if (bytes != null) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            return img.copyResize(decoded, width: 64, height: height);
          }
        }
      } else if (item.image != null && item.text != null) {
        // Draw text directly onto image
        final bytes = await _imageBytesFromProvider(item.image!);
        if (bytes != null) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            final resized = img.copyResize(decoded, width: 64, height: height);
            return _drawTextOnImage(resized, item.text!,
                fontSize: (height * 0.5).toInt(),
                yOffset: (height / 4).toInt());
          }
        }
      } else if (item.text != null) {
        // Fallback: render text as image
        final blank = img.Image(width: 64, height: height);
        return _drawTextOnImage(blank, item.text!,
            fontSize: (height * 0.5).toInt(), yOffset: (height / 4).toInt());
      }
      return img.Image(width: 64, height: height);
    }

    final top = await getBmp(splits[0], topHeight);
    final bottom = await getBmp(splits[1], bottomHeight);
    final merged = _compositeVertically(top, bottom, topHeight, bottomHeight);
    final bmpBytes = Uint8List.fromList(img.encodeBmp(merged));
    // Save to temp file for XFile
    final temp = File(
        '${Directory.systemTemp.path}/combined_${DateTime.now().millisecondsSinceEpoch}.bmp');
    await temp.writeAsBytes(bmpBytes);
    await dashboardCubit.uploadImageOrGif(XFile(temp.path));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Sent BMP to BLE!')),
    );
  }

  // Replace sendCurrentSplitToBle with handleSplitAndUpload
  @override
  Future<void> sendCurrentSplitToBle({
    required DashboardCubit dashboardCubit,
    required BuildContext context,
  }) async {
    await handleSplitAndUpload(context, dashboardCubit);
  }

  Future<Uint8List?> _imageBytesFromProvider(ImageProvider provider) async {
    if (provider is FileImage) {
      final raw = await File(provider.file.path).readAsBytes();
      final decoded = img.decodeImage(raw);
      if (decoded == null) return null;
      final cropped = img.copyResize(decoded, width: 64, height: 32);
      return Uint8List.fromList(img.encodeBmp(cropped));
    }
    return null;
  }
}
