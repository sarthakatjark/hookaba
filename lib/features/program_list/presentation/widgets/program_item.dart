import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/features/program_list/data/models/local_program_model.dart';
import 'package:hookaba/features/program_list/presentation/cubit/program_list_cubit.dart';
import 'package:hookaba/features/program_list/presentation/widgets/edit_program_name_sheet.dart';

class ProgramItem extends StatelessWidget {
  final LocalProgramModel program;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProgramItem({
    super.key,
    required this.program,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A33),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: (program.gifBase64 != null && program.gifBase64!.isNotEmpty)
                        ? Image.memory(
                            base64Decode(program.gifBase64!),
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          )
                        : program.bmpBytes.isNotEmpty
                            ? Image.memory(
                                program.bmpBytes,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.apps, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    program.name,
                    style: AppFonts.dashHorizonStyle(
                      fontSize: 25,
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/images/edit.svg',
                    width: 22,
                    height: 22,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF081122),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      builder: (modalContext) => EditProgramNameSheet(
                        initialName: program.name,
                        onSave: (newName) async {
                          final updated = LocalProgramModel(
                            id: program.id,
                            name: newName,
                            bmpBytes: program.bmpBytes,
                            jsonCommand: program.jsonCommand,
                          );
                          await context.read<ProgramListCubit>().updateProgram(updated);
                        },
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/images/delete.svg',
                    width: 22,
                    height: 22,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 