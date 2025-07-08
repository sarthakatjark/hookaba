import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';

class BrightnessSlider extends HookWidget {
  const BrightnessSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final sliderValue = useState(0.5);
    final debounceTimer = useRef<Timer?>(null);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/brightness.svg',
            width: 25,
            height: 25,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                activeTrackColor: Colors.blue,
                inactiveTrackColor: const Color(0xFF1A2633),
                thumbColor: Colors.white,
                overlayColor: Colors.transparent,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                trackShape: const RoundedRectSliderTrackShape(),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: sliderValue.value,
                onChanged: (value) {
                  final cubit = context.read<DashboardCubit>();
                  sliderValue.value = value;
                  final brightness = (value * 15).round();
                  debounceTimer.value?.cancel();
                  debounceTimer.value = Timer(const Duration(milliseconds: 200), () async {
                    await cubit.sendBrightness(brightness);
                  });
                },
                min: 0.0,
                max: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
