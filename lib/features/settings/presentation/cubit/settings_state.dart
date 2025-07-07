import 'package:equatable/equatable.dart';

enum ConnectionMode {
  bluetooth,
  wifi
}

class SettingsState extends Equatable {
  final bool isReturnOn;
  final ConnectionMode selectedMode;
  final String currentVersion;
  final String deviceCode;
  final String programVersion;
  final String controlModel;
  final bool isPasswordEnabled;
  final bool showClearConfirmation;

  const SettingsState({
    this.isReturnOn = false,
    this.selectedMode = ConnectionMode.bluetooth,
    this.currentVersion = 'GMSRM_JA2ZB',
    this.deviceCode = 'GMSRM_JA2ZB',
    this.programVersion = 'V0.8.9/V01',
    this.controlModel = 'EVS3-GMSRM_JA2ZB',
    this.isPasswordEnabled = false,
    this.showClearConfirmation = false,
  });

  SettingsState copyWith({
    bool? isReturnOn,
    ConnectionMode? selectedMode,
    String? currentVersion,
    String? deviceCode,
    String? programVersion,
    String? controlModel,
    bool? isPasswordEnabled,
    bool? showClearConfirmation,
  }) {
    return SettingsState(
      isReturnOn: isReturnOn ?? this.isReturnOn,
      selectedMode: selectedMode ?? this.selectedMode,
      currentVersion: currentVersion ?? this.currentVersion,
      deviceCode: deviceCode ?? this.deviceCode,
      programVersion: programVersion ?? this.programVersion,
      controlModel: controlModel ?? this.controlModel,
      isPasswordEnabled: isPasswordEnabled ?? this.isPasswordEnabled,
      showClearConfirmation: showClearConfirmation ?? this.showClearConfirmation,
    );
  }

  @override
  List<Object?> get props => [
        isReturnOn,
        selectedMode,
        currentVersion,
        deviceCode,
        programVersion,
        controlModel,
        isPasswordEnabled,
        showClearConfirmation,
      ];
} 