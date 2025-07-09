import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/extensions/responsive_ext.dart';
import 'package:hookaba/core/utils/app_colors.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/onboarding_app_bar.dart';

class OtpPage extends HookWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Controllers for each OTP digit
    final controllers = List.generate(6, (index) => useTextEditingController());
    final focusNodes = List.generate(6, (index) => useFocusNode());
    
    // Timer state
    final secondsRemaining = useState(60);
    final timer = useRef<Timer?>(null);
    
    // Terms acceptance state
    final termsAccepted = useState(false);

    // Start timer
    useEffect(() {
      timer.value = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (secondsRemaining.value > 0) {
          secondsRemaining.value--;
        } else {
          timer.cancel();
        }
      });

      return () {
        timer.value?.cancel();
      };
    }, []);

    // Handle OTP completion
    void onOtpComplete() {
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

      final otp = controllers.map((c) => c.text).join();
      if (otp.length == 6) {
        // Add any OTP validation logic here if needed
        context.go('/onboarding/bluetooth-permission');
      }
    }

    // Handle resend OTP
    void onResendOtp() {
      if (secondsRemaining.value == 0) {
        // Reset timer
        secondsRemaining.value = 60;
        // Add your resend OTP logic here
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OnboardingAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
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
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final boxWidth = context.getWidth(
                    ratioMobile: 0.12, // ~12% of screen width per box on mobile
                    ratioTablet: 0.08,
                    ratioDesktop: 0.06,
                  );
                  final boxMargin = context.isMobile ? 3.0 : 6.0;
                  return Flexible(
                    child: Container(
                      width: boxWidth,
                      height: 48,
                      margin: EdgeInsets.symmetric(horizontal: boxMargin),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: AppFonts.audiowideStyle(
                          fontSize: 22,
                          color: AppColors.text,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            // Move to next field
                            if (index < 5) {
                              focusNodes[index + 1].requestFocus();
                            } else {
                              focusNodes[index].unfocus();
                              onOtpComplete();
                            }
                          } else if (value.isEmpty && index > 0) {
                            // Move to previous field on backspace
                            focusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    ),
                  );
                }),
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
                            color: termsAccepted.value ? AppColors.primary : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: termsAccepted.value ? AppColors.primary : Colors.transparent,
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
              const Spacer(),
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
                            final url = Uri.parse('https://hookaba.com/pages/terms-of-service');
                            await launchUrl(url);
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
                            final url = Uri.parse('https://hookaba.com/pages/privacy-policy');
                            await launchUrl(url);
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
    );
  }
} 