import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hookaba/features/split_screen/data/datasources/split_screen_repository_impl.dart';

import 'split_screen_state.dart';

class SplitScreenCubit extends Cubit<SplitScreenState> {
  final SplitScreenRepositoryImpl splitScreenRepository;
  SplitScreenCubit({required this.splitScreenRepository}) : super(const SplitScreenState());

  void toggleMode() {
    emit(state.copyWith(
      mode: state.mode == SplitScreenMode.single
          ? SplitScreenMode.dual
          : SplitScreenMode.single,
    ));
  }

  void updateSplitRatio(double ratio) {
    emit(state.copyWith(splitRatio: ratio.clamp(0.1, 0.9)));
  }

  void updateLeftScreenColor(Color color) {
    emit(state.copyWith(leftScreenColor: color));
  }

  void updateRightScreenColor(Color color) {
    emit(state.copyWith(rightScreenColor: color));
  }

  void toggleActiveScreen() {
    emit(state.copyWith(isLeftScreenActive: !state.isLeftScreenActive));
  }

  void updateBrightness(double brightness) {
    emit(state.copyWith(brightness: brightness.clamp(0.0, 1.0)));
  }

  void updateActiveScreenColor(Color color) {
    if (state.isLeftScreenActive) {
      updateLeftScreenColor(color);
    } else {
      updateRightScreenColor(color);
    }
  }

  // --- Split content logic ---
  void setSplitImage(int index, ImageProvider image, {bool isGif = false}) {
    final updated = List<SplitScreenItem>.from(state.splits);
    updated[index] = SplitScreenItem(image: image, isGif: isGif);
    emit(state.copyWith(splits: updated));
  }

  void setSplitText(int index, String text, TextStyle style) {
    final updated = List<SplitScreenItem>.from(state.splits);
    updated[index] = SplitScreenItem(text: text, textStyle: style);
    emit(state.copyWith(splits: updated));
  }

  void clearSplit(int index) {
    final updated = List<SplitScreenItem>.from(state.splits);
    updated[index] = const SplitScreenItem();
    emit(state.copyWith(splits: updated));
  }

  Future<void> handleSplitAndUpload(BuildContext context, DashboardCubit dashboardCubit, {double? splitRatio}) async {
    await splitScreenRepository.handleSplitAndUpload(
      context: context,
      dashboardCubit: dashboardCubit,
      splits: state.splits,
      splitRatio: splitRatio ?? state.splitRatio,
      onError: (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))),
      onSuccess: (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))),
    );
  }

  Future<Uint8List> getCombinedPreviewBmp({double? splitRatio}) async {
    return await splitScreenRepository.getCombinedPreviewBmp(
      splits: state.splits,
      splitRatio: splitRatio ?? state.splitRatio,
    );
  }

  Future<Uint8List> getCombinedPreviewPng({double? splitRatio}) async {
    return await splitScreenRepository.getCombinedPreviewPng(
      splits: state.splits,
      splitRatio: splitRatio ?? state.splitRatio,
    );
  }

  Future<void> sendCurrentSplitToBle({
    required DashboardCubit dashboardCubit,
    required BuildContext context,
  }) async {
    await splitScreenRepository.sendCurrentSplitToBle(
      dashboardCubit: dashboardCubit,
      context: context,
      splits: state.splits,
      splitRatio: state.splitRatio,
      onError: (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))),
      onSuccess: (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))),
    );
  }
}
