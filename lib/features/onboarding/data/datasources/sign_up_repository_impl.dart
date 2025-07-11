import 'package:app_settings/app_settings.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hookaba/core/network/network_dio.dart';
import 'package:hookaba/core/utils/api_constants.dart';
import 'package:hookaba/core/utils/ble_service.dart';

class SignUpRepositoryImpl {
  final BLEService bleService;
  final Box<String> pairedBox;
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  SignUpRepositoryImpl({
    required this.bleService,
    required this.pairedBox,
    required this.dioClient,
    required this.secureStorage,
  });

  Future<BluetoothDevice?> startScanWithPrefix() async {
    return await bleService.findDevice();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await bleService.connectToDevice(device);
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown Device (  ${device.remoteId})';
    await pairedBox.put(device.remoteId.toString(), deviceName);
    bleService.setConnectedDevice(device);
  }

  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    await bleService.disconnect(device);
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown Device (  ${device.remoteId})';
    pairedBox.delete(device.remoteId.toString());
  }

  Future<List<Map<String, String>>> loadPairedDevices() async {
    final pairedDevices = <Map<String, String>>[];
    for (var key in pairedBox.keys) {
      final name = pairedBox.get(key);
      if (name != null) {
        pairedDevices.add({
          'name': name,
          'id': key.toString(),
        });
      }
    }
    return pairedDevices;
  }

  Future<bool> requestBluetoothPermission() async {
    return await bleService.requestBluetoothPermission();
  }

  Future<void> openBluetoothSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
  }

  Future<void> stopScan() async {
    bleService.stopScan();
  }

  // --- Auth API methods ---
  Future<dynamic> requestOtp(String phone) async {
    final response = await dioClient.post(
      ApiEndpoints.authRequestOtp,
      data: {"phone": phone},
      requireAuth: false,
    );
    return response.data;
  }

  Future<dynamic> verifyOtp(String phone, String otp) async {
    final response = await dioClient.post(
      ApiEndpoints.authVerifyOtp,
      data: {"phone": phone, "otp": otp},
      requireAuth: false,
    );
    final data = response.data;
    if (data != null && data['access_token'] != null) {
      await secureStorage.write(key: 'user_token', value: data['access_token']);
    }
    return data;
  }


  Future<dynamic> createUser(String username, String number) async {
    final response = await dioClient.post(
      ApiEndpoints.users,
      data: {"username": username, "number": number},
    );
    return response.data;
  }
} 