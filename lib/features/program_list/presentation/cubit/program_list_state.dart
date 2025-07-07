import 'package:equatable/equatable.dart';

enum ProgramMode { loop, single }

class Program {
  final String id;
  final String name;
  final String icon;
  final int loops;
  final int playTime;
  final ProgramMode mode;

  const Program({
    required this.id,
    required this.name,
    required this.icon,
    this.loops = 3,
    this.playTime = 10,
    this.mode = ProgramMode.loop,
  });

  Program copyWith({
    String? name,
    String? icon,
    int? loops,
    int? playTime,
    ProgramMode? mode,
  }) {
    return Program(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      loops: loops ?? this.loops,
      playTime: playTime ?? this.playTime,
      mode: mode ?? this.mode,
    );
  }
}

class ProgramListState extends Equatable {
  final List<Program> programs;
  final ProgramMode selectedMode;
  final Program? selectedProgram;
  final bool isDeleteDialogVisible;

  const ProgramListState({
    this.programs = const [
      Program(
        id: '1',
        name: 'Fire',
        icon: '🔥',
      ),
      Program(
        id: '2',
        name: 'Clock',
        icon: '⏰',
      ),
      Program(
        id: '3',
        name: 'Abstract',
        icon: '🎨',
      ),
      Program(
        id: '4',
        name: 'Smiley',
        icon: '😊',
      ),
      Program(
        id: '5',
        name: 'Rainbow',
        icon: '🌈',
      ),
      Program(
        id: '6',
        name: 'Sparkle',
        icon: '✨',
      ),
    ],
    this.selectedMode = ProgramMode.loop,
    this.selectedProgram,
    this.isDeleteDialogVisible = false,
  });

  ProgramListState copyWith({
    List<Program>? programs,
    ProgramMode? selectedMode,
    Program? selectedProgram,
    bool? isDeleteDialogVisible,
  }) {
    return ProgramListState(
      programs: programs ?? this.programs,
      selectedMode: selectedMode ?? this.selectedMode,
      selectedProgram: selectedProgram ?? this.selectedProgram,
      isDeleteDialogVisible: isDeleteDialogVisible ?? this.isDeleteDialogVisible,
    );
  }

  @override
  List<Object?> get props => [
        programs,
        selectedMode,
        selectedProgram,
        isDeleteDialogVisible,
      ];
} 