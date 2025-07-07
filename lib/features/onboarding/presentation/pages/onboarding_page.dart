import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/utils/app_colors.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

class OnboardingPage extends StatelessWidget {
  final VoidCallback onGetStarted;
  const OnboardingPage({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              'Welcome To Hookaba',
              style: AppFonts.dashHorizonStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Placeholder for backpack image
            SizedBox(
              width: 200,
              height: 200,
              
              child: Image.asset('assets/images/welcome_screen_bag.png'),
            ),
            const SizedBox(height: 24),
            Text(
              'CONTROL THE LED DISPLAY\nSCREEN ON YOUR BACKPACK.',
              style: AppFonts.audiowideStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: PrimaryButton(
                onPressed: () {
                  context.go('/onboarding/signup');
                },
                text: 'Get Started',
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
