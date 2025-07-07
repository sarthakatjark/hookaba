import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

class DashboardHeader extends HookWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isOn = useState(false);
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
              onChanged: (val) => isOn.value = val,
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