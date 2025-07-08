import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/common_widgets/primary_text_field.dart';
import 'package:hookaba/core/utils/app_colors.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

import '../cubit/sign_up_cubit.dart';
import '../widgets/onboarding_app_bar.dart';

class SignUpPage extends HookWidget {
  const SignUpPage({super.key});

  // Validation functions
  

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final phoneController = useTextEditingController();
    final phoneFocusNode = useFocusNode();
    final phoneFocused = useState(false);
    final cubit = context.read<SignUpCubit>();
    final state = context.watch<SignUpCubit>().state;

    // Validation state
    final showValidation = useState(false);
    final nameError = useState<String?>(null);
    final phoneError = useState<String?>(null);
    final isFormValid = useState(false);

    // Validate form
    void validateForm() {
      nameError.value = SignUpCubit.validateName(nameController.text);
      phoneError.value = SignUpCubit.validatePhone(phoneController.text);
      isFormValid.value = nameError.value == null && phoneError.value == null;
    }

    useEffect(() {
      nameController.text = state.name;
      phoneController.text = state.phone;
      validateForm(); // Initial validation
      void focusListener() {
        phoneFocused.value = phoneFocusNode.hasFocus;
      }
      phoneFocusNode.addListener(focusListener);
      return () {
        phoneFocusNode.removeListener(focusListener);
      };
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
              PrimaryTextField(
                controller: nameController,
                onChanged: (value) {
                  cubit.nameChanged(value);
                  if (showValidation.value) validateForm();
                },
                hintText: 'Name',
                //errorText: showValidation.value ? nameError.value : null,
                suffixIcon: nameError.value == null && nameController.text.isNotEmpty
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                textCapitalization: TextCapitalization.words,
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
                        style: AppFonts.audiowideStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              PrimaryTextField(
                controller: phoneController,
                focusNode: phoneFocusNode,
                onChanged: (value) {
                  cubit.phoneChanged(value);
                  if (showValidation.value) validateForm();
                },
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                hintText: 'Phone Number',
                //errorText: showValidation.value ? phoneError.value : null,
                suffixIcon: phoneError.value == null && phoneController.text.isNotEmpty
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                prefixText: phoneFocused.value ? '+91 ' : null,
                prefixStyle: AppFonts.audiowideStyle(
                  fontSize: 16,
                  color: AppColors.text,
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
                        style: AppFonts.audiowideStyle(
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