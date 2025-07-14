import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_snackbar.dart';
import 'package:hookaba/core/extensions/responsive_ext.dart';
import 'package:hookaba/core/utils/api_constants.dart';
import 'package:hookaba/core/utils/app_colors.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../cubit/sign_up_cubit.dart';
import '../widgets/onboarding_app_bar.dart';

class OtpPage extends HookWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Timer state
    final secondsRemaining = useState(20);
    final timer = useRef<Timer?>(null);

    // Terms acceptance state
    final termsAccepted = useState(true);

    // Cubit and state
    final cubit = BlocProvider.of<SignUpCubit>(context);
    final state = context.select((SignUpCubit c) => c.state);

    // Start timer and request OTP on mount
    useEffect(() {
      cubit.requestOtp(state.phone);
      timer.value = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (secondsRemaining.value > 0) {
          secondsRemaining.value--;
        } else {
          timer.cancel();
        }
      });
      SmsAutoFill().listenForCode();
      return () {
        timer.value?.cancel();
        SmsAutoFill().unregisterListener();
      };
    }, []);

    // Show error using snackbar if present
    useEffect(() {
      if (state.error != null && state.error!.isNotEmpty) {
        final lines = state.error!.split('\n');
        final shortError = lines.take(3).join('\n');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPrimarySnackbar(context, shortError, colorTint: Colors.redAccent);
        });
      }
      return null;
    }, [state.error]);

    // Handle OTP completion (now takes code as parameter)
    void onOtpComplete(String? otp) async {
      if (!termsAccepted.value) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.background,
            title: Text(
              'Terms & Conditions Required',
              style: AppFonts.dashHorizonStyle(
                fontSize: 20,
                color: AppColors.text,
              ),
            ),
            content: Text(
              'Please accept the Terms & Conditions to continue.',
              style: AppFonts.audiowideStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: AppFonts.audiowideStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
        return;
      }
      if (otp != null && otp.length == 6) {
        final result = await cubit.verifyOtp(state.phone, otp);
        print('OTP verify result: $result');
        // Only navigate if backend returns access_token and user is created
        if (context.mounted &&
            result != null &&
            result['access_token'] != null &&
            result['user_created'] == true) {
          context.go('/onboarding/bluetooth-permission');
        }
      }
    }

    // Handle resend OTP
    void onResendOtp() {
      if (secondsRemaining.value == 0) {
        secondsRemaining.value = 20;
        cubit.requestOtp(state.phone);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: OnboardingAppBar(
        onBack: () => context.go('/onboarding/welcome'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                    height: context.getHeight(
                        ratioMobile: 0.04,
                        ratioTablet: 0.03,
                        ratioDesktop: 0.02)),
                Text(
                  'Enter your code',
                  style: AppFonts.dashHorizonStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'We have sent a verification code to mobile number.Please enter your code down below',
                  style: AppFonts.audiowideStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                    height: context.getHeight(
                        ratioMobile: 0.04,
                        ratioTablet: 0.03,
                        ratioDesktop: 0.02)),
                PinFieldAutoFill(
                  codeLength: 6,
                  onCodeChanged: (code) {
                    onOtpComplete(code);
                  },
                  onCodeSubmitted: (code) {
                    onOtpComplete(code);
                  },
                  decoration: BoxLooseDecoration(
                    strokeColorBuilder:
                        const FixedColorBuilder(AppColors.primary),
                    textStyle: AppFonts.audiowideStyle(
                      fontSize: 22,
                      color: AppColors.text,
                    ),
                    radius: const Radius.circular(
                        10), // Adjust the value for your preferred border radius
                    gapSpace: 12, // Optional: space between boxes
                  ),
                ),
                const SizedBox(height: 24),
                // Terms and conditions checkbox
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () => termsAccepted.value = !termsAccepted.value,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: termsAccepted.value
                                  ? AppColors.primary
                                  : Colors.grey,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            color: termsAccepted.value
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          child: termsAccepted.value
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'By clicking this, you agree to our Terms & Conditions and Privacy Policy',
                            style: AppFonts.audiowideStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: secondsRemaining.value == 0 ? onResendOtp : null,
                  child: Text(
                    secondsRemaining.value > 0
                        ? 'Resend code in ${secondsRemaining.value}s'
                        : 'Resend code',
                    style: AppFonts.audiowideStyle(
                      color: secondsRemaining.value > 0
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(
                    height: context.getHeight(
                        ratioMobile: 0.04,
                        ratioTablet: 0.03,
                        ratioDesktop: 0.02)),
                // Terms and Privacy links at bottom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: AppFonts.audiowideStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              await SignUpCubit.openUrl(
                                  ApiEndpoints.termsOfServiceUrl);
                            },
                        ),
                        TextSpan(
                          text: ' • ',
                          style: AppFonts.audiowideStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: AppFonts.audiowideStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              await SignUpCubit.openUrl(
                                  ApiEndpoints.privacyPolicyUrl);
                            },
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
