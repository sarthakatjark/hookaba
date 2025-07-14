import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_snackbar.dart';
import 'package:hookaba/core/network/network_dio.dart';
import 'package:hookaba/core/utils/api_constants.dart';
import 'package:hookaba/core/utils/app_colors.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/datasources/profile_repository_impl.dart';
import '../cubit/profile_cubit.dart';

class ProfilePage extends HookWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cubit = useMemoized(() => ProfileCubit(
      repository: ProfileRepositoryImpl(
        dioClient: DioClient(ApiEndpoints.baseUrl),
        secureStorage: const FlutterSecureStorage(),
      ),
    ));
    //final cubitNotifier = useListenable(cubit);

    useEffect(() {
      cubit.fetchProfile();
      return null;
    }, []);

    return ChangeNotifierProvider<ProfileCubit>.value(
      value: cubit,
      child: Consumer<ProfileCubit>(
        builder: (context, cubit, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text('PROFILE', style: AppFonts.dashHorizonStyle(fontSize: 22, color: Colors.white)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    await cubit.logout();
                    if (context.mounted) {
                      showPrimarySnackbar(
                        context,
                        'Logged out successfully',
                        colorTint: Colors.green,
                        icon: Icons.logout,
                      );
                      await Future.delayed(const Duration(milliseconds: 1200));
                      context.go('/onboarding/welcome');
                    }
                  },
                ),
              ],
            ),
            body: Center(
              child: cubit.isLoading
                  ? const CircularProgressIndicator()
                  : cubit.error != null
                      ? Text('Error:  [${cubit.error}', style: AppFonts.audiowideStyle(color: Colors.redAccent))
                      : cubit.profileData != null
                          ? _ProfileCard(profile: cubit.profileData!)
                          : const Text('No profile data', style: TextStyle(color: Colors.white)),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    // Example fields: username, email, phone
    final username = profile['username'] ?? 'Unknown';
    final email = profile['email'] ?? 'No email';
    final phone = profile['phone'] ?? 'No phone';
    return Card(
      color: AppColors.inputFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 80, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(username, style: AppFonts.dashHorizonStyle(fontSize: 26, color: Colors.white)),
            const SizedBox(height: 8),
            Text(email, style: AppFonts.audiowideStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(phone, style: AppFonts.audiowideStyle(fontSize: 16, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
} 