import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/utils/app_colors.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

import '../cubit/sign_up_cubit.dart';
import '../widgets/onboarding_app_bar.dart';

class SignUpPage extends HookWidget {
  const SignUpPage({super.key});

  // Validation functions
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Remove any non-digit characters for validation
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 11) {
      return 'Phone number must be 10-11 digits';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final phoneController = useTextEditingController();
    final cubit = context.read<SignUpCubit>();
    final state = context.watch<SignUpCubit>().state;

    // Validation state
    final showValidation = useState(false);
    final nameError = useState<String?>(null);
    final phoneError = useState<String?>(null);
    final isFormValid = useState(false);

    // Validate form
    void validateForm() {
      nameError.value = validateName(nameController.text);
      phoneError.value = validatePhone(phoneController.text);
      isFormValid.value = nameError.value == null && phoneError.value == null;
    }

    useEffect(() {
      nameController.text = state.name;
      phoneController.text = state.phone;
      validateForm(); // Initial validation
      return null;
    }, []);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OnboardingAppBar(showBackButton: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image.asset(
              //   'assets/images/hookaba_logo.png',
              //   height: 120,
              //   fit: BoxFit.contain,
              // ),
              const SizedBox(height: 32),
              Text(
                'Sign Up',
                style: AppFonts.dashHorizonStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: nameController,
                onChanged: (value) {
                  cubit.nameChanged(value);
                  if (showValidation.value) validateForm();
                },
                textCapitalization: TextCapitalization.words,
                style: AppFonts.orbitron(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.text,
                ),
                decoration: InputDecoration(
                  hintText: 'Name',
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                  ),
                  hintStyle: AppFonts.orbitron(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                  suffixIcon: nameError.value == null && nameController.text.isNotEmpty
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
              ),
              if (showValidation.value && nameError.value != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        nameError.value!,
                        style: AppFonts.orbitron(
                          fontSize: 12,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                onChanged: (value) {
                  cubit.phoneChanged(value);
                  if (showValidation.value) validateForm();
                },
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                style: AppFonts.orbitron(
                  fontSize: 16,
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                  ),
                  hintStyle: AppFonts.orbitron(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                  suffixIcon: phoneError.value == null && phoneController.text.isNotEmpty
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  prefixText: '+91 ',
                  prefixStyle: AppFonts.orbitron(
                    fontSize: 16,
                    color: AppColors.text,
                  ),
                ),
              ),
              if (showValidation.value && phoneError.value != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        phoneError.value!,
                        style: AppFonts.orbitron(
                          fontSize: 12,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: state.loading
                      ? () {}
                      : () {
                          showValidation.value = true;
                          validateForm();
                          if (isFormValid.value) {
                            cubit.submit();
                            context.go('/onboarding/otp');
                          }
                        },
                  loading: state.loading,
                  text: 'Send OTP',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 