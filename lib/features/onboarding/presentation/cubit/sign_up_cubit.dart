import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show Cubit;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/features/onboarding/data/datasources/sign_up_repository_impl.dart';
import 'package:hookaba/features/onboarding/presentation/widgets/permission_denied_dialog.dart';
import 'package:logger/logger.dart' as logger;
import 'package:permission_handler/permission_handler.dart';

part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  final SignUpRepositoryImpl signUpRepository;
  final _logger = logger.Logger();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _scanTimeout;

  SignUpCubit({
    required this.signUpRepository,
  }) : super(const SignUpState());

  @override
  Future<void> close() {
    _logger.d('🚪 Closing SignUpCubit and cancelling subscriptions.');
    
    // Only cancel subscriptions and clean up own state
    _scanSubscription?.cancel();
    _scanTimeout?.cancel();
    
    // Clear only SignUpCubit's connection state
    emit(state.copyWith(connectedDevices: {}));
    
    _logger.d('✅ SignUpCubit cleanup complete');
    return super.close();
  }

  Future<void> requestBluetoothPermission(BuildContext context,
      {bool navigateDirectly = false}) async {
    try {
      _logger.i('Requesting Bluetooth permissions...');
      final allGranted = await signUpRepository.requestBluetoothPermission();
      if (!context.mounted) return;
      if (allGranted) {
        _logger.i('All Bluetooth permissions granted, navigating to device search page');
        emit(state.copyWith(bluetoothStatus: BluetoothPermissionStatus.granted));
        if (navigateDirectly) {
          context.go('/onboarding/searchingdevicepage');
        }
      } else {
        _logger.w('One or more Bluetooth permissions denied');
        emit(state.copyWith(bluetoothStatus: BluetoothPermissionStatus.denied));
        // Check if any permission is permanently denied
        final isPermanentlyDenied = await Permission.bluetooth.status.then((s) => s.isPermanentlyDenied);
        if (isPermanentlyDenied) {
          _logger.w('Some permissions are permanently denied, opening app settings');
          await signUpRepository.openBluetoothSettings();
        } else {
          await _showPermissionDeniedDialog(context, permanentlyDenied: false);
        }
      }
    } catch (e) {
      _logger.e('Error requesting Bluetooth permissions: $e');
      if (context.mounted) {
        emit(state.copyWith(bluetoothStatus: BluetoothPermissionStatus.denied));
        await _showPermissionDeniedDialog(context);
      }
    }
  }

  Future<void> _showPermissionDeniedDialog(BuildContext context,
      {bool permanentlyDenied = false}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PermissionDeniedDialog(
        permanentlyDenied: permanentlyDenied,
        onCancel: () {
          Navigator.of(ctx).pop();
          context.go('/onboarding/signup');
        },
        onSettings: () async {
          Navigator.of(ctx).pop();
          _logger.i('Opening Bluetooth settings...');
          await signUpRepository.openBluetoothSettings();
          await Future.delayed(const Duration(seconds: 1));
          if (!context.mounted) return;
          final newStatus = await Permission.bluetooth.status;
          _logger.i('Bluetooth permission status after settings: $newStatus');
          if (newStatus.isGranted) {
            _logger.i('Bluetooth permission granted after settings, navigating to device search page');
            emit(state.copyWith(bluetoothStatus: BluetoothPermissionStatus.granted));
            context.go('/onboarding/searchingdevicepage');
          } else {
            _logger.w('Bluetooth permission still not granted after settings');
            emit(state.copyWith(bluetoothStatus: BluetoothPermissionStatus.denied));
            await _showPermissionDeniedDialog(context, permanentlyDenied: newStatus.isPermanentlyDenied);
          }
        },
      ),
    );
  }

  void skipBluetoothPermission() {
    emit(state.copyWith(bluetoothStatus: BluetoothPermissionStatus.skipped));
  }

  // SignUp logic
  void nameChanged(String name) => emit(state.copyWith(name: name));
  void phoneChanged(String phone) => emit(state.copyWith(phone: phone));
  void submit() async {
    emit(state.copyWith(loading: true, error: null));
    await Future.delayed(const Duration(seconds: 1));
    // Simulate success
    emit(state.copyWith(loading: false));
  }

  // Device Scan logic
  void startScanWithPrefix() async {
    if (state.scanning) {
      _logger.d('📱 Already scanning, skipping...');
      return;
    }

    _logger.i('🔍 Starting BLE scan...');
    emit(state.copyWith(scanning: true, scannedDevices: []));

    try {
      final device = await signUpRepository.startScanWithPrefix();
      if (device != null) {
        _logger.i('✅ Device found: \\${device.platformName}');
        emit(state.copyWith(scannedDevices: [device], scanning: false));
      } else {
        _logger.w('⚠️ No valid device found during scan');
        emit(state.copyWith(scanning: false));
      }
    } catch (e) {
      _logger.e('❌ Error during scan: \\${e}');
      emit(state.copyWith(scanning: false));
    }
  }

  void stopScan() {
    _logger.i('🛑 Stopping BLE scan...');
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _scanTimeout?.cancel();
    _scanTimeout = null;
    signUpRepository.stopScan();
    emit(state.copyWith(scanning: false));
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _logger.i('🔌 Attempting to connect to device: \\${device.platformName}');
      emit(state.copyWith(
        connecting: true,
        error: null,
        connectingDeviceId: device.remoteId.str,
      ));

      // Use BLEService's connectToDevice directly
      await signUpRepository.connectToDevice(device);

      // Store device in local storage
      final deviceName = device.platformName.isNotEmpty
          ? device.platformName
          : 'Unknown Device (\\${device.remoteId})';
      // await pairedBox.put(device.remoteId.toString(), deviceName); // Removed as per new_code

      // Update state with connected device and paired devices
      final updatedDevices = Map<String, bool>.from(state.connectedDevices);
      updatedDevices[deviceName] = true;

      final updatedPairedDevices = List<Map<String, String>>.from(state.pairedDevices);
      updatedPairedDevices.add({
        'name': deviceName,
        'id': device.remoteId.toString(),
      });

      emit(state.copyWith(
        connectedDevices: updatedDevices,
        pairedDevices: updatedPairedDevices,
        connecting: false,
        connectingDeviceId: null,
      ));

      _logger.i('✅ Successfully connected to device: \\${deviceName}');

      // Store the connected device in the BLE service for the dashboard
      // bleService.setConnectedDevice(device); // Removed as per new_code
    } catch (e) {
      _logger.e('❌ Error connecting to device: \\${e}');
      emit(state.copyWith(
        connecting: false,
        connectingDeviceId: null,
        error: 'Failed to connect to device. Please try again.',
      ));
    }
  }

  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    try {
      _logger.i('🔌 Attempting to disconnect from device: ${device.platformName}');
      
      await signUpRepository.disconnectFromDevice(device);

      // Update state to remove disconnected device
      final updatedDevices = Map<String, bool>.from(state.connectedDevices);
      updatedDevices.remove(device.platformName);
      emit(state.copyWith(connectedDevices: updatedDevices));

      _logger.i('✅ Successfully disconnected from device: ${device.platformName}');
    } catch (e) {
      _logger.e('❌ Error disconnecting from device: $e');
      emit(state.copyWith(
        error: 'Failed to disconnect from device. Please try again.',
      ));
    }
  }

  // Add method to load paired devices from storage
  Future<void> loadPairedDevices() async {
    try {
      _logger.i('📱 Loading paired devices from storage...');
      final pairedDevices = await signUpRepository.loadPairedDevices();
      
      emit(state.copyWith(pairedDevices: pairedDevices));
      _logger.i('✅ Loaded ${pairedDevices.length} paired devices');
    } catch (e) {
      _logger.e('❌ Error loading paired devices: $e');
    }
  }

  // Validation functions
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Remove any non-digit characters for validation
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 11) {
      return 'Phone number must be 10-11 digits';
    }
    return null;
  }
}
