import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_snackbar.dart';
import 'package:hookaba/core/network/network_dio.dart';
import 'package:hookaba/core/utils/api_constants.dart';
import 'package:hookaba/core/utils/app_colors.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text('PROFILE', style: AppFonts.dashHorizonStyle(fontSize: 22, color: Colors.white)),
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
                    child: Text('Error: ${state.error}', style: AppFonts.audiowideStyle(color: Colors.redAccent)),
                  );
                } else if (state.profile != null) {
                  return Center(child: _ProfileCard(profile: state.profile!));
                } else {
                  return const Center(child: Text('No profile data', style: TextStyle(color: Colors.white)));
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ProfileEntity profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final username = profile.username;
    final number = profile.number;
    final email = profile.email ?? '';
    final createdOn = profile.createdOn;
    final userId = profile.id;
    // Placeholder image, replace with actual image if available
    const profileImage = AssetImage('assets/images/hookaba_logo.png');
    // For the switch (open to offers)
    final isOpenToOffers = useState(true);

    return Card(
      color: AppColors.inputFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                const CircleAvatar(
                  radius: 54,
                  backgroundImage: profileImage,
                  backgroundColor: AppColors.background,
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              username,
              textAlign: TextAlign.center,
              style: AppFonts.dashHorizonStyle(fontSize: 28, color: Colors.white),
            ),
            const SizedBox(height: 8),
            // Visit Store Button
            SizedBox(
              width: 180,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                icon: const Icon(Icons.storefront, color: Colors.white),
                label: Text('Visit Store', style: AppFonts.audiowideStyle(color: Colors.white)),
                onPressed: () async {
                  // Open the store URL
                  final url = Uri.parse('https://hookaba.com/');
                  // ignore: deprecated_member_use
                  await launchUrl(url, mode: LaunchMode.platformDefault);
                },
              ),
            ),
            const SizedBox(height: 18),
            // Email
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 6),
                Text(email, style: AppFonts.audiowideStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            // Phone
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 6),
                Text(number, style: AppFonts.audiowideStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            // Joined date
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Joined: ${createdOn.day}/${createdOn.month}/${createdOn.year}',
                  style: AppFonts.audiowideStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // User ID
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fingerprint, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 6),
                Text('ID: $userId', style: AppFonts.audiowideStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 18),
            // Open to offers switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Are you open to offers?', style: AppFonts.audiowideStyle(color: Colors.white)),
                    Text('Your profile is publicly visible', style: AppFonts.audiowideStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    Text('Yes', style: AppFonts.audiowideStyle(color: isOpenToOffers.value ? AppColors.accent : AppColors.textSecondary)),
                    Switch(
                      value: isOpenToOffers.value,
                      onChanged: (val) => isOpenToOffers.value = val,
                      activeColor: AppColors.accent,
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