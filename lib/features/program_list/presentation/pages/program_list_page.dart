import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';

import '../cubit/program_list_cubit.dart';
import '../cubit/program_list_state.dart';
import '../widgets/delete_dialog.dart';
import '../widgets/program_details.dart';
import '../widgets/program_item.dart';

class ProgramListPage extends HookWidget {
  const ProgramListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProgramListCubit(context.read<DashboardCubit>())..fetchProgramsFromDevice(),
      child: Scaffold(
        backgroundColor: const Color(0xFF081122),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'PROGRAM LIST',
            style: AppFonts.dashHorizonStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        body: BlocBuilder<ProgramListCubit, ProgramListState>(
          builder: (context, state) {
            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildRadioButton(
                            context: context,
                            label: 'Loop',
                            isSelected: state.selectedMode == ProgramMode.loop,
                            onTap: () {
                              if (state.selectedMode != ProgramMode.loop) {
                                context.read<ProgramListCubit>().toggleMode();
                              }
                            },
                          ),
                          const SizedBox(width: 32),
                          _buildRadioButton(
                            context: context,
                            label: 'Single',
                            isSelected: state.selectedMode == ProgramMode.single,
                            onTap: () {
                              if (state.selectedMode != ProgramMode.single) {
                                context.read<ProgramListCubit>().toggleMode();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.programs.length,
                        itemBuilder: (context, index) {
                          final program = state.programs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ProgramItem(
                              program: program,
                              onTap: () => context
                                  .read<ProgramListCubit>()
                                  .selectProgram(program),
                              onDelete: () => context
                                  .read<ProgramListCubit>()
                                  .showDeleteDialog(program),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (state.selectedProgram != null && !state.isDeleteDialogVisible)
                  ProgramDetails(
                    program: state.selectedProgram!,
                    onClose: () => context
                        .read<ProgramListCubit>()
                        .selectProgram(state.selectedProgram!),
                    onUpdateSettings: (loops, playTime) => context
                        .read<ProgramListCubit>()
                        .updateProgramSettings(
                          state.selectedProgram!,
                          loops: loops,
                          playTime: playTime,
                        ),
                  ),
                if (state.isDeleteDialogVisible)
                  DeleteDialog(
                    onConfirm: () =>
                        context.read<ProgramListCubit>().deleteProgram(),
                    onCancel: () =>
                        context.read<ProgramListCubit>().hideDeleteDialog(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRadioButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue,
                width: 2,
              ),
              color: isSelected ? Colors.blue : Colors.transparent,
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppFonts.audiowideStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 