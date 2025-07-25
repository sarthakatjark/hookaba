import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hookaba/core/utils/ble_service.dart';
import 'package:hookaba/core/utils/enum.dart'
    show AnimationType, DashboardStatus;
import 'package:hookaba/core/utils/js_bridge_service.dart';
import 'package:hookaba/core/utils/local_program_service.dart';
import 'package:hookaba/features/dashboard/data/datasources/dashboard_repository_impl.dart';
import 'package:hookaba/features/dashboard/data/models/library_item_model.dart';
import 'package:hookaba/features/program_list/data/models/local_program_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart' as logger;
import 'package:path_provider/path_provider.dart';

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

    getDeviceScreenProperty();
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
      await dashboardRepository.sendTlvToBle(
        _connectedDevice!,
        tlvBytes,
        onProgress: (progress) {
          emit(state.copyWith(uploadProgress: progress));
        },
      );
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

  /// Sends a power-off command to the BLE device
  Future<void> sendPowerSequence({required int power, required int sno}) async {
    if (_connectedDevice == null) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'No device connected',
      ));
      return;
    }
    try {
      await dashboardRepository.sendPowerSequence(power: power, sno: sno);
      emit(state.copyWith(status: DashboardStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to send power command: $e',
      ));
    }
  }

  /// Sends a brightness command to the BLE device via JS bridge
  Future<void> sendBrightness(int brightnessValue) async {
    if (_connectedDevice == null) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'No device connected',
      ));
      return;
    }
    try {
      await dashboardRepository.sendBrightness(brightnessValue);
      emit(state.copyWith(status: DashboardStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to send brightness command: $e',
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
      await dashboardRepository.uploadImageOrGif(
        _connectedDevice!,
        file,
        width: state.screenWidth ?? 64,
        height: state.screenHeight ?? 64,
      );
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

  /// Erases a single pixel (sets it to black) on the BLE device
  Future<void> erasePixel(int x, int y) async {
    const int black = 0;
    await dashboardRepository.sendRTDrawPoint(x: x, y: y, color: black);
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

  /// Picks an image, crops to box, compresses, and returns the processed XFile (or null if cancelled)
  Future<XFile?> pickAndProcessImage(BuildContext context) async {
    return await dashboardRepository.pickAndProcessImage(context);
  }

  /// Requests the device's screen property (width and height)
  Future<void> getDeviceScreenProperty() async {
    if (_connectedDevice == null) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'No device connected',
      ));
      return;
    }
    try {
      final property =
          await dashboardRepository.getDeviceScreenProperty(_connectedDevice!);
      if (property != null &&
          property.containsKey('width') &&
          property.containsKey('height')) {
        emit(state.copyWith(
          screenWidth: property['width'],
          screenHeight: property['height'],
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to get device screen property: $e',
      ));
    }
  }

  void refreshConnection() {
    final connectedDevice = bleService.connectedDevice;
    if (connectedDevice != null) {
      _connectedDevice = connectedDevice;
      _isDeviceConnected = true;
      emit(state.copyWith(
        connectedDevice: connectedDevice,
        isDeviceConnected: true,
      ));
    } else {
      _connectedDevice = null;
      _isDeviceConnected = false;
      emit(state.copyWith(
        connectedDevice: null,
        isDeviceConnected: false,
      ));
    }
  }

  Future<void> fetchLibraryItems(
      {int page = 1, int perPage = 10, bool loadMore = false}) async {
    if (state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await dashboardRepository.fetchLibraryList(
          page: page, perPage: perPage);
      final items = result['items'] as List<LibraryItemModel>;
      final totalPages = result['totalPages'] as int;
      final currentPage = result['page'] as int;

      emit(state.copyWith(
        status: DashboardStatus.success,
        libraryItems: loadMore ? [...state.libraryItems, ...items] : items,
        currentPage: currentPage,
        totalPages: totalPages,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to fetch library items: $e',
        isLoadingMore: false,
      ));
    }
  }

  Future<void> uploadLibraryImageToBle(LibraryItemModel item,
      {void Function(double progress)? onProgress}) async {
    try {
      _logger.i('[LibraryUpload] Start upload for:  [${item.imageUrl}');
      // Download image to temp file
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/temp_library_image';
      _logger.i('[LibraryUpload] Temp path: $tempPath');
      final response = await Dio().get<List<int>>(
        item.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      _logger.i('[LibraryUpload] Downloaded bytes: ${response.data?.length}');
      final file = await File(tempPath).writeAsBytes(response.data!);
      _logger.i('[LibraryUpload] File written: ${file.path}');

      // Convert to XFile
      final xFile = XFile(file.path);
      _logger.i('[LibraryUpload] XFile created: ${xFile.path}');

      if (_connectedDevice == null) {
        _logger.e('[LibraryUpload] No device connected!');
        emit(state.copyWith(
          status: DashboardStatus.error,
          errorMessage: 'No device connected',
          uploadProgress: null,
        ));
        return;
      }
      _logger.i('[LibraryUpload] Uploading to BLE device: ${_connectedDevice!.platformName}');
      await dashboardRepository.uploadImageOrGif(
        _connectedDevice!,
        xFile,
        width: state.screenWidth ?? 64,
        height: state.screenHeight ?? 64,
        onProgress: (progress) {
          emit(state.copyWith(uploadProgress: progress));
          if (onProgress != null) onProgress(progress);
        },
      );
      _logger.i('[LibraryUpload] Upload to BLE complete!');
      emit(state.copyWith(status: DashboardStatus.success, uploadProgress: null));
    } catch (e, st) {
      _logger.e('[LibraryUpload] ERROR: $e\n$st');
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to upload image from library: $e',
        uploadProgress: null,
      ));
    }
  }

  Future<void> loadLocalPrograms() async {
    final localPrograms = LocalProgramService().getProgramsPage(0, 4);
    emit(state.copyWith(localPrograms: localPrograms));
  }

  /// Saves the current drawing as a local program
  Future<void> saveCurrentDrawingAsLocalProgram({
    required List<Offset> points,
    required Color color,
    int width = 64,
    int height = 64,
    String? name,
  }) async {
    await DashboardRepositoryImpl.saveDrawingAsLocalProgram(
      points: points,
      color: color,
      width: width,
      height: height,
      name: name,
    );
  }
}
