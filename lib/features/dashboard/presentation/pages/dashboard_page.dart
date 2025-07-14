import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_bottom_nav_bar.dart';
import 'package:hookaba/core/injection_container/injection_container.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hookaba/features/dashboard/presentation/widgets/brightness_slider.dart';
import 'package:hookaba/features/dashboard/presentation/widgets/header.dart';
import 'package:hookaba/features/dashboard/presentation/widgets/program_list.dart';
import 'package:hookaba/features/dashboard/presentation/widgets/quick_actions.dart';
import 'package:hookaba/features/dashboard/presentation/widgets/split_screen_widget.dart';
import 'package:hookaba/features/onboarding/presentation/pages/searching_device_page.dart';
import 'package:hookaba/features/profile/presentation/pages/profile_page.dart';
import 'package:hookaba/features/settings/presentation/pages/settings_page.dart';

class DashboardPage extends HookWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = useState(0);
    final pageController = usePageController();
    final currentPage = useState(0);

    // List of bag images
    final bagImages = [
      'assets/images/welcome_screen_bag.png',
      'assets/images/bags/bag_one.png',
      'assets/images/bags/bag_two.png',
      'assets/images/bags/bag_three.png',
      'assets/images/bags/bag_four.png',
      'assets/images/bags/bag_five.png',
      'assets/images/bags/bag_six.png',
    ];

    // Auto-scroll timer
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (currentPage.value < bagImages.length - 1) {
          currentPage.value++;
        } else {
          currentPage.value = 0;
        }
        pageController.animateToPage(
          currentPage.value,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      });

      return () => timer.cancel();
    }, []);

    return BlocProvider.value(
      value: sl<DashboardCubit>(),
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (!state.isDeviceConnected) {
            return const SearchingDevicePage();
          }
          return Scaffold(
            backgroundColor: const Color(0xFF081122),
            body: selectedIndex.value == 1
                ? const SettingsPage()
                : selectedIndex.value == 2
                    ? const ProfilePage()
                    : SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BlocProvider.value(
                                value: sl<DashboardCubit>(),
                                child: const DashboardHeader(),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 180,
                                child: PageView.builder(
                                  controller: pageController,
                                  onPageChanged: (index) => currentPage.value = index,
                                  itemCount: bagImages.length,
                                  itemBuilder: (context, index) {
                                    return Center(
                                      child: Image.asset(
                                        bagImages[index],
                                        height: 180,
                                        fit: BoxFit.contain,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text("QUICK ACTIONS", style: _labelStyle()),
                              const SizedBox(height: 8),
                              const QuickActions(),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("PROGRAM LIST", style: _labelStyle()),
                                  GestureDetector(
                                    onTap: () => context.push('/dashboard/programs'),
                                    child: Text(
                                      "VIEW ALL",
                                      style: AppFonts.audiowideStyle(
                                        fontSize: 12,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const ProgramList(),
                              const SizedBox(height: 20),
                              Text("BRIGHTNESS", style: _labelStyle()),
                              const SizedBox(height: 8),
                              BlocProvider.value(
                                value: sl<DashboardCubit>(),
                                child: const BrightnessSlider(),
                              ),
                              const SizedBox(height: 20),
                              Text("SPLIT SCREEN FEATURE", style: _labelStyle()),
                              const SizedBox(height: 8),
                              const SplitScreen(),
                            ],
                          ),
                        ),
                      ),
            bottomNavigationBar: PrimaryBottomNavBar(
              currentIndex: selectedIndex.value,
              onTap: (index) => selectedIndex.value = index,
            ),
          );
        },
      ),
    );
  }

  TextStyle _labelStyle() {
    return AppFonts.dashHorizonStyle(
      fontSize: 15,
      color: Colors.white,
      //letterSpacing: 1,
    );
  }
}
