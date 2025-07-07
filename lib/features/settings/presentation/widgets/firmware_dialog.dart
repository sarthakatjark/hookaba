import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

class FirmwareDialog extends StatelessWidget {
  const FirmwareDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF081122),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIRMWARE',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 24),
                _InfoRow(
                  label: 'Current Version',
                  value: state.currentVersion,
                ),
                _InfoRow(
                  label: 'Latest Version',
                  value: state.currentVersion,
                ),
                const SizedBox(height: 24),
                const Text(
                  'To ensure a successful upgrade please:',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Please close the software and do not power off the device',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<SettingsCubit>().updateFirmware();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Update Immediately'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
} 