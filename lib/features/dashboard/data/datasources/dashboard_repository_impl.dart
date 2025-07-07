import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hookaba/core/utils/ble_service.dart';
import 'package:hookaba/core/utils/enum.dart' show AnimationType;
import 'package:hookaba/core/utils/js_bridge_service.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart' as logger;

class DashboardRepositoryImpl {
  final BLEService bleService;
  final JsBridgeService jsBridgeService;
  final _logger = logger.Logger();

  DashboardRepositoryImpl({
    required this.bleService,
    required this.jsBridgeService,
  });

  Future<void> sendJsonCommand(BluetoothDevice device, Map<String, dynamic> jsonCmd) async {
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
    if (writeChar == null) throw Exception('Write characteristic not found');
    final jsonStr = jsonEncode(jsonCmd);
    final bytes = utf8.encode(jsonStr);
    final packet = Uint8List(2 + bytes.length)
      ..[0] = bytes.length & 0xFF
      ..[1] = (bytes.length >> 8) & 0xFF
      ..setRange(2, 2 + bytes.length, bytes);
    await writeChar.write(packet, withoutResponse: false);
  }

  Future<void> sendPowerOffSequence(BluetoothDevice device) async {
    final cmd = {
      "cmd": {
        "power": {"type": 0}
      },
      "sno": DateTime.now().millisecondsSinceEpoch % 1000
    };
    await sendJsonCommand(device, cmd);
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

  Future<void> uploadImageOrGif(BluetoothDevice device, XFile file) async {
    final raw = await file.readAsBytes();
    final isGif = raw.length >= 6 &&
        (String.fromCharCodes(raw.sublist(0, 6)) == 'GIF87a' ||
            String.fromCharCodes(raw.sublist(0, 6)) == 'GIF89a');
    final idPro = DateTime.now().millisecondsSinceEpoch % 50000;
    final randomBytes = Uint8List.fromList(List.generate(20, (_) => Random().nextInt(256)));
    final idRes = base64Encode(randomBytes);
    final sno = DateTime.now().millisecondsSinceEpoch % 65535;
    if (isGif) {
      final gifBase64 = base64Encode(raw);
      final jsonCmd = {
        "pkts_program": {
          "id_pro": idPro,
          "property_pro": {
            "width": 64,
            "height": 64,
            "type_color": 2,
            "type_pro": 1,
            "play_fixed_time": 300,
            "show_now": 1,
            "send_gif_src": 1,
          },
          "list_region": [
            {
              "info_pos": {"x": 0, "y": 0, "w": 64, "h": 64},
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
      return;
    } else {
      final decoded = img.decodeImage(raw);
      if (decoded == null) throw Exception("Unsupported or corrupt image");
      final resized = img.copyResize(decoded, width: 64, height: 64);
      final fixed = img.Image(width: 64, height: 64);
      const cut = 28;
      const rightWidth = 64 - cut;
      for (int y = 0; y < 64; y++) {
        for (int x = 0; x < 64; x++) {
          if (x < rightWidth) {
            final srcX = x + cut;
            final pixel = resized.getPixel(srcX, y);
            fixed.setPixel(x, y, pixel);
          } else {
            final srcX = x - rightWidth;
            final srcY = (y - 1).clamp(0, 63);
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
            "width": 64,
            "height": 64,
            "type_color": 2,
            "type_pro": 1,
            "play_fixed_time": 300,
            "show_now": 1,
          },
          "list_region": [
            {
              "info_pos": {"x": 0, "y": 0, "w": 64, "h": 64},
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
  }

  Future<void> sendBlankCanvas(BluetoothDevice device, {int width = 64, int height = 64}) async {
    final idPro = DateTime.now().millisecondsSinceEpoch % 50000;
    final randomBytes = Uint8List.fromList(List.generate(20, (_) => Random().nextInt(256)));
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

  Future<void> sendTextToBle(BluetoothDevice device, {
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
                if (alignHorizontal != null) "align_horizontal": alignHorizontal,
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
  }

  Future<void> sendBinaryToBle(BluetoothDevice device, Uint8List data, int idPro) async {
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
    if (writeChar == null) throw Exception('Write characteristic not found for binary');
    final header = Uint8List(4);
    ByteData.view(header.buffer).setUint32(0, data.length, Endian.little);
    await writeChar.write(header, withoutResponse: true);
    await Future.delayed(const Duration(milliseconds: 50));
    const mtu = 180;
    for (int i = 0; i < data.length; i += mtu) {
      final chunk = data.sublist(i, (i + mtu > data.length) ? data.length : i + mtu);
      await writeChar.write(chunk, withoutResponse: true);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    final cmd = {
      "cmd": {
        "pgm_play": {
          "model": 0,
          "index": 0,
          "ids_pro": [idPro],
        }
      },
      "sno": DateTime.now().millisecondsSinceEpoch % 65535,
    };
    await sendJsonCommand(device, cmd);
  }

  Future<void> getProgramGroup(BluetoothDevice device) async {
    final cmd = {
      "cmd": { "get": "pgm_play" },
      "sno": DateTime.now().millisecondsSinceEpoch % 1000,
    };
    await sendJsonCommand(device, cmd);
  }

  Future<void> getProgramResourceIds(BluetoothDevice device, List<int> programIds) async {
    final cmd = {
      "cmd": { "get": "pgm_key", "ids_pro": programIds },
      "sno": DateTime.now().millisecondsSinceEpoch % 1000,
    };
    await sendJsonCommand(device, cmd);
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

  Future<void> sendTlvToBle(BluetoothDevice device, Uint8List tlvBytes) async {
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
      await Future.delayed(const Duration(milliseconds: 100));
    }
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
} 