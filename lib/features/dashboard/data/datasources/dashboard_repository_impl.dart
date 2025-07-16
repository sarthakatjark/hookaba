import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hookaba/core/common_widgets/primary_snackbar.dart';
import 'package:hookaba/core/network/network_dio.dart';
import 'package:hookaba/core/utils/api_constants.dart';
import 'package:hookaba/core/utils/ble_service.dart';
import 'package:hookaba/core/utils/enum.dart' show AnimationType;
import 'package:hookaba/core/utils/js_bridge_service.dart';
import 'package:hookaba/core/utils/local_program_service.dart';
import 'package:hookaba/core/utils/my_new_service.dart';
import 'package:hookaba/features/dashboard/data/models/library_item_model.dart';
import 'package:hookaba/features/program_list/data/models/local_program_model.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart' as logger;
import 'package:permission_handler/permission_handler.dart';

class DashboardRepositoryImpl {
  final BLEService bleService;
  final JsBridgeService jsBridgeService;
  final DioClient dioClient;
  final AnalyticsService analyticsService;
  final _logger = logger.Logger();

  DashboardRepositoryImpl({
    required this.bleService,
    required this.jsBridgeService,
    required this.dioClient,
    required this.analyticsService,
  });

  Future<void> sendPowerSequence({required int power, required int sno}) async {
    final cmd = {
      "cmd": {
        "power": {"type": power},
      },
      "sno": sno,
    };
    await jsBridgeService.sendJsonCommand(cmd);
  }

  /// Sends a brightness command to the BLE device via JS bridge (fixed mode)
  Future<void> sendBrightness(int brightnessValue) async {
    final cmd = {
      "cmd": {
        "light": {
          "type": 0,
          "value_fix": brightnessValue.clamp(0, 15),
        },
      },
      "sno": DateTime.now().millisecondsSinceEpoch % 65535,
    };
    await jsBridgeService.sendJsonCommand(cmd);
  }

  Future<void> sendImageOrGifViaJsBridge(Map<String, dynamic> jsonCmd,
      {String? base64Image, String? gifBase64}) async {
    _logger.i('🧩 Sending image/GIF to JS bridge. Command: $jsonCmd');
    if (gifBase64 != null) {
      _logger.d('🌀 Detected GIF. Length: ${gifBase64.length} base64 chars');
    }
    if (base64Image != null) {
      _logger
          .d('🖼️ Detected image. Length: ${base64Image.length} base64 chars');
    }
    await jsBridgeService.sendImageOrGif(jsonCmd,
        base64Image: base64Image, gifBase64: gifBase64);
    _logger.i('✅ JS bridge command sent.');
  }

  Future<void> uploadImageOrGif(BluetoothDevice device, XFile file,
      {required int width, required int height, void Function(double progress)? onProgress}) async {
    final raw = await file.readAsBytes();
    final isGif = raw.length >= 6 &&
        (String.fromCharCodes(raw.sublist(0, 6)) == 'GIF87a' ||
            String.fromCharCodes(raw.sublist(0, 6)) == 'GIF89a');
    final idPro = DateTime.now().millisecondsSinceEpoch % 50000;
    final randomBytes =
        Uint8List.fromList(List.generate(20, (_) => Random().nextInt(256)));
    final idRes = base64Encode(randomBytes);
    final sno = DateTime.now().millisecondsSinceEpoch % 65535;
    if (isGif) {
      final gifBase64 = base64Encode(raw);
      final jsonCmd = {
        "pkts_program": {
          "id_pro": idPro,
          "property_pro": {
            "width": width,
            "height": height,
            "type_color": 2,
            "type_pro": 1,
            "play_fixed_time": 300,
            "show_now": 1,
            "send_gif_src": 1,
          },
          "list_region": [
            {
              "info_pos": {"x": 0, "y": 0, "w": width, "h": height},
              "list_item": [
                {
                  "type_item": "graphic",
                  "isGif": 1,
                  "info_animate": {
                    "model_gif": 3,
                    "time_stay": 100,
                  },
                },
              ],
            },
          ],
        },
        "id_res": idRes,
        "sno": sno,
      };
      await sendImageOrGifViaJsBridge(jsonCmd, gifBase64: gifBase64);
      // Generate GIF preview (first frame as BMP)
      Uint8List gifPreview = Uint8List(0);
      try {
        final gifImage = img.decodeGif(raw);
        if (gifImage != null) {
          final firstFrame = gifImage;
          final resized = img.copyResize(firstFrame, width: width, height: height);
          gifPreview = Uint8List.fromList(img.encodeBmp(resized));
        }
      } catch (_) {}
      // Store to local
      await LocalProgramService().addProgram(LocalProgramModel(
        id: idPro.toString(),
        name: file.name,
        bmpBytes: gifPreview,
        jsonCommand: jsonCmd,
        gifBase64: gifBase64,
      ));
      return;
    } else {
      final decoded = img.decodeImage(raw);
      if (decoded == null) throw Exception("Unsupported or corrupt image");
      final resized = img.copyResize(decoded, width: width, height: height);
      final fixed = img.Image(width: width, height: height);
      const cut = 28;
      final rightWidth = width - cut;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (x < rightWidth) {
            final srcX = x + cut;
            final pixel = resized.getPixel(srcX, y);
            fixed.setPixel(x, y, pixel);
          } else {
            final srcX = x - rightWidth;
            final srcY = (y - 1).clamp(0, height - 1);
            final pixel = resized.getPixel(srcX, srcY);
            fixed.setPixel(x, y, pixel);
          }
        }
      }
      final bmpBytes = Uint8List.fromList(img.encodeBmp(fixed));
      final base64Image = base64Encode(bmpBytes);
      final jsonCmd = {
        "pkts_program": {
          "id_pro": idPro,
          "property_pro": {
            "width": width,
            "height": height,
            "type_color": 2,
            "type_pro": 1,
            "play_fixed_time": 300,
            "show_now": 1,
          },
          "list_region": [
            {
              "info_pos": {"x": 0, "y": 0, "w": width, "h": height},
              "list_item": [
                {"type_item": "graphic", "isGif": 0},
              ],
            },
          ],
        },
        "id_res": idRes,
        "sno": sno,
        "res_base64": base64Image,
      };
      // Use the same BLE upload logic to show progress
      await sendTlvToBle(device, Uint8List.fromList([]), onProgress: onProgress);
      await sendImageOrGifViaJsBridge(jsonCmd, base64Image: base64Image);
      // Store to local
      await LocalProgramService().addProgram(LocalProgramModel(
        id: idPro.toString(),
        name: file.name,
        bmpBytes: base64Decode(base64Image),
        jsonCommand: jsonCmd,
      ));
    }
  }

  Future<void> sendBlankCanvas(BluetoothDevice device,
      {required int width, required int height}) async {
    final idPro = DateTime.now().millisecondsSinceEpoch % 50000;
    final randomBytes =
        Uint8List.fromList(List.generate(20, (_) => Random().nextInt(256)));
    final idRes = base64Encode(randomBytes);
    final sno = DateTime.now().millisecondsSinceEpoch % 65535;
    final blank = img.Image(width: width, height: height);
    final bmpBytes = Uint8List.fromList(img.encodeBmp(blank));
    final base64Image = base64Encode(bmpBytes);
    final jsonCmd = {
      "pkts_program": {
        "id_pro": idPro,
        "property_pro": {
          "width": width,
          "height": height,
          "type_color": 2,
          "type_pro": 1,
          "play_fixed_time": 300,
          "show_now": 1,
        },
        "list_region": [
          {
            "info_pos": {"x": 0, "y": 0, "w": width, "h": height},
            "list_item": [
              {"type_item": "graphic", "isGif": 0},
            ],
          },
        ],
      },
      "id_res": idRes,
      "sno": sno,
      "res_base64": base64Image,
    };
    await sendImageOrGifViaJsBridge(jsonCmd, base64Image: base64Image);
  }

  Future<void> sendTextToBle(
    BluetoothDevice device, {
    required String text,
    required int color,
    required int size,
    int? bold,
    int? italic,
    int? spaceFont,
    int? spaceLine,
    String? alignHorizontal,
    String? alignVertical,
    Map<String, dynamic>? infoAnimate,
    double? stayingTime,
  }) async {
    final idPro = DateTime.now().millisecondsSinceEpoch % 50000;
    final idRes = DateTime.now()
        .millisecondsSinceEpoch
        .toRadixString(16)
        .padLeft(32, '0')
        .substring(0, 32);
    final propertyPro = {
      "width": 128,
      "height": 32,
      "show_now": 1,
    };
    if (stayingTime != null) {
      propertyPro["play_fixed_time"] = stayingTime.toInt();
    }
    final jsonCmd = {
      "pkts_program": {
        "id_pro": idPro,
        "property_pro": propertyPro,
        "list_region": [
          {
            "info_pos": {"x": 0, "y": 0, "w": 64, "h": 64},
            "list_item": [
              {
                "type_item": "text",
                "text": text,
                "size": size,
                "color": color,
                if (bold != null) "bold": bold,
                if (italic != null) "italic": italic,
                if (spaceFont != null) "space_font": spaceFont,
                if (spaceLine != null) "space_line": spaceLine,
                if (alignHorizontal != null)
                  "align_horizontal": alignHorizontal,
                if (alignVertical != null) "align_vertical": alignVertical,
                if (infoAnimate != null) "info_animate": infoAnimate,
              }
            ]
          }
        ]
      },
      "id_res": idRes,
      "sno": 1,
    };
    await jsBridgeService.sendText(jsonCmd);
    // Store to local
    await LocalProgramService().addProgram(LocalProgramModel(
      id: idPro.toString(),
      name: text,
      bmpBytes: Uint8List(0),
      jsonCommand: jsonCmd,
    ));
  }

  Future<void> getProgramGroup(BluetoothDevice device) async {
    final cmd = {
      "cmd": {"get": "pgm_play"},
      "sno": DateTime.now().millisecondsSinceEpoch % 1000,
    };
    //await sendJsonCommand(device, cmd);
    await jsBridgeService.sendJsonCommand(cmd);
  }

  Future<void> getProgramResourceIds(
      BluetoothDevice device, List<int> programIds) async {
    final cmd = {
      "cmd": {"get": "pgm_key", "ids_pro": programIds},
      "sno": DateTime.now().millisecondsSinceEpoch % 1000,
    };
    //await sendJsonCommand(device, cmd);
    await jsBridgeService.sendJsonCommand(cmd);
  }

  Future<void> sendRTDrawPoint({
    required int x,
    required int y,
    required int color,
  }) async {
    final cmd = {
      "cmd": {
        "RTDraw": {
          "type": 16,
          "color": color,
          "data": [
            [x, y]
          ]
        }
      },
      "sno": DateTime.now().millisecondsSinceEpoch % 1000,
    };
    await jsBridgeService.sendRTDraw(cmd);
    await Future.delayed(const Duration(milliseconds: 30));
  }

  Future<void> flushDrawBuffer(List<List<int>> drawBuffer, int color) async {
    if (drawBuffer.isEmpty) return;
    final cmd = {
      "cmd": {
        "RTDraw": {
          "type": 16,
          "color": color,
          "data": List.from(drawBuffer),
        }
      },
      "sno": DateTime.now().millisecondsSinceEpoch % 1000,
    };
    await jsBridgeService.sendRTDraw(cmd);
  }

  Future<void> sendTlvToBle(
    BluetoothDevice device,
    Uint8List tlvBytes, {
    void Function(double progress)? onProgress,
  }) async {
    final services = await device.discoverServices();
    BluetoothCharacteristic? writeChar;
    for (var service in services) {
      for (var char in service.characteristics) {
        final charUuid = char.uuid.toString().toLowerCase();
        if (charUuid.contains("fff2") || charUuid.contains("ff02")) {
          writeChar = char;
          break;
        }
      }
      if (writeChar != null) break;
    }
    if (writeChar == null) {
      throw Exception('Write characteristic not found for TLV');
    }

    // Send 4-byte header first
    final header = Uint8List(4);
    ByteData.view(header.buffer).setUint32(0, tlvBytes.length, Endian.little);
    await writeChar.write(header, withoutResponse: true);
    await Future.delayed(const Duration(milliseconds: 50));

    // Send in chunks if needed
    const mtu = 180;
    for (int i = 0; i < tlvBytes.length; i += mtu) {
      final chunk = tlvBytes.sublist(
          i, (i + mtu > tlvBytes.length) ? tlvBytes.length : i + mtu);
      await writeChar.write(chunk, withoutResponse: true);
      if (onProgress != null) {
        onProgress((i + chunk.length) / tlvBytes.length);
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<Map<String, int>?> getDeviceScreenProperty(
      BluetoothDevice device) async {
    _logger.i(
        '📏 Sending get property_pro command to device: ${device.platformName}');
    final cmd = {
      "cmd": {"get": "dev_info", "id_pro": 1},
      "sno": 2
    };

    await jsBridgeService.sendJsonCommand(cmd);

    return null;
  }

  Map<String, dynamic>? animationTypeToInfoAnimate(AnimationType? type) {
    if (type == null) return null;
    switch (type) {
      case AnimationType.showNow:
        return {"model_normal": 0x01, "speed": 10, "time_stay": 3};
      case AnimationType.shiftLeft:
        return {"model_normal": 0x02, "speed": 10, "time_stay": 3};
      case AnimationType.shiftRight:
        return {"model_normal": 0x03, "speed": 10, "time_stay": 3};
      case AnimationType.moveUp:
        return {"model_normal": 0x04, "speed": 10, "time_stay": 3};
      case AnimationType.moveDown:
        return {"model_normal": 0x05, "speed": 10, "time_stay": 3};
      case AnimationType.snow:
        return {"model_normal": 0x09, "speed": 10, "time_stay": 3};
      case AnimationType.bubble:
        return {"model_normal": 0x0A, "speed": 10, "time_stay": 3};
      case AnimationType.flicker:
        return {"model_normal": 0x1E, "speed": 10, "time_stay": 3};
      case AnimationType.continueLeftShift:
        return {"model_continue": "left", "speed": 10, "size_interval": 50};
    }
  }

  /// Picks an image, crops to box, compresses, and returns the processed XFile (or null if cancelled)
  Future<XFile?> pickAndProcessImage(BuildContext context) async {
    final status = await Permission.photos.request();
    print('[pickAndProcessImage] Permission.photos status: $status '
        '(isGranted= [32m${status.isGranted} [0m, isLimited= [33m${status.isLimited} [0m, '
        'isDenied= [31m${status.isDenied} [0m, isPermanentlyDenied=${status.isPermanentlyDenied}, '
        'isRestricted=${status.isRestricted})');

    if (status.isGranted || status.isLimited) {
      print('[pickAndProcessImage] Permission granted or limited, opening picker');
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return null;
      // Check if GIF
      final isGif = file.name.toLowerCase().endsWith('.gif');
      XFile? finalFile = file;
      if (!isGif) {
        // Crop image to box shape
        final cropped = await ImageCropper().cropImage(
          sourcePath: file.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Image',
              aspectRatioLockEnabled: true,
            ),
          ],
        );
        if (cropped != null) {
          // Compress image
          final compressed = await FlutterImageCompress.compressAndGetFile(
            cropped.path,
            '${cropped.path}_compressed.jpg',
            quality: 80,
          );
          if (compressed != null) {
            finalFile = XFile(compressed.path);
          } else {
            finalFile = XFile(cropped.path);
          }
        } else {
          // User cancelled cropping
          return null;
        }
      }
      return finalFile;
    } else if (status.isDenied) {
      print('[pickAndProcessImage] Permission denied, can ask again');
      showPrimarySnackbar(context, 'Photo permission is required to select images.', colorTint: Colors.red, icon: Icons.error);
      return null;
    } else if (status.isPermanentlyDenied || status.isRestricted) {
      print('[pickAndProcessImage] Permission permanently denied or restricted, opening settings');
      showPrimarySnackbar(context, 'Please enable photo access in Settings.', colorTint: Colors.red, icon: Icons.error);
      await Future.delayed(const Duration(milliseconds: 1200));
      await openAppSettings();
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> fetchLibraryList({int page = 1, int perPage = 10}) async {
    final response = await dioClient.get(
      ApiEndpoints.libraryList(page: page, perPage: perPage),
      requireAuth: true,
    );
    final data = response.data;
    if (data is Map && data['items'] is List) {
      return {
        'items': (data['items'] as List)
            .map((item) => LibraryItemModel.fromJson(item))
            .toList(),
        'page': data['page'] ?? 1,
        'totalPages': data['total_pages'] ?? 1,
      };
    }
    return {'items': [], 'page': 1, 'totalPages': 1};
  }
}
