import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/injection_container/injection_container.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hookaba/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:hookaba/features/dashboard/presentation/pages/draw_screen.dart';
import 'package:hookaba/features/dashboard/presentation/pages/library_screen.dart';
import 'package:hookaba/features/dashboard/presentation/pages/text_editor_screen.dart';
import 'package:hookaba/features/onboarding/presentation/pages/bluetooth_permission_page.dart';
import 'package:hookaba/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:hookaba/features/onboarding/presentation/pages/otp_page.dart';
import 'package:hookaba/features/onboarding/presentation/pages/searching_device_page.dart'
    show SearchingDevicePage;
import 'package:hookaba/features/onboarding/presentation/pages/sign_up_page.dart';
import 'package:hookaba/features/program_list/presentation/pages/program_list_page.dart';
import 'package:hookaba/features/split_screen/presentation/cubit/split_screen_cubit.dart';
import 'package:hookaba/features/split_screen/presentation/pages/split_screen_preview_page.dart';
import 'package:hookaba/features/split_screen/presentation/pages/split_screen_template_page.dart';
import 'package:hookaba/features/split_screen/presentation/widgets/split_screen_clear_all_dialog.dart';
import 'package:hookaba/features/split_screen/presentation/widgets/split_screen_text_modal.dart';
import 'package:injectable/injectable.dart';

@singleton
class AppRouter {
  final router = GoRouter(
    initialLocation: '/onboarding/welcome',
    routes: [
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) => OnboardingPage(
          onGetStarted: () {},
        ),
      ),
      GoRoute(
        path: '/onboarding/signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/onboarding/otp',
        builder: (context, state) => const OtpPage(),
      ),
      GoRoute(
        path: '/onboarding/searchingdevicepage',
        builder: (context, state) => const SearchingDevicePage(),
      ),
      GoRoute(
        path: '/onboarding/bluetooth-permission',
        builder: (context, state) => const BluetoothPermissionPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => DashboardPage(),
      ),
      GoRoute(
        path: '/dashboard/text',
        builder: (context, state) => BlocProvider.value(
          value: sl<DashboardCubit>(),
          child: const TextEditorScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard/draw',
        builder: (context, state) => BlocProvider.value(
          value: sl<DashboardCubit>(),
          child: const DrawScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard/library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/dashboard/split-screen',
        builder: (context, state) => const SplitScreenPage(),
      ),
      GoRoute(
        path: '/dashboard/split-screen/preview',
        builder: (context, state) {
          final templateIndex =
              int.tryParse(state.uri.queryParameters['templateIndex'] ?? '0') ??
                  0;
          final ratio =
              double.tryParse(state.uri.queryParameters['ratio'] ?? '0.5') ??
                  0.5;
          return BlocProvider.value(
            value: sl<DashboardCubit>(),
            child: BlocProvider<SplitScreenCubit>(
              create: (_) => SplitScreenCubit(splitScreenRepository: sl()),
              child: SplitScreenPreviewPage(
                templateIndex: templateIndex,
                initialRatio: ratio,
                onUpload: () {},
                onText: () {},
                onClear: () {},
              ),
            ),
          );
        },
      ),
      
      GoRoute(
        path: '/dashboard/split-screen/text',
        builder: (context, state) => SplitScreenTextModal(
          textController: TextEditingController(),
          onApply: () {},
          onFormat: (style) {},
        ),
      ),
      GoRoute(
        path: '/dashboard/split-screen/clear-all',
        builder: (context, state) => SplitScreenClearAllDialog(
          onConfirm: () {},
          onCancel: () {},
        ),
      ),
      GoRoute(
        path: '/dashboard/programs',
        builder: (context, state) => BlocProvider.value(
          value: sl<DashboardCubit>(),
          child: const ProgramListPage(),
        ),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Dashboard - Coming Soon'),
          ),
        ),
      ),
    ],
  );
}
