import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hookaba/core/utils/ble_service.dart';
import 'package:hookaba/core/utils/enum.dart' show AnimationType;
import 'package:hookaba/core/utils/js_bridge_service.dart';
import 'package:hookaba/features/dashboard/data/datasources/dashboard_repository_impl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart' as logger;

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final BLEService bleService;
  final DashboardRepositoryImpl dashboardRepository;
  final _logger = logger.Logger();
  //final _imagePicker = ImagePicker();

  final JsBridgeService jsBridgeService;

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
    required this.dashboardRepository,
    required this.jsBridgeService,
    Map<String, dynamic>? extra,
  }) : super(const DashboardState()) {
    _logger.i(
        'DashboardCubit initialized. Initial state: _connectedDevice =  [32m$_connectedDevice, _isDeviceConnected = $_isDeviceConnected');

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

    // Listen to JS bridge TLV stream
    jsBridgeService.tlvStream.listen((tlvBytes) {
      sendTlvToBle(tlvBytes);
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

  Future<void> sendTlvToBle(Uint8List tlvBytes) async {
    if (_connectedDevice == null) {
      _logger.e('No device connected. Cannot send TLV.');
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'No device connected. Cannot send TLV.',
      ));
      return;
    }
    try {
      await dashboardRepository.sendTlvToBle(_connectedDevice!, tlvBytes);
      emit(state.copyWith(uploadProgress: 1.0));
      _logger.i('TLV sent to BLE device.');
      // Optionally reset progress after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(uploadProgress: null));
    } catch (e) {
      _logger.e('Failed to send TLV: $e');
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to send TLV: $e',
        uploadProgress: null,
      ));
    }
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
      await dashboardRepository.sendJsonCommand(_connectedDevice!, jsonCmd);
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
    if (_connectedDevice == null) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'No device connected',
      ));
      return;
    }
    try {
      await dashboardRepository.sendPowerOffSequence(_connectedDevice!);
      emit(state.copyWith(status: DashboardStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to send power off: $e',
      ));
    }
  }

  /// Use the JS bridge to encode and send an image or GIF
  Future<void> sendImageOrGifViaJsBridge(Map<String, dynamic> jsonCmd,
      {String? base64Image, String? gifBase64}) async {
    try {
      await dashboardRepository.sendImageOrGifViaJsBridge(jsonCmd,
          base64Image: base64Image, gifBase64: gifBase64);
      emit(state.copyWith(status: DashboardStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to send image/GIF: $e',
      ));
    }
  }

  /// Uploads an image or GIF file, processes it, and sends to BLE via JS bridge
  Future<void> uploadImageOrGif(XFile file) async {
    if (_connectedDevice == null) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'No device connected',
      ));
      return;
    }
    try {
      await dashboardRepository.uploadImageOrGif(_connectedDevice!, file);
      emit(state.copyWith(status: DashboardStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Upload failed: $e',
      ));
      rethrow;
    }
  }

  /// Sends a blank (all-black) canvas to the BLE device to clear the screen before drawing
  Future<void> sendBlankCanvas({int width = 64, int height = 64}) async {
    if (_connectedDevice == null) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'No device connected',
      ));
      return;
    }
    try {
      await dashboardRepository.sendBlankCanvas(_connectedDevice!,
          width: width, height: height);
      emit(state.copyWith(status: DashboardStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to send blank canvas: $e',
      ));
    }
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
    double? stayingTime,
  }) async {
    if (_connectedDevice == null) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'No device connected',
      ));
      return;
    }
    try {
      await dashboardRepository.sendTextToBle(
        _connectedDevice!,
        text: text,
        color: color,
        size: size,
        bold: bold,
        italic: italic,
        spaceFont: spaceFont,
        spaceLine: spaceLine,
        alignHorizontal: alignHorizontal,
        alignVertical: alignVertical,
        infoAnimate: infoAnimate,
        stayingTime: stayingTime,
      );
      emit(state.copyWith(status: DashboardStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to send text: $e',
      ));
    }
  }

  Future<void> sendRTDrawPoint({
    required int x,
    required int y,
    required int color,
  }) async {
    try {
      await dashboardRepository.sendRTDrawPoint(x: x, y: y, color: color);
      emit(state.copyWith(status: DashboardStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to send RTDraw point: $e',
      ));
    }
  }

  Map<String, dynamic>? animationTypeToInfoAnimate(AnimationType? type) {
    return dashboardRepository.animationTypeToInfoAnimate(type);
  }

  /// Enqueue a pixel for real-time drawing
  void enqueueDrawPixel(int x, int y, int color) {
    _drawBuffer.add([x, y]);
    // Restart flush timer every time a point is added
    _drawFlushTimer?.cancel();
    _drawFlushTimer = Timer(const Duration(milliseconds: 40), () {
      flushDrawBuffer(color);
    });
  }

  Future<void> flushDrawBuffer(int color) async {
    try {
      await dashboardRepository.flushDrawBuffer(_drawBuffer, color);
      _drawBuffer.clear();
      emit(state.copyWith(status: DashboardStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to flush draw buffer: $e',
      ));
    }
  }

  /// Sends raw binary data (e.g. BMP or GIF) to BLE in 180-byte chunks
  Future<void> sendBinaryToBle(Uint8List data, int idPro) async {
    if (_connectedDevice == null) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'No device connected. Cannot send binary.',
      ));
      return;
    }
    try {
      await dashboardRepository.sendBinaryToBle(_connectedDevice!, data, idPro);
      emit(state.copyWith(status: DashboardStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to send binary: $e',
      ));
    }
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
    if (_connectedDevice == null) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'No device connected',
      ));
      return;
    }
    try {
      await dashboardRepository.getProgramGroup(_connectedDevice!);
      emit(state.copyWith(status: DashboardStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to get program group: $e',
      ));
    }
  }

  /// Request the resource IDs for a list of program IDs from the BLE device
  Future<void> getProgramResourceIds(List<int> programIds) async {
    if (_connectedDevice == null) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'No device connected',
      ));
      return;
    }
    try {
      await dashboardRepository.getProgramResourceIds(
          _connectedDevice!, programIds);
      emit(state.copyWith(status: DashboardStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to get program resource IDs: $e',
      ));
    }
  }
} 