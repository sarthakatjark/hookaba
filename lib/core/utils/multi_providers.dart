import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookaba/core/injection_container/injection_container.dart';
import 'package:hookaba/features/onboarding/presentation/cubit/sign_up_cubit.dart';
import 'package:hookaba/features/settings/presentation/cubit/settings_cubit.dart';

class AppMultiProviders extends StatelessWidget {
  final Widget child;
  const AppMultiProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SignUpCubit>(create: (_) => sl<SignUpCubit>()),
        BlocProvider<SettingsCubit>(create: (_) => SettingsCubit()),
        // Add more BlocProviders here as needed
      ],
      child: child,
    );
  }
} 