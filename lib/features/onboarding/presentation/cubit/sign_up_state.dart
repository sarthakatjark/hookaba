part of 'sign_up_cubit.dart';

// Combined SignUpState
class SignUpState extends Equatable {
  final String name;
  final String phone;
  final bool loading;
  final String? error;
  final BluetoothPermissionStatus bluetoothStatus;
  final bool scanning;
  final bool connecting;
  final String? connectingDeviceId;
  final List<BluetoothDevice> scannedDevices;
  final List<Map<String, String>> pairedDevices;
  final Map<String, bool> connectedDevices;

  const SignUpState({
    this.name = '',
    this.phone = '',
    this.loading = false,
    this.error,
    this.bluetoothStatus = BluetoothPermissionStatus.denied,
    this.scanning = false,
    this.connecting = false,
    this.connectingDeviceId,
    this.scannedDevices = const [],
    this.pairedDevices = const [],
    this.connectedDevices = const {},
  });

  SignUpState copyWith({
    String? name,
    String? phone,
    bool? loading,
    String? error,
    BluetoothPermissionStatus? bluetoothStatus,
    bool? scanning,
    bool? connecting,
    String? connectingDeviceId,
    List<BluetoothDevice>? scannedDevices,
    List<Map<String, String>>? pairedDevices,
    Map<String, bool>? connectedDevices,
  }) {
    return SignUpState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      loading: loading ?? this.loading,
      error: error,
      bluetoothStatus: bluetoothStatus ?? this.bluetoothStatus,
      scanning: scanning ?? this.scanning,
      connecting: connecting ?? this.connecting,
      connectingDeviceId: connectingDeviceId ?? this.connectingDeviceId,
      scannedDevices: scannedDevices ?? this.scannedDevices,
      pairedDevices: pairedDevices ?? this.pairedDevices,
      connectedDevices: connectedDevices ?? this.connectedDevices,
    );
  }

  @override
  List<Object?> get props => [
        name,
        phone,
        loading,
        error,
        bluetoothStatus,
        scanning,
        connecting,
        connectingDeviceId,
        scannedDevices,
        pairedDevices,
        connectedDevices,
      ];
}

enum BluetoothPermissionStatus {
  initial,
  granted,
  denied,
  skipped
}
