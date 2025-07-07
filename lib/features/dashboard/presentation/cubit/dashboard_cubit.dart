import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hookaba/core/utils/ble_service.dart';
import 'package:hookaba/core/utils/enum.dart' show AnimationType;
import 'package:hookaba/core/utils/js_bridge_service.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart' as logger;

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final BLEService bleService;
  final _logger = logger.Logger();
  //final _imagePicker = ImagePicker();

  late final JsBridgeService jsBridgeService;

  BluetoothDevice? _connectedDevice;
  bool _isDeviceConnected = false;

  // Add public getter for connection state
  bool get isDeviceConnected => _isDeviceConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  StreamSubscription? _notificationSubscription;

  // --- Real-time draw batching logic ---
  final List<List<int>> _drawBuffer = [];
  Timer? _drawFlushTimer;

  DashboardCubit({
    required this.bleService,
    Map<String, dynamic>? extra,
  }) : super(const DashboardState()) {
    _logger.i(
        'DashboardCubit initialized. Initial state: _connectedDevice = $_connectedDevice, _isDeviceConnected = $_isDeviceConnected');

    // Initialize with connected device from BLEService
    final connectedDevice = bleService.connectedDevice;
    if (connectedDevice != null) {
      _connectedDevice = connectedDevice;
      _isDeviceConnected = true;
      emit(state.copyWith(
        connectedDevice: connectedDevice,
        isDeviceConnected: true,
      ));
      _logger.i(
          'Successfully initialized with connected device: ${connectedDevice.platformName}');
    }

    // Initialize JS bridge
    jsBridgeService = JsBridgeService();
    jsBridgeService.init();
    jsBridgeService.tlvStream.listen((tlvBytes) {
      //sendTlvToBle(tlvBytes);
    });
  }

  @override
  Future<void> close() {
    _logger.d('🚪 Closing DashboardCubit');
    _logger.d(
        '📊 Final connection state - device: $_connectedDevice, connected: $_isDeviceConnected');

    // Cancel notification subscription
    _notificationSubscription?.cancel();

    // Cancel draw flush timer
    _drawFlushTimer?.cancel();

    // Only clear internal state, don't disconnect from device
    // The BLE connection will be managed by the BLE service
    _connectedDevice = null;
    _isDeviceConnected = false;

    _logger.d('✅ DashboardCubit cleanup complete');
    return super.close();
  }

  void setConnectedDevice(BluetoothDevice device) {
    _logger.i(
        '📱 Setting connected device in DashboardCubit: ${device.platformName} (${device.remoteId})');
    _logger.d(
        '📊 Current state - device: $_connectedDevice, connected: $_isDeviceConnected');

    // Only update if this is a different device
    if (_connectedDevice?.remoteId != device.remoteId) {
      _connectedDevice = device;
      _isDeviceConnected = true;
      _logger.d(
          '📊 New state - device: $_connectedDevice, connected: $_isDeviceConnected');
      _logger.i('✅ Connection state updated successfully');
      emit(state.copyWith(
        status: DashboardStatus.initial,
        errorMessage: null, // Clear any previous error
      ));
    } else {
      _logger.d(
          '📱 Device ${device.platformName} already connected, skipping update');
    }
  }

  void handleBLEFeedback(String message) {
    try {
      final decoded = jsonDecode(message);
      _logger.i('📱 Decoded BLE feedback: $decoded');

      // Update state based on the response
      emit(state.copyWith(
        status: DashboardStatus.success,
        deviceResponse: decoded,
      ));
    } catch (e) {
      _logger.e('❌ Error handling BLE feedback', error: e);
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to parse device response: $e',
      ));
    }
  }

  /// Sends a JSON command to the BLE device
  Future<void> sendJsonCommand(Map<String, dynamic> jsonCmd) async {
    if (_connectedDevice == null) {
      _logger.e('❌ No device connected. Cannot send command.');
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'No device connected',
      ));
      return;
    }

    try {
      _logger.i('📤 Sending JSON command: $jsonCmd');
      // Discover services and characteristics if not already done
      final services = await _connectedDevice!.discoverServices();
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
        _logger.e('❌ Write characteristic not found');
        emit(state.copyWith(
          status: DashboardStatus.error,
          errorMessage: 'Write characteristic not found',
        ));
        return;
      }

      final jsonStr = jsonEncode(jsonCmd);
      final bytes = utf8.encode(jsonStr);

      // Prepend length as 2 bytes (little endian)
      final packet = Uint8List(2 + bytes.length)
        ..[0] = bytes.length & 0xFF
        ..[1] = (bytes.length >> 8) & 0xFF
        ..setRange(2, 2 + bytes.length, bytes);

      await writeChar.write(packet, withoutResponse: false);
      _logger.i('✅ JSON command sent to BLE device.');
      emit(state.copyWith(status: DashboardStatus.success));
    } catch (e) {
      _logger.e('❌ Failed to send command: $e');
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to send command: $e',
      ));
    }
  }

  /// Sends a power-off command to the BLE device
  Future<void> sendPowerOffSequence() async {
    _logger.i('⛔ Sending power-off command to BLE device...');
    final cmd = {
      "cmd": {
        "power": {"type": 0}
      },
      "sno": DateTime.now().millisecondsSinceEpoch % 1000
    };
    await sendJsonCommand(cmd);
  }

  /// Use the JS bridge to encode and send an image or GIF
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

  /// Uploads an image or GIF file, processes it, and sends to BLE via JS bridge
  Future<void> uploadImageOrGif(XFile file) async {
    try {
      _logger.i('Uploading file: ${file.name}');
      final raw = await file.readAsBytes();
      final isGif = raw.length >= 6 &&
          (String.fromCharCodes(raw.sublist(0, 6)) == 'GIF87a' ||
              String.fromCharCodes(raw.sublist(0, 6)) == 'GIF89a');
      _logger.i(
          'File type: ${isGif ? 'GIF' : 'Image'} | Size: ${raw.length} bytes');

      final idPro = DateTime.now().millisecondsSinceEpoch % 50000;
      final randomBytes = Uint8List.fromList(List.generate(20, (_) => Random().nextInt(256)));
      final idRes = base64Encode(randomBytes);
      final sno = DateTime.now().millisecondsSinceEpoch % 65535;

      if (isGif) {
        final gifBase64 = base64Encode(raw);
        _logger.d('GIF base64 length: ${gifBase64.length}');
        final jsonCmd = {
          "pkts_program": {
            "id_pro": idPro,
            "property_pro": {
              "width": 64,
              "height": 64,
              "type_color": 2,
              "type_pro": 1, // immediate playback
              "play_fixed_time": 300,
              "show_now": 1,
              "send_gif_src": 1, // Only for GIF
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
        _logger.i('Built GIF JSON command: $jsonCmd');
        await sendImageOrGifViaJsBridge(jsonCmd, gifBase64: gifBase64);
        return; // Exit after GIF processing to prevent BMP processing
      } else {
        // Convert to BMP24
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
        _logger.d('BMP base64 length: ${base64Image.length}');
        final jsonCmd = {
          "pkts_program": {
            "id_pro": idPro,
            "property_pro": {
              "width": 64,
              "height": 64,
              "type_color": 2,
              "type_pro": 1, // immediate playback
              "play_fixed_time": 300,
              "show_now": 1,
              // no send_gif_src for images
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
        // Double-check: send_gif_src should not exist for images
        final pktsProgram = jsonCmd["pkts_program"];
        final propertyPro = pktsProgram is Map ? pktsProgram["property_pro"] : null;
        assert(propertyPro is Map ? propertyPro["send_gif_src"] == null : true);
        assert(jsonCmd["res_base64"] != null);
        _logger.i('Built image JSON command: $jsonCmd');
        await sendImageOrGifViaJsBridge(jsonCmd, base64Image: base64Image);
      }
      _logger.i('Upload process complete.');
    } catch (e, st) {
      _logger.e('Upload failed: $e\n$st');
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Upload failed: $e',
      ));
      rethrow;
    }
  }

  /// Sends a blank (all-black) canvas to the BLE device to clear the screen before drawing
  Future<void> sendBlankCanvas({int width = 64, int height = 64}) async {
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
          "type_pro": 1, // immediate playback
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

  /// Send a text program to BLE display via JS bridge (with animation, spacing, etc)
  Future<void> sendTextToBle({
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
    double? stayingTime, // in seconds
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
    // Debug log
    _logger.i('[DEBUG] sendRTDrawPoint payload: $cmd');
    await jsBridgeService.sendRTDraw(cmd);
    // Throttle BLE
    await Future.delayed(const Duration(milliseconds: 30));
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

  /// Enqueue a pixel for real-time drawing
  void enqueueDrawPixel(int x, int y, int color) {
    _drawBuffer.add([x, y]);
    // Restart flush timer every time a point is added
    _drawFlushTimer?.cancel();
    _drawFlushTimer = Timer(const Duration(milliseconds: 40), () {
      _flushDrawBuffer(color);
    });
  }

  Future<void> _flushDrawBuffer(int color) async {
    if (_drawBuffer.isEmpty) return;
    final cmd = {
      "cmd": {
        "RTDraw": {
          "type": 16,
          "color": color,
          "data": List.from(_drawBuffer),
        }
      },
      "sno": DateTime.now().millisecondsSinceEpoch % 1000,
    };
    _logger.i("[REALTIME] Sending  [32m [1m [4m");

    _logger.i("[REALTIME] Sending ${_drawBuffer.length} pixels to BLE");
    _drawBuffer.clear();
    try {
      await jsBridgeService.sendRTDraw(cmd);
    } catch (e) {
      _logger.e("❌ Failed to send RTDraw batch: $e");
    }
  }

  /// Sends raw binary data (e.g. BMP or GIF) to BLE in 180-byte chunks
  Future<void> sendBinaryToBle(Uint8List data, int idPro) async {
    if (_connectedDevice == null) {
      _logger.e('No device connected. Cannot send binary.');
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'No device connected. Cannot send binary.',
      ));
      return;
    }

    _logger.i('Starting binary send. Total: ${data.length} bytes');

    final services = await _connectedDevice!.discoverServices();
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
      _logger.e('Write characteristic not found for binary');
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Write characteristic not found for binary',
      ));
      return;
    }

    // Send 4-byte header first
    final header = Uint8List(4);
    ByteData.view(header.buffer).setUint32(0, data.length, Endian.little);
    try {
      await writeChar.write(header, withoutResponse: true);
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      _logger.e('Failed to write header: $e');
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to write header: $e',
      ));
      return;
    }

    const mtu = 180;
    for (int i = 0; i < data.length; i += mtu) {
      // Check connection before each chunk
      final deviceState = await _connectedDevice!.connectionState.first;
      if (deviceState != BluetoothConnectionState.connected) {
        _logger.e('Device disconnected during binary transfer.');
        emit(state.copyWith(
          status: DashboardStatus.error,
          errorMessage: 'Device disconnected during binary transfer.',
        ));
        return;
      }
      final chunk =
          data.sublist(i, (i + mtu > data.length) ? data.length : i + mtu);
      try {
        await writeChar.write(chunk, withoutResponse: true);
      } catch (e) {
        _logger.e('Failed to write chunk: $e');
        emit(state.copyWith(
          status: DashboardStatus.error,
          errorMessage: 'Failed to write chunk: $e',
        ));
        return;
      }
      _logger.d(
          'Sent chunk: ${chunk.length} bytes [${i}..${i + chunk.length - 1}]');
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _logger.i('Finished sending binary to BLE.');

    // Send explicit play command after binary
    await sendJsonCommand({
      "cmd": {
        "pgm_play": {
          "model": 0,
          "index": 0,
          "ids_pro": [idPro],
        }
      },
      "sno": DateTime.now().millisecondsSinceEpoch % 65535,
    });
  }

  // Helper to map Flutter Color to BLE color int
  int colorToBleInt(Color color) {
    if (color == Colors.red) return 255;
    if (color == Colors.green) return 65280;
    if (color == Colors.blue) return 16711680;
    if (color == Colors.yellow) return 65535;
    if (color == Colors.white) return 16777215;
    if (color == Colors.black) return 0;
    if (color == Colors.purple) return 16711935;
    // Add more as needed
    return 255;
  }

  /// Request the program group (list of program IDs) from the BLE device
  Future<void> getProgramGroup() async {
    final cmd = {
      "cmd": { "get": "pgm_play" },
      "sno": DateTime.now().millisecondsSinceEpoch % 1000,
    };
    await sendJsonCommand(cmd);
  }

  /// Request the resource IDs for a list of program IDs from the BLE device
  Future<void> getProgramResourceIds(List<int> programIds) async {
    final cmd = {
      "cmd": { "get": "pgm_key", "ids_pro": programIds },
      "sno": DateTime.now().millisecondsSinceEpoch % 1000,
    };
    await sendJsonCommand(cmd);
  }
}
