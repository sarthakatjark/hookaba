import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../presentation/cubit/split_screen_state.dart';

class SplitScreenRepositoryImpl {
  Future<void> handleSplitAndUpload({
    required BuildContext context,
    required DashboardCubit dashboardCubit,
    required List<SplitScreenItem> splits,
    required double splitRatio,
    required Function(String) onError,
    required Function(String) onSuccess,
  }) async {
    final left = splits[0];
    final right = splits[1];
    final hasGif = left.isGif || right.isGif;
    final hasText = left.text != null || right.text != null;
    final hasImage = left.image != null || right.image != null;
    final ratio = splitRatio;
    final topHeight = (64 * ratio).round();
    final bottomHeight = 64 - topHeight;
    try {
      if (hasGif) {
        await combineAndUploadGif(
          splits: splits,
          dashboardCubit: dashboardCubit,
          context: context,
          topHeight: topHeight,
          bottomHeight: bottomHeight,
        );
        onSuccess('✅ Sent GIF to BLE!');
      } else if (hasImage || hasText) {
        await combineAndUploadBmp(
          splits: splits,
          dashboardCubit: dashboardCubit,
          context: context,
          topHeight: topHeight,
          bottomHeight: bottomHeight,
        );
        onSuccess('✅ Sent BMP to BLE!');
      } else if (left.text != null && right.text != null) {
        final combined = "${left.text!}\n${right.text!}";
        await dashboardCubit.sendTextToBle(
          text: combined,
          color: 255,
          size: 16,
        );
        onSuccess('✅ Sent text to BLE!');
      }
    } catch (e) {
      onError('❌ Failed to send: $e');
    }
  }

  Future<void> combineAndUploadGif({
    required List<SplitScreenItem> splits,
    required DashboardCubit dashboardCubit,
    required BuildContext context,
    required int topHeight,
    required int bottomHeight,
  }) async {
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
        final bytes = await imageBytesFromProvider(item.image!);
        if (bytes != null) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            return [img.copyResize(decoded, width: 64, height: height)];
          }
        }
      } else if (item.text != null) {
        final blank = img.Image(width: 64, height: height);
        return [
          drawTextOnImage(blank, item.text!,
              fontSize: (height * 0.5).toInt(), yOffset: (height / 4).toInt())
        ];
      }
      return [img.Image(width: 64, height: height)];
    }
    final leftFrames = await getFrames(splits[0], topHeight);
    final rightFrames = await getFrames(splits[1], bottomHeight);
    final frameCount = leftFrames.length > rightFrames.length
        ? leftFrames.length
        : rightFrames.length;
    final List<img.Image> combinedFrames = [];
    for (int i = 0; i < frameCount; i++) {
      final top = leftFrames[i % leftFrames.length];
      final bottom = rightFrames[i % rightFrames.length];
      final merged = compositeVertically(top, bottom, topHeight, bottomHeight);
      combinedFrames.add(merged);
    }
    final encoder = img.GifEncoder(
      repeat: 0,
      numColors: 256,
    );
    for (var frame in combinedFrames) {
      encoder.addFrame(frame, duration: 20);
    }
    final gifBytes = Uint8List.fromList(encoder.finish()!);
    final temp = File(
        '${Directory.systemTemp.path}/combined_${DateTime.now().millisecondsSinceEpoch}.gif');
    await temp.writeAsBytes(gifBytes);
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final docsPath =
          '${docsDir.path}/merged_debug_${DateTime.now().millisecondsSinceEpoch}.gif';
      final debugFile = File(docsPath);
      await debugFile.writeAsBytes(gifBytes);
    } catch (e) {
      try {
        final fallbackPath =
            '${Directory.systemTemp.path}/merged_debug_${DateTime.now().millisecondsSinceEpoch}.gif';
        final fallbackFile = File(fallbackPath);
        await fallbackFile.writeAsBytes(gifBytes);
      } catch (e2) {}
    }
    await dashboardCubit.uploadImageOrGif(XFile(temp.path));
  }

  img.Image compositeVertically(
      img.Image top, img.Image bottom, int topHeight, int bottomHeight) {
    final merged = img.Image(width: 64, height: topHeight + bottomHeight);
    for (int y = 0; y < topHeight; y++) {
      for (int x = 0; x < 64; x++) {
        merged.setPixel(x, y, top.getPixel(x, y));
      }
    }
    for (int y = 0; y < bottomHeight; y++) {
      for (int x = 0; x < 64; x++) {
        merged.setPixel(x, y + topHeight, bottom.getPixel(x, y));
      }
    }
    return merged;
  }

  img.Image drawTextOnImage(img.Image base, String text,
      {int fontSize = 18, int yOffset = 0}) {
    final font = img.arial14;
    const x = 4;
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

  Future<Uint8List> getCombinedPreviewBmp({
    required List<SplitScreenItem> splits,
    required double splitRatio,
  }) async {
    final ratio = splitRatio;
    final topHeight = (64 * ratio).round();
    final bottomHeight = 64 - topHeight;
    Future<img.Image> getBmp(SplitScreenItem item, int height) async {
      if (item.image != null && item.text == null) {
        final bytes = await imageBytesFromProvider(item.image!);
        if (bytes != null) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            return img.copyResize(decoded, width: 64, height: height);
          }
        }
      } else if (item.image != null && item.text != null) {
        final bytes = await imageBytesFromProvider(item.image!);
        if (bytes != null) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            final resized = img.copyResize(decoded, width: 64, height: height);
            return drawTextOnImage(resized, item.text!,
                fontSize: (height * 0.5).toInt(),
                yOffset: (height / 4).toInt());
          }
        }
      } else if (item.text != null) {
        final blank = img.Image(width: 64, height: height);
        return drawTextOnImage(blank, item.text!,
            fontSize: (height * 0.5).toInt(), yOffset: (height / 4).toInt());
      }
      return img.Image(width: 64, height: height);
    }
    final top = await getBmp(splits[0], topHeight);
    final bottom = await getBmp(splits[1], bottomHeight);
    final merged = compositeVertically(top, bottom, topHeight, bottomHeight);
    return Uint8List.fromList(img.encodeBmp(merged));
  }

  Future<Uint8List> getCombinedPreviewPng({
    required List<SplitScreenItem> splits,
    required double splitRatio,
  }) async {
    final ratio = splitRatio;
    final topHeight = (64 * ratio).round();
    final bottomHeight = 64 - topHeight;
    Future<img.Image> getBmp(SplitScreenItem item, int height) async {
      if (item.image != null) {
        final bytes = await imageBytesFromProvider(item.image!);
        if (bytes != null) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            return img.copyResize(decoded, width: 64, height: height);
          }
        }
      } else if (item.text != null) {
        final blank = img.Image(width: 64, height: height);
        return drawTextOnImage(blank, item.text!,
            fontSize: (height * 0.5).toInt(), yOffset: (height / 4).toInt());
      }
      return img.Image(width: 64, height: height);
    }
    final top = await getBmp(splits[0], topHeight);
    final bottom = await getBmp(splits[1], bottomHeight);
    final merged = compositeVertically(top, bottom, topHeight, bottomHeight);
    return Uint8List.fromList(img.encodePng(merged));
  }

  Future<void> combineAndUploadBmp({
    required List<SplitScreenItem> splits,
    required DashboardCubit dashboardCubit,
    required BuildContext context,
    required int topHeight,
    required int bottomHeight,
  }) async {
    Future<img.Image> getBmp(SplitScreenItem item, int height) async {
      if (item.image != null && item.text == null) {
        final bytes = await imageBytesFromProvider(item.image!);
        if (bytes != null) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            return img.copyResize(decoded, width: 64, height: height);
          }
        }
      } else if (item.image != null && item.text != null) {
        final bytes = await imageBytesFromProvider(item.image!);
        if (bytes != null) {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            final resized = img.copyResize(decoded, width: 64, height: height);
            return drawTextOnImage(resized, item.text!,
                fontSize: (height * 0.5).toInt(),
                yOffset: (height / 4).toInt());
          }
        }
      } else if (item.text != null) {
        final blank = img.Image(width: 64, height: height);
        return drawTextOnImage(blank, item.text!,
            fontSize: (height * 0.5).toInt(), yOffset: (height / 4).toInt());
      }
      return img.Image(width: 64, height: height);
    }
    final top = await getBmp(splits[0], topHeight);
    final bottom = await getBmp(splits[1], bottomHeight);
    final merged = compositeVertically(top, bottom, topHeight, bottomHeight);
    final bmpBytes = Uint8List.fromList(img.encodeBmp(merged));
    final temp = File(
        '${Directory.systemTemp.path}/combined_${DateTime.now().millisecondsSinceEpoch}.bmp');
    await temp.writeAsBytes(bmpBytes);
    await dashboardCubit.uploadImageOrGif(XFile(temp.path));
  }

  Future<void> sendCurrentSplitToBle({
    required DashboardCubit dashboardCubit,
    required BuildContext context,
    required List<SplitScreenItem> splits,
    required double splitRatio,
    required Function(String) onError,
    required Function(String) onSuccess,
  }) async {
    await handleSplitAndUpload(
      context: context,
      dashboardCubit: dashboardCubit,
      splits: splits,
      splitRatio: splitRatio,
      onError: onError,
      onSuccess: onSuccess,
    );
  }

  Future<Uint8List?> imageBytesFromProvider(ImageProvider provider) async {
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