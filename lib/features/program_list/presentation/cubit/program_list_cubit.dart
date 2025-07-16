import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookaba/core/utils/enum.dart' show DashboardStatus;
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hookaba/features/program_list/data/datasources/programs_datasource.dart';
import 'package:hookaba/features/program_list/data/models/local_program_model.dart';

import 'program_list_state.dart';

class ProgramListCubit extends Cubit<ProgramListState> {
  final ProgramDataSource programDataSource;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isFetching = false;
  bool _hasMore = true;

  ProgramListCubit(this.programDataSource) : super(const ProgramListState());

  void fetchProgramsFromLocal({int page = 0, int? pageSize}) {
    final size = pageSize ?? _pageSize;
    final programs = programDataSource.getProgramsPage(page, size);
    emit(state.copyWith(programs: programs));
    _currentPage = page;
    _hasMore = programs.length == size;
  }

  void fetchNextPage() {
    if (_isFetching || !_hasMore) return;
    _isFetching = true;
    final nextPage = _currentPage + 1;
    final newPrograms = programDataSource.getProgramsPage(nextPage, _pageSize);
    if (newPrograms.isNotEmpty) {
      emit(state.copyWith(programs: [...state.programs, ...newPrograms]));
      _currentPage = nextPage;
      _hasMore = newPrograms.length == _pageSize;
    } else {
      _hasMore = false;
    }
    _isFetching = false;
  }

  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;

  @override
  Future<void> close() {
    return super.close();
  }

  void toggleMode() {
    emit(state.copyWith(
      selectedMode: state.selectedMode == ProgramMode.loop
          ? ProgramMode.single
          : ProgramMode.loop,
    ));
  }

  void selectProgram(LocalProgramModel program) {
    emit(state.copyWith(selectedProgram: program));
  }

  void showDeleteDialog(LocalProgramModel program) {
    emit(state.copyWith(
      selectedProgram: program,
      isDeleteDialogVisible: true,
    ));
  }

  void hideDeleteDialog() {
    emit(state.copyWith(
      isDeleteDialogVisible: false,
    ));
  }

  void deleteProgram(BuildContext context) {
    if (state.selectedProgram != null) {
      final updatedPrograms = List<LocalProgramModel>.from(state.programs)
        ..removeWhere((program) => program.id == state.selectedProgram!.id);
      emit(state.copyWith(
        programs: updatedPrograms,
        isDeleteDialogVisible: false,
        selectedProgram: null,
      ));
      // Remove from local storage
      programDataSource.deleteProgram(state.selectedProgram!.id);
      // Refresh dashboard's local program list
      context.read<DashboardCubit>().loadLocalPrograms();
    }
  }

  void updateProgramSettings(LocalProgramModel program, {int? loops, int? playTime}) {
    emit(state.copyWith(selectedProgram: program));
  }

  Future<void> sendProgramToDevice(LocalProgramModel program) async {
    final isGif = program.gifBase64 != null && program.gifBase64!.isNotEmpty;
    if (isGif) {
      // Simulate progress for GIF upload
      for (double p = 0; p <= 1.0; p += 0.1) {
        emit(state.copyWith(uploadProgress: p));
        await Future.delayed(const Duration(milliseconds: 80));
      }
      await programDataSource.sendProgramToDevice(
        program,
        onProgress: null, // No real progress for GIF
      );
      emit(state.copyWith(uploadProgress: 1.0));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(uploadProgress: null));
    } else {
      await programDataSource.sendProgramToDevice(
        program,
        onProgress: (progress) {
          emit(state.copyWith(uploadProgress: progress));
        },
      );
      emit(state.copyWith(uploadProgress: 1.0));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(uploadProgress: null));
    }
  }

  Future<void> sendTlvToBle(Uint8List tlvBytes) async {
    final device = programDataSource.dashboardRepository.bleService.connectedDevice;
    if (device == null) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'No device connected. Cannot send TLV.',
      ));
      return;
    }
    try {
      await programDataSource.dashboardRepository.sendTlvToBle(
        device,
        tlvBytes,
        onProgress: (progress) {
          emit(state.copyWith(uploadProgress: progress));
        },
      );
      emit(state.copyWith(uploadProgress: 1.0));
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(uploadProgress: null));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to send TLV: $e',
        uploadProgress: null,
      ));
    }
  }

  Future<void> updateProgram(LocalProgramModel updated) async {
    await programDataSource.updateProgram(updated);
    fetchProgramsFromLocal(page: currentPage, pageSize: pageSize);
  }
} 