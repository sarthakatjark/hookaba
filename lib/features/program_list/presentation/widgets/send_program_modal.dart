import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/common_widgets/primary_snackbar.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/features/program_list/data/models/local_program_model.dart';
import 'package:hookaba/features/program_list/presentation/cubit/program_list_cubit.dart';

class SendProgramModal extends HookWidget {
  final LocalProgramModel program;
  const SendProgramModal({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    final loading = useState(false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            program.name,
            style: AppFonts.dashHorizonStyle(
              fontSize: 22,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          if (program.bmpBytes.isNotEmpty)
            Image.memory(
              program.bmpBytes,
              height: 80,
              fit: BoxFit.contain,
            ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Send to Device',
            loading: loading.value,
            onPressed: loading.value
                ? null
                : () async {
                    loading.value = true;
                    Navigator.of(context).pop();
                    try {
                      await context.read<ProgramListCubit>().sendProgramToDevice(program);
                      if (!context.mounted) return;
                      showPrimarySnackbar(context, 'Program sent to device!');
                    } catch (e) {
                      if (!context.mounted) return;
                      showPrimarySnackbar(context, 'Failed to send: $e', colorTint: Colors.red, icon: Icons.error);
                    } finally {
                      loading.value = false;
                    }
                  },
          ),
        ],
      ),
    );
  }
} 