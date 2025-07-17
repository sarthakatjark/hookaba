import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/extensions/responsive_ext.dart';
import 'package:hookaba/core/utils/app_colors.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

import '../cubit/sign_up_cubit.dart';
import '../widgets/onboarding_app_bar.dart';

class BluetoothPermissionPage extends StatelessWidget {
  const BluetoothPermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    print(
        'SignUpCubit instance in BluetoothPermissionPage: ${context.read<SignUpCubit>()}'); // DEBUG LOG
    return BlocListener<SignUpCubit, SignUpState>(
      listenWhen: (previous, current) =>
          previous.bluetoothStatus != current.bluetoothStatus,
      listener: (context, state) {
        print(
            'Bluetooth status changed: ${state.bluetoothStatus}'); // DEBUG LOG
        if (state.bluetoothStatus == BluetoothPermissionStatus.granted) {
          context.go('/onboarding/searchingdevicepage');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: OnboardingAppBar(
          onBack: () => context.go('/onboarding/signup'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Bluetooth\nPermission',
                    style: AppFonts.dashHorizonStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.height * 0.03),
                  SvgPicture.asset(
                    'assets/images/bluetooth-square.svg',
                    width: context.width * 0.6,
                    height: context.height * 0.2,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF00E1FF),
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(height: context.height * 0.03),
                  Text(
                    'ENABLE BLUETOOTH SO HOOKABA\nCAN PAIR WITH YOUR BACKPACK.',
                    style: AppFonts.audiowideStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.height * 0.02),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TO CONNECT YOUR HOOKABA:',
                        style: AppFonts.audiowideStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: context.height * 0.01),
                      Text(
                        '1. TURN ON YOUR BACKPACK',
                        style: AppFonts.audiowideStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: context.height * 0.008),
                      Text(
                        '2. PRESS AND HOLD THE BUTTON FOR 3 SECONDS',
                        style: AppFonts.audiowideStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: context.height * 0.008),
                      Text(
                        '3. WAIT FOR A LIGHT',
                        style: AppFonts.audiowideStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    onPressed: () => context
                        .read<SignUpCubit>()
                        .requestBluetoothPermission(context,
                            navigateDirectly: false),
                    text: 'Allow',
                  ),
                  SizedBox(height: context.height * 0.02),
                  PrimaryButton(
                    onPressed: () {
                      context.read<SignUpCubit>().skipBluetoothPermission();
                      context.go('/dashboard');
                    },
                    text: 'Don\'t Allow',
                    color: const Color(0xFF787880).withValues(alpha: 0.2),
                  ),
                  SizedBox(height: context.height * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
