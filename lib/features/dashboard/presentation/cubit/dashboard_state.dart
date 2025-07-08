part of 'dashboard_cubit.dart';


class DashboardState extends Equatable {
  final DashboardStatus status;
  final String? lastUploadedImage;
  final String? errorMessage;
  final BluetoothDevice? connectedDevice;
  final bool isDeviceConnected;
  final Map<String, dynamic>? deviceResponse;
  final double? uploadProgress; // 0.0 to 1.0, or null if not uploading

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.lastUploadedImage,
    this.errorMessage,
    this.connectedDevice,
    this.isDeviceConnected = false,
    this.deviceResponse,
    this.uploadProgress,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    String? lastUploadedImage,
    String? errorMessage,
    BluetoothDevice? connectedDevice,
    bool? isDeviceConnected,
    Map<String, dynamic>? deviceResponse,
    double? uploadProgress,
  }) {
    return DashboardState(
      status: status ?? this.status,
      lastUploadedImage: lastUploadedImage ?? this.lastUploadedImage,
      errorMessage: errorMessage ?? this.errorMessage,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      isDeviceConnected: isDeviceConnected ?? this.isDeviceConnected,
      deviceResponse: deviceResponse ?? this.deviceResponse,
      uploadProgress: uploadProgress,
    );
  }

  @override
  List<Object?> get props => [
    status, 
    lastUploadedImage, 
    errorMessage, 
    connectedDevice, 
    isDeviceConnected,
    deviceResponse,
    uploadProgress,
  ];
} 