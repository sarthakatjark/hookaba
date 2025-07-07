import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void toggleReturn() {
    emit(state.copyWith(isReturnOn: !state.isReturnOn));
  }

  void setConnectionMode(ConnectionMode mode) {
    emit(state.copyWith(selectedMode: mode));
  }

  void togglePasswordSettings() {
    emit(state.copyWith(isPasswordEnabled: !state.isPasswordEnabled));
  }

  void showClearConfirmation() {
    emit(state.copyWith(showClearConfirmation: true));
  }

  void hideClearConfirmation() {
    emit(state.copyWith(showClearConfirmation: false));
  }

  Future<void> clearAll() async {
    // Implement clear all functionality
    hideClearConfirmation();
  }

  Future<void> updateFirmware() async {
    // Implement firmware update functionality
  }
} 