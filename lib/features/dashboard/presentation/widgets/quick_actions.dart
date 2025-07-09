import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_snackbar.dart';
import 'package:hookaba/core/utils/enum.dart' show DashboardStatus;
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hookaba/features/dashboard/presentation/widgets/action_card.dart';
import 'package:hookaba/features/dashboard/presentation/widgets/show_upload_modal.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (dashboardContext, state) {
        final cubit = dashboardContext.read<DashboardCubit>();
        final canUpload = cubit.isDeviceConnected;
        //final connectedDevice = cubit.connectedDevice;

        // Show device response if available
        if (state.deviceResponse != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showPrimarySnackbar(
              context,
              'Device response: ${state.deviceResponse}',
              //backgroundColor: Colors.blue,
            );
          });
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AspectRatio(
                        aspectRatio: 1.5,
                        child: ActionCard(
                          title: "Upload",
                          color: Colors.deepPurple,
                          onTap: canUpload
                              ? () async {
                                  final device = cubit.connectedDevice;
                                  if (device == null) {
                                    showPrimarySnackbar(
                                      context,
                                      'Device is not connected. Please reconnect.',
                                      //backgroundColor: Colors.red,
                                    );
                                    return;
                                  }
                                  showUploadModal(
                                      dashboardContext, device, cubit);
                                }
                              : null,
                          isLoading: state.status == DashboardStatus.loading,
                          isDisabled: !canUpload,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ActionCard(
                          title: "Draw",
                          color: Colors.teal,
                          onTap: () => context.push('/dashboard/draw'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ActionCard(
                          title: "Library",
                          color: Colors.indigo,
                          onTap: () => context.push('/dashboard/library'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: AspectRatio(
                        aspectRatio: 1.5,
                        child: ActionCard(
                          title: "Text",
                          color: Colors.cyan,
                          onTap: () => context.push('/dashboard/text'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
