import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hookaba/core/routes/app_router.dart';
import 'package:hookaba/core/utils/ble_service.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hookaba/features/onboarding/presentation/cubit/sign_up_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Hive
  await Hive.initFlutter();
  var pairedBox = await Hive.openBox<String>('pairedDevices');
  sl.registerLazySingleton<Box<String>>(() => pairedBox);

  // Router
  sl.registerLazySingleton(() => AppRouter());
  
  // Services
  sl.registerLazySingleton(() => BLEService());

  // Cubits
  sl.registerFactory(() => SignUpCubit(
    bleService: sl<BLEService>(),
    pairedBox: sl<Box<String>>(),
  ));
  sl.registerLazySingleton(() => DashboardCubit(
    bleService: sl<BLEService>(),
  ));
}

// Helper extension to find a device by name or ID
// This is a simple implementation and might need adjustments
// based on how device names and IDs are handled in your app. 