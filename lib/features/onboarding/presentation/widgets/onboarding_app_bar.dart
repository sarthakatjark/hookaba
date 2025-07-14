import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OnboardingAppBar({
    super.key,
    this.showBackButton = true,
    this.actions,
    this.onBack,
  });

  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: onBack ?? () => context.pop(),
            )
          : null,
      centerTitle: true,
      title: Image.asset(
        'assets/images/hookaba_logo.png',
        height: 50,
        fit: BoxFit.cover,
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 