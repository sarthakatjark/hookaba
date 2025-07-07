import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';

import 'program_list_state.dart';

class ProgramListCubit extends Cubit<ProgramListState> {
  final DashboardCubit dashboardCubit;
  StreamSubscription? _dashboardSub;

  ProgramListCubit(this.dashboardCubit) : super(const ProgramListState()) {
    _dashboardSub = dashboardCubit.stream.listen(_onDashboardStateChanged);
  }

  Future<void> fetchProgramsFromDevice() async {
    await dashboardCubit.getProgramGroup();
  }

  void _onDashboardStateChanged(DashboardState dashboardState) async {
    // Step 1: Get program IDs
    final idsPro = dashboardState.deviceResponse?['ack']?['pgm_play']?['ids_pro'];
    if (idsPro != null && idsPro is List) {
      await dashboardCubit.getProgramResourceIds(List<int>.from(idsPro));
    }
    // Step 2: Get program resource IDs
    final pgmKeyList = dashboardState.deviceResponse?['ack']?['pgm_key'];
    if (pgmKeyList != null && pgmKeyList is List) {
      // Map to your Program model if needed
      final programs = pgmKeyList.map<Program>((e) => Program(
        id: e['id_pro'].toString(),
        name: e['key'] ?? 'Unknown',
        icon: '📦', // Placeholder, you may want to map icons
      )).toList();
      emit(state.copyWith(programs: programs));
    }
  }

  @override
  Future<void> close() {
    _dashboardSub?.cancel();
    return super.close();
  }

  void toggleMode() {
    emit(state.copyWith(
      selectedMode: state.selectedMode == ProgramMode.loop
          ? ProgramMode.single
          : ProgramMode.loop,
    ));
  }

  void selectProgram(Program program) {
    emit(state.copyWith(selectedProgram: program));
  }

  void showDeleteDialog(Program program) {
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
      final updatedPrograms = List<Program>.from(state.programs)
        ..removeWhere((program) => program.id == state.selectedProgram!.id);
      
      emit(state.copyWith(
        programs: updatedPrograms,
        isDeleteDialogVisible: false,
        selectedProgram: null,
      ));
    }
  }

  void updateProgramSettings(Program program, {int? loops, int? playTime}) {
    final index = state.programs.indexWhere((p) => p.id == program.id);
    if (index != -1) {
      final updatedProgram = program.copyWith(
        loops: loops,
        playTime: playTime,
      );
      final updatedPrograms = List<Program>.from(state.programs)
        ..[index] = updatedProgram;
      
      emit(state.copyWith(
        programs: updatedPrograms,
        selectedProgram: updatedProgram,
      ));
    }
  }
} 