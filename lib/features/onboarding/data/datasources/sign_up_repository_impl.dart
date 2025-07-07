import 'package:app_settings/app_settings.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive/hive.dart';
import 'package:hookaba/core/utils/ble_service.dart';

class SignUpRepositoryImpl {
  final BLEService bleService;
  final Box<String> pairedBox;

  SignUpRepositoryImpl({
    required this.bleService,
    required this.pairedBox,
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
} 