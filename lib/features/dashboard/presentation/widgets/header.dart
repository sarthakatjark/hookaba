import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';

class DashboardHeader extends HookWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isOn = useState(true);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "DASHBOARD",
          style: AppFonts.dashHorizonStyle(
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        Row(
          children: [
            Switch(
              value: isOn.value,
              onChanged: (val) async {
                final cubit = context.read<DashboardCubit>();
                if (!val && isOn.value) {
                  // Toggling from ON to OFF, send power off
                  await cubit.sendPowerSequence(power: 0, sno: 3);
                } else if (val && !isOn.value) {
                  // Toggling from OFF to ON, send power on
                  await cubit.sendPowerSequence(power: 1, sno: 2);
                }
                isOn.value = val;
              },
              activeColor: Colors.green,
            ),
            Text(
              isOn.value ? "Turn ON" : "Turn OFF",
              style: AppFonts.audiowideStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: isOn.value ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(
                Icons.bluetooth_connected,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 