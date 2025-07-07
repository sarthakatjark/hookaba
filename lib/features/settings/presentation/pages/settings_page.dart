import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../widgets/clear_confirmation_dialog.dart';
import '../widgets/connection_dialog.dart';
import '../widgets/firmware_dialog.dart';
import '../widgets/settings_tile.dart';

class SettingsPage extends HookWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final showConnectionDialog = useState(false);

    return BlocProvider(
      create: (_) => SettingsCubit(),
      child: Scaffold(
        backgroundColor: const Color(0xFF081122),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'SETTINGS',
            style: AppFonts.dashHorizonStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SettingsTile(
                      title: 'Return',
                      trailing: Switch(
                        value: state.isReturnOn,
                        onChanged: (_) => context.read<SettingsCubit>().toggleReturn(),
                        activeColor: Colors.blue,
                      ),
                      titleStyle: AppFonts.audiowideStyle(color: Colors.white),
                    ),
                    SettingsTile(
                      title: 'Clear Screen',
                      onTap: () => context.read<SettingsCubit>().showClearConfirmation(),
                      titleStyle: AppFonts.audiowideStyle(color: Colors.white),
                    ),
                    SettingsTile(
                      title: 'Information',
                      onTap: () {},
                      titleStyle: AppFonts.audiowideStyle(color: Colors.white),
                    ),
                    SettingsTile(
                      title: 'Firmware',
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const FirmwareDialog(),
                      ),
                      titleStyle: AppFonts.audiowideStyle(color: Colors.white),
                    ),
                    SettingsTile(
                      title: 'App Update',
                      onTap: () {},
                      titleStyle: AppFonts.audiowideStyle(color: Colors.white),
                    ),
                    SettingsTile(
                      title: 'Privacy Agreement',
                      onTap: () {},
                      titleStyle: AppFonts.audiowideStyle(color: Colors.white),
                    ),
                    SettingsTile(
                      title: 'FAQ',
                      onTap: () {},
                      titleStyle: AppFonts.audiowideStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'CONNECTIONS',
                      style: AppFonts.audiowideStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Choose the correct connect mode according to your device.',
                      style: AppFonts.audiowideStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _ConnectionOption(
                            icon: Icons.bluetooth,
                            label: 'Bluetooth',
                            isSelected: state.selectedMode == ConnectionMode.bluetooth,
                            onTap: () => context
                                .read<SettingsCubit>()
                                .setConnectionMode(ConnectionMode.bluetooth),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ConnectionOption(
                            icon: Icons.wifi,
                            label: 'WiFi',
                            isSelected: state.selectedMode == ConnectionMode.wifi,
                            onTap: () => context
                                .read<SettingsCubit>()
                                .setConnectionMode(ConnectionMode.wifi),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => showConnectionDialog.value = false,
                          child: Text(
                            'Cancel',
                            style: AppFonts.audiowideStyle(color: Colors.grey[400]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => showConnectionDialog.value = true,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Proceed'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (state.showClearConfirmation)
                  const ClearConfirmationDialog(),
                if (showConnectionDialog.value)
                  ConnectionDialog(
                    onClose: () => showConnectionDialog.value = false,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConnectionOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConnectionOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppFonts.audiowideStyle(
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 