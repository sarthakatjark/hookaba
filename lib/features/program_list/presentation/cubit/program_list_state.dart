import 'package:equatable/equatable.dart';
import 'package:hookaba/core/utils/enum.dart' show DashboardStatus;
import 'package:hookaba/features/program_list/data/models/local_program_model.dart';

enum ProgramMode { loop, single }

class ProgramListState extends Equatable {
  final List<LocalProgramModel> programs;
  final ProgramMode selectedMode;
  final LocalProgramModel? selectedProgram;
  final bool isDeleteDialogVisible;
  final double? uploadProgress;
  final String? errorMessage;
  final DashboardStatus? status;

  const ProgramListState({
    this.programs = const [],
    this.selectedMode = ProgramMode.loop,
    this.selectedProgram,
    this.isDeleteDialogVisible = false,
    this.uploadProgress,
    this.errorMessage,
    this.status,
  });

  ProgramListState copyWith({
    List<LocalProgramModel>? programs,
    ProgramMode? selectedMode,
    LocalProgramModel? selectedProgram,
    bool? isDeleteDialogVisible,
    double? uploadProgress,
    String? errorMessage,
    DashboardStatus? status,
  }) {
    return ProgramListState(
      programs: programs ?? this.programs,
      selectedMode: selectedMode ?? this.selectedMode,
      selectedProgram: selectedProgram ?? this.selectedProgram,
      isDeleteDialogVisible: isDeleteDialogVisible ?? this.isDeleteDialogVisible,
      uploadProgress: uploadProgress,
      errorMessage: errorMessage,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        programs,
        selectedMode,
        selectedProgram,
        isDeleteDialogVisible,
        uploadProgress,
        errorMessage,
        status,
      ];
} 