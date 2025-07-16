import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
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

  void deleteProgram() {
    if (state.selectedProgram != null) {
      final updatedPrograms = List<LocalProgramModel>.from(state.programs)
        ..removeWhere((program) => program.id == state.selectedProgram!.id);
      emit(state.copyWith(
        programs: updatedPrograms,
        isDeleteDialogVisible: false,
        selectedProgram: null,
      ));
    }
  }

  void updateProgramSettings(LocalProgramModel program, {int? loops, int? playTime}) {
    emit(state.copyWith(selectedProgram: program));
  }

  Future<void> sendProgramToDevice(LocalProgramModel program) async {
    await programDataSource.sendProgramToDevice(program);
  }
} 