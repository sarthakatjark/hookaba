part of 'dashboard_cubit.dart';

class DashboardState extends Equatable {
  final DashboardStatus status;
  final String? lastUploadedImage;
  final String? errorMessage;
  final BluetoothDevice? connectedDevice;
  final bool isDeviceConnected;
  final Map<String, dynamic>? deviceResponse;
  final double? uploadProgress; // 0.0 to 1.0, or null if not uploading
  final int? screenWidth;
  final int? screenHeight;
  final List<LibraryItemModel> libraryItems;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final List<LocalProgramModel> localPrograms;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.lastUploadedImage,
    this.errorMessage,
    this.connectedDevice,
    this.isDeviceConnected = false,
    this.deviceResponse,
    this.uploadProgress,
    this.screenWidth,
    this.screenHeight,
    this.libraryItems = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.localPrograms = const [],
  });

  DashboardState copyWith({
    DashboardStatus? status,
    String? lastUploadedImage,
    String? errorMessage,
    BluetoothDevice? connectedDevice,
    bool? isDeviceConnected,
    Map<String, dynamic>? deviceResponse,
    double? uploadProgress,
    int? screenWidth,
    int? screenHeight,
    List<LibraryItemModel>? libraryItems,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    List<LocalProgramModel>? localPrograms,
  }) {
    return DashboardState(
      status: status ?? this.status,
      lastUploadedImage: lastUploadedImage ?? this.lastUploadedImage,
      errorMessage: errorMessage ?? this.errorMessage,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      isDeviceConnected: isDeviceConnected ?? this.isDeviceConnected,
      deviceResponse: deviceResponse ?? this.deviceResponse,
      uploadProgress: uploadProgress,
      screenWidth: screenWidth ?? this.screenWidth,
      screenHeight: screenHeight ?? this.screenHeight,
      libraryItems: libraryItems ?? this.libraryItems,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      localPrograms: localPrograms ?? this.localPrograms,
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
    screenWidth,
    screenHeight,
    libraryItems,
    currentPage,
    totalPages,
    isLoadingMore,
    localPrograms,
  ];
} 