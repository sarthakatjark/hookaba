import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_snackbar.dart';
import 'package:hookaba/core/extensions/responsive_ext.dart';
import 'package:hookaba/core/network/network_dio.dart';
import 'package:hookaba/core/utils/api_constants.dart';
import 'package:hookaba/core/utils/app_colors.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:url_launcher/url_launcher.dart' show LaunchMode, launchUrl;

import '../../data/datasources/profile_repository_impl.dart';
import '../../domain/entities/profile_entity.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class ProfilePage extends HookWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(
        repository: ProfileRepositoryImpl(
          dioClient: DioClient(ApiEndpoints.baseUrl),
          secureStorage: const FlutterSecureStorage(),
        ),
      ),
      child: Builder(
        builder: (context) {
          final cubit = context.read<ProfileCubit>();
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text('PROFILE',
                  style: AppFonts.dashHorizonStyle(
                      fontSize: 22, color: Colors.white)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    await cubit.logout();
                    if (!context.mounted) return;
                    showPrimarySnackbar(
                      context,
                      'Logged out successfully',
                      colorTint: Colors.green,
                      icon: Icons.logout,
                    );
                    await Future.delayed(const Duration(milliseconds: 1200));
                    if (!context.mounted) return;
                    context.go('/onboarding/welcome');
                  },
                ),
              ],
            ),
            body: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state.error != null) {
                  return Center(
                    child: Text('Error: ${state.error}',
                        style:
                            AppFonts.audiowideStyle(color: Colors.redAccent)),
                  );
                } else if (state.profile != null) {
                  return Center(child: _ProfileCard(profile: state.profile!));
                } else {
                  return const Center(
                      child: Text('No profile data',
                          style: TextStyle(color: Colors.white)));
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends HookWidget {
  final ProfileEntity profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final username = profile.username;
    final number = profile.number;

    final createdOn = profile.createdOn;

    // Placeholder image, replace with actual image if available
    final profileImage = Image.asset(
      'assets/images/welcome_screen_bag.png',
      height: context.getWidth(ratioMobile: 0.3, ratioTablet: 0.2, ratioDesktop: 0.15),
      width: context.getWidth(ratioMobile: 0.3, ratioTablet: 0.2, ratioDesktop: 0.15),
    );
    final isOpenToOffers = useState(true);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.getWidth(ratioMobile: 0.05, ratioTablet: 0.15, ratioDesktop: 0.2),
        vertical: context.getHeight(ratioMobile: 0.03, ratioTablet: 0.04, ratioDesktop: 0.05),
      ),
      child: Container(
        padding: EdgeInsets.all(context.getWidth(ratioMobile: 0.05, ratioTablet: 0.04, ratioDesktop: 0.03)),
        child: Column(
          children: [
             profileImage,
            SizedBox(height: context.getHeight(ratioMobile: 0.02, ratioTablet: 0.03, ratioDesktop: 0.04)),
            Text(
              username,
              textAlign: TextAlign.center,
              style:
                  AppFonts.dashHorizonStyle(fontSize: 28, color: Colors.white),
            ),
            SizedBox(height: context.getHeight(ratioMobile: 0.04, ratioTablet: 0.05, ratioDesktop: 0.06)),
            // Visit Store Button
            SizedBox(
              width: context.getWidth(ratioMobile: 0.5, ratioTablet: 0.3, ratioDesktop: 0.2),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                icon: const Icon(Icons.storefront, color: Colors.white),
                label: Text('Visit Store',
                    style: AppFonts.audiowideStyle(color: Colors.white)),
                onPressed: () async {
                  // Open the store URL
                  final url = Uri.parse('https://hookaba.com/');
                  // ignore: deprecated_member_use
                  await launchUrl(url, mode: LaunchMode.platformDefault);
                },
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(height: context.getHeight(ratioMobile: 0.04, ratioTablet: 0.06, ratioDesktop: 0.08)),
                // Email

                // Phone
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.phone,
                        color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 6),
                    Text(number,
                        style: AppFonts.audiowideStyle(
                            color: AppColors.textSecondary)),
                  ],
                ),
                SizedBox(height: context.getHeight(ratioMobile: 0.01, ratioTablet: 0.015, ratioDesktop: 0.02)),
                // Joined date
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Joined: ${createdOn.day}/${createdOn.month}/${createdOn.year}',
                      style: AppFonts.audiowideStyle(
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
                SizedBox(height: context.getHeight(ratioMobile: 0.01, ratioTablet: 0.015, ratioDesktop: 0.02)),
                // User ID

                SizedBox(height: context.getHeight(ratioMobile: 0.02, ratioTablet: 0.03, ratioDesktop: 0.04)),
                // Open to offers switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Are you open to offers?',
                            style: AppFonts.audiowideStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            'Your profile is publicly visible',
                            style: AppFonts.audiowideStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isOpenToOffers.value,
                      onChanged: (val) => isOpenToOffers.value = val,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
