import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/common_widgets/primary_snackbar.dart';
import 'package:hookaba/core/injection_container/injection_container.dart';
import 'package:hookaba/core/utils/app_colors.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hookaba/features/onboarding/presentation/cubit/sign_up_cubit.dart';

import '../widgets/onboarding_app_bar.dart' show OnboardingAppBar;

class SearchingDevicePage extends StatelessWidget {
  const SearchingDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignUpCubit>(
      create: (_) => sl<SignUpCubit>()
        ..loadPairedDevices()
        ..startScanWithPrefix(),
      child: BlocListener<SignUpCubit, SignUpState>(
        listenWhen: (previous, current) {
          // Listen for a device being connected
          final prevConnected = previous.pairedDevices.any(
              (device) => previous.connectedDevices[device['name']] == true);
          final currConnected = current.pairedDevices.any(
              (device) => current.connectedDevices[device['name']] == true);
          return !prevConnected && currConnected;
        },
        listener: (context, state) {
          // Find the first connected device
          final connectedDevice = state.pairedDevices.firstWhere(
            (device) => state.connectedDevices[device['name']] == true,
            orElse: () => {'name': '', 'id': ''},
          );
          if (connectedDevice['name']!.isNotEmpty) {
            // Refresh dashboard connection state
            sl<DashboardCubit>().refreshConnection();
            context.go('/dashboard', extra: {
              'deviceName': connectedDevice['name'],
              'deviceId': connectedDevice['id'],
            });
          }
        },
        child: BlocBuilder<SignUpCubit, SignUpState>(
          builder: (context, SignUpState state) {
            // if (state.bluetoothStatus != BluetoothPermissionStatus.denied) {
            //   return const BluetoothPermissionPage();
            // }
            return Scaffold(
              appBar: OnboardingAppBar(
                onBack: () => context.go('/onboarding/signup'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Refresh',
                    onPressed: () {
                      context.read<SignUpCubit>().startScanWithPrefix();
                      showPrimarySnackbar(context, 'Scanning for devices...');
                    },
                  ),
                ],
              ),
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: (() {
                    // Prepare set of paired device names to filter out from OTHER DEVICES
                    final pairedDeviceNames =
                        state.pairedDevices.map((d) => d['name']).toSet();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Searching Device',
                            style: AppFonts.dashHorizonStyle(
                              fontSize: 28,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (state.pairedDevices.isNotEmpty) ...[
                                  Text('MY DEVICES',
                                      style: AppFonts.audiowideStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary)),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.inputFill,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: state.pairedDevices
                                          .map((device) => device['name'])
                                          .toSet()
                                          .length,
                                      itemBuilder: (context, idx) {
                                        final uniqueDevices = state
                                            .pairedDevices
                                            .map((device) => device['name'])
                                            .toSet()
                                            .toList();
                                        final deviceName = uniqueDevices[idx];
                                        final device =
                                            state.pairedDevices.firstWhere(
                                          (d) => d['name'] == deviceName,
                                        );

                                        return ListTile(
                                          title: Text(
                                            device['name']!,
                                            style: AppFonts.audiowideStyle(
                                                color: AppColors.text),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                state.connectedDevices[
                                                            device['name']] ==
                                                        true
                                                    ? 'Connected'
                                                    : state.connecting &&
                                                            state.connectingDeviceId ==
                                                                device['id']
                                                        ? 'Connecting...'
                                                        : 'Not connected',
                                                style: AppFonts.audiowideStyle(
                                                  fontSize: 12,
                                                  color: state.connectedDevices[
                                                              device['name']] ==
                                                          true
                                                      ? Colors.green
                                                      : state.connecting &&
                                                              state.connectingDeviceId ==
                                                                  device['id']
                                                          ? Colors.orange
                                                          : AppColors
                                                              .textSecondary,
                                                ),
                                              ),
                                              if (state.connecting &&
                                                  state.connectingDeviceId ==
                                                      device['id'])
                                                const SizedBox(
                                                  width: 48,
                                                  height: 48,
                                                  child: Center(
                                                    child: SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: Colors.orange,
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              else
                                                IconButton(
                                                  icon: Icon(
                                                    state.connectedDevices[
                                                                device[
                                                                    'name']] ==
                                                            true
                                                        ? Icons
                                                            .bluetooth_connected
                                                        : Icons.bluetooth,
                                                    color: state.connectedDevices[
                                                                device[
                                                                    'name']] ==
                                                            true
                                                        ? Colors.green
                                                        : AppColors
                                                            .textSecondary,
                                                  ),
                                                  onPressed: state.connecting
                                                      ? null
                                                      : () async {
                                                          try {
                                                            final bleDevice = state
                                                                .scannedDevices
                                                                .firstWhere(
                                                              (d) =>
                                                                  d.platformName ==
                                                                  device[
                                                                      'name'],
                                                            );
                                                            context
                                                                .read<
                                                                    SignUpCubit>()
                                                                .connectToDevice(
                                                                    bleDevice);
                                                          } catch (e) {
                                                            // Show snackbar if device is not found
                                                            showPrimarySnackbar(
                                                              context,
                                                              'Device not found. Please turn on device',
                                                              colorTint:
                                                                  Colors.red,
                                                              icon: Icons
                                                                  .bluetooth,
                                                            );
                                                          }
                                                        },
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Text('OTHER DEVICES',
                                    style: AppFonts.audiowideStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.inputFill,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: state.scannedDevices
                                        .where((device) =>
                                            device.platformName.isNotEmpty &&
                                            !pairedDeviceNames
                                                .contains(device.platformName))
                                        .length,
                                    itemBuilder: (context, idx) {
                                      final filteredDevices = state
                                          .scannedDevices
                                          .where((device) =>
                                              device.platformName.isNotEmpty &&
                                              !pairedDeviceNames.contains(
                                                  device.platformName))
                                          .toList();
                                      final device = filteredDevices[idx];
                                      final deviceName = device
                                              .platformName.isNotEmpty
                                          ? device.platformName
                                          : 'Unknown Device ( ${device.remoteId})';
                                      return ListTile(
                                        title: Text(deviceName,
                                            style: AppFonts.audiowideStyle(
                                                color: AppColors.text)),
                                        trailing: state.connecting &&
                                                state.connectingDeviceId ==
                                                    device.remoteId.str
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.orange,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : null,
                                        onTap: state.connecting
                                            ? null
                                            : () => context
                                                .read<SignUpCubit>()
                                                .connectToDevice(device),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: 'Cancel',
                          color: AppColors.inputFill,
                          onPressed: () =>
                              context.go('/onboarding/bluetooth-permission'),
                        ),
                      ],
                    );
                  })(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
