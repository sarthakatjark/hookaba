import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data'; // Added for Uint8List

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hookaba/core/utils/js_bridge_service.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart' as logger;
import 'package:permission_handler/permission_handler.dart';

/// Custom exception for permission-related errors
class BlePermissionException implements Exception {
  final String message;
  final bool canOpenSettings;
  final List<Permission> deniedPermissions;

  BlePermissionException(
    this.message, {
    this.canOpenSettings = true,
    this.deniedPermissions = const [],
  });

  @override
  String toString() => message;
}

@singleton
class BLEService {
  final logger.Logger _logger = logger.Logger();
  final JsBridgeService jsBridgeService;

  // Add StreamController for notifications
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notifications =>
      _notificationController.stream;

  // Cache for discovered services and characteristics
  final Map<String, List<BluetoothService>> _discoveredServices = {};

  // Track connected devices
  final Map<String, bool> _connectedDevices = {};

  // Known service and characteristic UUIDs
  static const String TARGET_SERVICE_UUID =
      '49535343-fe7d-4ae5-8fa9-9fafd205e455';
  static const String TARGET_CHARACTERISTIC_UUID =
      '49535343-aca3-481c-91ec-d85e28a60318';

  
  static const int DEFAULT_MTU_SIZE = 180; // Maximum MTU size for the device

  // Add command sequence numbers
  int _currentSno = 0;
  int getNextSno() {
    _currentSno = (_currentSno % 65535) + 1;
    return _currentSno;
  }

  // Add helper for LV encoding

  // Add command sequence helper

  BluetoothDevice? _connectedDevice;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  void setConnectedDevice(BluetoothDevice device) {
    _logger.i(
        'Setting connected device in BLEService: ${device.platformName} (${device.remoteId})');
    _connectedDevice = device;
  }

  BLEService(this.jsBridgeService) {
    // Monitor BLE status
    FlutterBluePlus.state.listen((state) {
      _logger.d('📡 BLE Status: $state');
    });
  }

  bool isDeviceConnected(String deviceId) {
    return _connectedDevices[deviceId] ?? false;
  }

  Stream<List<ScanResult>> get discoveredDevices => FlutterBluePlus.scanResults;

  Future<void> startScan() async {
    try {
      // Request platform-specific permissions before scanning
      try {
        final permissionsGranted = await requestBluetoothPermission();
        if (!permissionsGranted) {
          throw BlePermissionException(
            'Required permissions not granted. Please enable Bluetooth and Location permissions in Settings.',
            canOpenSettings: true,
          );
        }
      } catch (e) {
        if (e is BlePermissionException) {
          rethrow;
        }
        throw BlePermissionException(
          'Failed to check permissions: ${e.toString()}',
          canOpenSettings: false,
        );
      }

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
      );
      _logger.i('🔍 BLE scan started');
    } catch (e) {
      _logger.e('❌ Error starting scan', error: e);
      rethrow;
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      _logger.e('❌ Error stopping scan', error: e);
      rethrow;
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    // Request permissions first
    if (Platform.isAndroid) {
      final permissionsGranted = await requestBluetoothPermission();
      if (!permissionsGranted) {
        throw Exception(
            'Required permissions not granted. Please enable Bluetooth and Location permissions in Settings.');
      }
    }

    while (retryCount < maxRetries) {
      try {
        _logger.d(
            '🔄 Starting connection to device: ${device.remoteId} (Attempt ${retryCount + 1}/$maxRetries)');

        // 1. Stop any ongoing scan first
        await stopScan();

        // 2. Wait after scanning (critical for Android, especially Samsung)
        _logger.d('⏳ Waiting after scan stop...');
        await Future.delayed(const Duration(seconds: 2));

        // 3. Always force disconnect first, even if we think we're not connected
        _logger.d('🔌 Forcing disconnect for clean state...');
        try {
          await device.disconnect();
        } catch (_) {
          // Ignore disconnect errors - device might not be connected
        }

        // 4. Wait after disconnect (let BLE stack stabilize)
        await Future.delayed(const Duration(milliseconds: 500));

        // 5. Clear any existing connection state
        _connectedDevices[device.remoteId.str] = false;
        clearDiscoveredServices(device.remoteId.str);

        // 6. Double check permissions before connecting
        if (Platform.isAndroid) {
          final permissionsValid = await requestBluetoothPermission();
          if (!permissionsValid) {
            throw Exception(
                'Permissions were revoked during connection attempt');
          }
        }

        // 7. Attempt connection with longer timeout
        _logger.d('🔄 Attempting connection...');
        await device.connect(
          timeout: const Duration(seconds: 15),
          autoConnect: false, // Important: don't use autoConnect
        );

        // 8. Wait for connection to stabilize
        await Future.delayed(const Duration(seconds: 1));

        // 9. Verify connection was successful
        final connectionCheck = await device.isConnected;
        if (!connectionCheck) {
          throw Exception('Connection verification failed');
        }

        // 10. Connection successful - update state
        _connectedDevices[device.remoteId.str] = true;
        setConnectedDevice(device);
        _logger.i('✅ Successfully connected to device: ${device.remoteId}');

        // 11. Discover services after stable connection
        await discoverServicesAndCharacteristics(device);

        // 12. Set up notification forwarding to JS
        final services = await device.discoverServices();
        for (var service in services) {
          for (var char in service.characteristics) {
            final charUuid = char.uuid.toString().toLowerCase();
            if ((charUuid.contains('fff1') || charUuid.contains('ff01')) &&
                char.properties.notify) {
              await char.setNotifyValue(true);
              char.value.listen((data) {
                final hex = data
                    .map((b) => b.toRadixString(16).padLeft(2, '0'))
                    .join(' ');
                _logger.i('🔔 BLE notification received: $hex');
                onBleNotification(Uint8List.fromList(data));
              });
            }
          }
        }

        return; // Success! Exit the retry loop
      } catch (e) {
        if (e.toString().contains('permissions')) {
          _logger.e('❌ Permission error during connection');
          _logger.e('   Please ensure the following permissions are granted:');
          _logger.e('   - Bluetooth Scan');
          _logger.e('   - Bluetooth Connect');
          _logger.e('   - Location When In Use');
          rethrow; // Don't retry for permission errors
        }

        _logger.e(
            '❌ Connection error for ${device.remoteId} (Attempt ${retryCount + 1}/$maxRetries)',
            error: e);

        // Handle Android error code 133
        if (e.toString().contains('android-code: 133')) {
          _logger.w('⚠️ GATT Error 133 detected. This is common on Android.');
          _logger.w('   Possible causes:');
          _logger.w('   - Device paired with another phone/app');
          _logger.w('   - BLE device busy or not advertising');
          _logger.w('   - Android BLE stack issue (common on Samsung/Xiaomi)');

          // Clean up connection state
          await handleConnectionTimeout(device);

          // Wait longer between retries for GATT 133
          if (retryCount < maxRetries - 1) {
            _logger.d('⏳ Waiting ${retryDelay.inSeconds}s before retry...');
            await Future.delayed(retryDelay);
          }
        } else {
          // For other errors, throw immediately
          rethrow;
        }

        retryCount++;

        // If we've exhausted all retries, provide detailed error
        if (retryCount >= maxRetries) {
          _logger.e('❌ Connection failed after $maxRetries attempts');
          _logger.e('   Suggestions:');
          _logger.e('   1. Restart the BLE device');
          _logger.e('   2. Check if device is connected to another app/phone');
          _logger.e('   3. Toggle phone Bluetooth off/on');
          _logger.e('   4. Try with nRF Connect app to verify hardware');
          throw Exception('Failed to connect after $maxRetries attempts: $e');
        }
      }
    }
  }

  Future<List<BluetoothService>> discoverServicesAndCharacteristics(
      BluetoothDevice device) async {
    try {
      _logger
          .d('🔎 Starting service discovery for device ID: ${device.remoteId}');

      // Verify device is still connected
      final isConnected = await device.isConnected;
      if (!isConnected) {
        _logger.e('❌ Device is not connected during service discovery');
        throw Exception('Device disconnected during service discovery');
      }

      // Check if we already have discovered services for this device
      if (_discoveredServices.containsKey(device.remoteId.str)) {
        _logger.d('📚 Using cached services for device ID: ${device.remoteId}');
        final cachedServices = _discoveredServices[device.remoteId.str]!;
        _logDiscoveredServices(cachedServices);
        return cachedServices;
      }

      await logAllServicesAndCharacteristics(device);

      // Add a longer delay after connection before starting discovery
      _logger.d('⏳ Waiting for device to stabilize...');
      await Future.delayed(const Duration(seconds: 5));

      // Discover services with retry logic
      List<BluetoothService> services = [];
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          // Verify connection before each attempt
          if (!await device.isConnected) {
            _logger.e(
                '❌ Device disconnected during service discovery attempt ${retryCount + 1}');
            throw Exception('Device disconnected during service discovery');
          }

          services = await device.discoverServices();
          _logger.d(
              '📡 Found ${services.length} services on attempt ${retryCount + 1}');

          if (services.isNotEmpty) {
            _logger.d('✅ Services discovered successfully');
            break;
          }

          _logger.w(
              '⚠️ No services found, retrying... (attempt ${retryCount + 1}/$maxRetries)');
          await Future.delayed(const Duration(seconds: 2));
          retryCount++;
        } catch (e) {
          _logger.w(
              '⚠️ Service discovery attempt failed: $e (attempt ${retryCount + 1}/$maxRetries)');
          await Future.delayed(const Duration(seconds: 2));
          retryCount++;
          if (retryCount == maxRetries) {
            rethrow;
          }
        }
      }

      if (services.isEmpty) {
        _logger.e('❌ No services discovered after $maxRetries attempts');
        throw Exception(
            'No services discovered for device: ${device.remoteId}');
      }

      _logDiscoveredServices(services);

      // Cache the discovered services
      _discoveredServices[device.remoteId.str] = services;

      return services;
    } catch (e) {
      _logger.e('❌ Error during service discovery', error: e);
      _discoveredServices.remove(device.remoteId.str);
      rethrow;
    }
  }

  void _logDiscoveredServices(List<BluetoothService> services) {
    _logger.d('📋 Discovered Services (${services.length} total):');
    for (var service in services) {
      _logger.d('Discovered  Service UUID: ${service.uuid}');
      _logger.d('Discovered    isPrimary: ${service.isPrimary}');
      _logger.d(
          'Discovered    Characteristics (${service.characteristics.length}):');
      for (var characteristic in service.characteristics) {
        _logger.d('Discovered      - UUID: ${characteristic.uuid}');
        _logger.d('Discovered        Properties:');
        _logger
            .d('Discovered          read: ${characteristic.properties.read}');
        _logger
            .d('Discovered          write: ${characteristic.properties.write}');
        _logger.d(
            'Discovered          writeWithoutResponse: ${characteristic.properties.writeWithoutResponse}');
        _logger.d(
            'Discovered          notify: ${characteristic.properties.notify}');
        _logger.d(
            'Discovered          indicate: ${characteristic.properties.indicate}');
      }
    }
  }

  Future<void> writeToCharacteristic(
    BluetoothDevice device,
    String serviceUuid,
    String characteristicUuid,
    List<int> data, {
    bool withoutResponse = false,
  }) async {
    try {
      if (!isDeviceConnected(device.remoteId.str)) {
        throw Exception('Device is not connected: ${device.remoteId}');
      }

      _logger.d('📝 Attempting to write to characteristic:');
      _logger.d('  Device ID: ${device.remoteId}');
      _logger.d('  Service UUID: $serviceUuid');
      _logger.d('  Characteristic UUID: $characteristicUuid');
      _logger.d('  Data length: ${data.length} bytes');
      _logger.d(
          '  Payload: ${data.map((e) => '0x${e.toRadixString(16).padLeft(2, '0')}').join(' ')}');

      // Normalize UUIDs to ensure consistent format
      final normalizedServiceUuid = _normalizeUuid(serviceUuid);
      final normalizedCharacteristicUuid = _normalizeUuid(characteristicUuid);

      _logger.d('  Normalized Service UUID: $normalizedServiceUuid');
      _logger
          .d('  Normalized Characteristic UUID: $normalizedCharacteristicUuid');

      // Ensure services are discovered
      final services = await discoverServicesAndCharacteristics(device);

      // Find the service - try both full and short UUID formats
      final service = services.firstWhere(
        (s) {
          final serviceId = s.uuid.toString().toLowerCase();
          // Try matching both the full UUID and the short form
          return serviceId == normalizedServiceUuid.toLowerCase() ||
              serviceId.endsWith(normalizedServiceUuid.toLowerCase());
        },
        orElse: () {
          _logger.e('❌ Service not found: $normalizedServiceUuid');
          _logger.d(
              'Available services: ${services.map((s) => s.uuid.toString()).join(", ")}');
          throw Exception('Service not found: $normalizedServiceUuid');
        },
      );

      // Find the write characteristic - try both full and short UUID formats
      final characteristic = service.characteristics.firstWhere(
        (c) {
          final charId = c.uuid.toString().toLowerCase();
          // Try matching both the full UUID and the short form
          return charId == normalizedCharacteristicUuid.toLowerCase() ||
              charId.endsWith(normalizedCharacteristicUuid.toLowerCase());
        },
        orElse: () {
          _logger
              .e('❌ Characteristic not found: $normalizedCharacteristicUuid');
          throw Exception(
              'Characteristic not found: $normalizedCharacteristicUuid');
        },
      );

      // Log all characteristics for debugging
      _logger.d('📋 Available characteristics in service:');
      for (var c in service.characteristics) {
        _logger.d('  UUID: ${c.uuid}');
        _logger.d('  Properties:');
        _logger.d('    read: ${c.properties.read}');
        _logger.d('    write: ${c.properties.write}');
        _logger.d(
            '    writeWithoutResponse: ${c.properties.writeWithoutResponse}');
        _logger.d('    notify: ${c.properties.notify}');
        _logger.d('    indicate: ${c.properties.indicate}');
      }

      // Try to find and set up notify characteristic if available
      BluetoothCharacteristic? notifyChar;
      try {
        notifyChar = service.characteristics.firstWhere(
          (c) =>
              (c.uuid.toString().toLowerCase().contains('fff1') ||
                  c.uuid.toString().toLowerCase().contains('ff01')) &&
              c.properties.notify,
        );

        if (notifyChar != null) {
          //await _tryEnableNotify(notifyChar);
        }
      } catch (e) {
        _logger.w('⚠️ No notify characteristic found or setup failed: $e');
        _logger.w(
            '⚠️ This is normal for some devices/commands - continuing with write operation');
      }

      const mtuSize = DEFAULT_MTU_SIZE;
      if (data.length > mtuSize) {
        _logger.w('⚠️ Data exceeds MTU size, splitting into chunks...');

        // Split data into MTU-sized chunks
        for (var i = 0; i < data.length; i += mtuSize) {
          final end = (i + mtuSize < data.length) ? i + mtuSize : data.length;
          final chunk = data.sublist(i, end);

          await characteristic.write(chunk, withoutResponse: true);
          await Future.delayed(
              const Duration(milliseconds: 20)); // Small delay between chunks
        }
      } else {
        await characteristic.write(data, withoutResponse: true);
      }

      _logger.i('✅ Successfully wrote to characteristic');
    } catch (e) {
      _logger.e('❌ BLE write failed', error: e);
      rethrow;
    }
  }

  // /// Normalizes a UUID string to ensure consistent format
  // /// Handles both short (16-bit) and long (128-bit) UUIDs
  String _normalizeUuid(String uuid) {
    // Remove any non-alphanumeric characters
    final cleanUuid =
        uuid.replaceAll(RegExp(r'[^a-fA-F0-9]'), '').toLowerCase();

    // If it's a short UUID (16-bit), keep it as is
    if (cleanUuid.length <= 4) {
      return cleanUuid.padLeft(4, '0');
    }

    // If it's already a 128-bit UUID (32 characters)
    if (cleanUuid.length == 32) {
      // Insert hyphens in the correct positions
      return '${cleanUuid.substring(0, 8)}-${cleanUuid.substring(8, 12)}-'
          '${cleanUuid.substring(12, 16)}-${cleanUuid.substring(16, 20)}-'
          '${cleanUuid.substring(20)}';
    }

    // Return as-is if it's already in the correct format
    return uuid;
  }

  void clearDiscoveredServices(String deviceId) {
    _discoveredServices.remove(deviceId);
    _logger.d('🧹 Cleared cached services for device: $deviceId');
  }

  Future<void> disconnect(BluetoothDevice device) async {
    try {
      await device.disconnect();
      _connectedDevices.remove(device.remoteId.str);
      clearDiscoveredServices(device.remoteId.str);
      _logger.d('✅ Disconnected from device: ${device.remoteId}');
    } catch (e) {
      _logger.e('❌ Error disconnecting from device', error: e);
      rethrow;
    }
  }

  Future<void> logAllServicesAndCharacteristics(BluetoothDevice device) async {
    final logger = _logger; // Shortcut

    logger.i('🕵️ Discovering all services and characteristics...');
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        logger.i(
            'logAllServicesAndCharacteristics 🔍 Service UUID: ${service.uuid}');
        for (var characteristic in service.characteristics) {
          logger.i(
              'logAllServicesAndCharacteristics  - Characteristic UUID: ${characteristic.uuid}');
          logger.i('logAllServicesAndCharacteristics    Properties: '
              'read: ${characteristic.properties.read}, '
              'write: ${characteristic.properties.write}, '
              'writeWithoutResponse: ${characteristic.properties.writeWithoutResponse}, '
              'notify: ${characteristic.properties.notify}, '
              'indicate: ${characteristic.properties.indicate}');
        }
      }
      logger.i('✅ Finished logging all services and characteristics.');
    } catch (e) {
      logger.e('❌ Failed to discover and log services: $e');
    }
  }

  Future<(String, String)?> getTargetServiceAndCharacteristic(
      BluetoothDevice device) async {
    try {
      _logger.d(
          '🔍 Looking for target service and characteristic for device: ${device.remoteId}');

      // Get discovered services or discover them if not cached
      final services = await discoverServicesAndCharacteristics(device);

      // Look specifically for our known target service and characteristic
      final targetService = services.firstWhere(
        (service) =>
            service.uuid.str.toLowerCase() == TARGET_SERVICE_UUID.toLowerCase(),
        orElse: () {
          _logger.e('❌ Target service not found: $TARGET_SERVICE_UUID');
          throw Exception('Target service not found');
        },
      );

      final targetCharacteristic = targetService.characteristics.firstWhere(
        (char) =>
            char.uuid.str.toLowerCase() ==
            TARGET_CHARACTERISTIC_UUID.toLowerCase(),
        orElse: () {
          _logger.e(
              '❌ Target characteristic not found: $TARGET_CHARACTERISTIC_UUID');
          throw Exception('Target characteristic not found');
        },
      );

      // Verify the characteristic has the write property
      if (!targetCharacteristic.properties.write) {
        _logger.e('❌ Target characteristic does not support write operations');
        return null;
      }

      _logger.i('✅ Found target service: ${targetService.uuid.str}');
      _logger
          .i('✅ Found target characteristic: ${targetCharacteristic.uuid.str}');
      _logger.i('✅ Write property verified');

      return (targetService.uuid.str, targetCharacteristic.uuid.str);
    } catch (e) {
      _logger.e('❌ Error getting target service and characteristic', error: e);
      return null;
    }
  }

  bool isValidDeviceName(String name) {
    return name.startsWith("YS") ||
        name.startsWith("LO") ||
        name.startsWith("TL");
  }

  Future<BluetoothDevice?> findDevice() async {
    try {
      _logger.i('🔍 Starting device search...');

      // Start scanning
      await startScan();

      // Listen for scan results
      await for (final results in FlutterBluePlus.scanResults) {
        for (final result in results) {
          final name = result.device.platformName;
          _logger.i('Discovered device: $name (${result.device.remoteId})');
          if (isValidDeviceName(name)) {
            _logger
                .i('✅ Found valid device: $name (${result.device.remoteId})');

            // Stop scanning before connecting
            await stopScan();

            return result.device;
          }
        }
      }

      _logger.w('⚠️ No valid device found during scan');
      return null;
    } catch (e) {
      _logger.e('❌ Error during device search', error: e);
      return null;
    } finally {
      await stopScan();
    }
  }

  Future<void> handleConnectionTimeout(BluetoothDevice device) async {
    _logger.w('⚠️ Handling connection timeout for device: ${device.remoteId}');

    try {
      // 1. Force disconnect
      try {
        await device.disconnect();
      } catch (_) {}

      // 2. Clear connection state
      _connectedDevices[device.remoteId.str] = false;
      if (_connectedDevice?.remoteId.str == device.remoteId.str) {
        _connectedDevice = null;
      }

      // 3. Clear discovered services
      clearDiscoveredServices(device.remoteId.str);

      // 4. Wait for BLE stack to stabilize
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      _logger.e('❌ Error during timeout handling', error: e);
    }
  }

  // Add dispose method to clean up resources
  void dispose() {
    _notificationController.close();
  }

  /// Requests Bluetooth permissions for Android and iOS. Returns true if all permissions are granted, false otherwise.
  Future<bool> requestBluetoothPermission() async {
    try {
      _logger.i('Requesting Bluetooth permissions...');
      // Only request location permission on Android
      if (Platform.isAndroid) {
        _logger.i('Android platform detected, checking location permission...');
        final locationStatus = await Permission.location.status;
        if (!locationStatus.isGranted) {
          _logger.i('Requesting location permission for Android...');
          await Permission.location.request();
        }
      }
      // Request platform-specific Bluetooth permissions
      List<Permission> permissions = [];
      if (Platform.isAndroid) {
        permissions.addAll([
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ]);
      } else if (Platform.isIOS) {
        permissions.add(Permission.bluetooth);
      }
      Map<Permission, PermissionStatus> statuses = await permissions.request();
      _logger.i('Bluetooth permissions status: $statuses');
      final allGranted = statuses.values.every((status) => status.isGranted);
      return allGranted;
    } catch (e) {
      _logger.e('Error requesting Bluetooth permissions: $e');
      return false;
    }
  }

  // Add this method to forward BLE notifications to JS for parsing
  void forwardNotificationToJs(Uint8List data,
      [JsBridgeService? jsBridgeServiceOrController]) {
    final hexStr =
        data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    (jsBridgeServiceOrController ?? jsBridgeService)
        .parseTLVHexNotification(hexStr);
  }

  // Example BLE notification handler (add this where you handle notifications)
  void onBleNotification(Uint8List data) {
    final hexStr =
        data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    _logger.i('🔔 BLE notification received: $hexStr');
    // Forward to JS bridge for parsing
    forwardNotificationToJs(data);
  }
}
