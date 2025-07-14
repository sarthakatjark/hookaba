import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    show FlutterSecureStorage;
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hookaba/core/network/network_dio.dart';
import 'package:hookaba/core/routes/app_router.dart';
import 'package:hookaba/core/utils/api_constants.dart';
import 'package:hookaba/core/utils/ble_service.dart';
import 'package:hookaba/core/utils/js_bridge_service.dart';
import 'package:hookaba/features/dashboard/data/datasources/dashboard_repository_impl.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hookaba/features/onboarding/data/datasources/sign_up_repository_impl.dart';
import 'package:hookaba/features/onboarding/presentation/cubit/sign_up_cubit.dart';
import 'package:hookaba/features/profile/data/datasources/profile_repository_impl.dart';
import 'package:hookaba/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:hookaba/features/split_screen/data/datasources/split_screen_repository_impl.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Hive
  await Hive.initFlutter();
  var pairedBox = await Hive.openBox<String>('pairedDevices');
  sl.registerLazySingleton<Box<String>>(() => pairedBox);

  // Router
  sl.registerLazySingleton(() => AppRouter());

  // Services
  sl.registerLazySingleton(() => BLEService(sl<JsBridgeService>()));

  // Initialize and register JsBridgeService
  final jsBridgeService = JsBridgeService();
  await jsBridgeService.init();
  sl.registerLazySingleton<JsBridgeService>(() => jsBridgeService);

  // DioClient
  sl.registerLazySingleton(() => DioClient(ApiEndpoints.baseUrl));

  // Repositories
  sl.registerLazySingleton(() => SignUpRepositoryImpl(
        bleService: sl<BLEService>(),
        pairedBox: sl<Box<String>>(),
        dioClient: sl<DioClient>(),
        secureStorage: const FlutterSecureStorage(),
      ));

  // SplitScreenRepositoryImpl registration
  sl.registerLazySingleton(() => SplitScreenRepositoryImpl());

  // ProfileRepositoryImpl registration
  sl.registerLazySingleton(() => ProfileRepositoryImpl(
        dioClient: sl<DioClient>(),
        secureStorage: const FlutterSecureStorage(),
      ));

  // ProfileCubit registration
  sl.registerFactory(() => ProfileCubit(
        repository: sl<ProfileRepositoryImpl>(),
      ));

  // Cubits
  sl.registerFactory(() => SignUpCubit(
        signUpRepository: sl<SignUpRepositoryImpl>(),
        bleService: sl<BLEService>(),
      ));
  sl.registerLazySingleton(() => DashboardCubit(
        bleService: sl<BLEService>(),
        dashboardRepository: DashboardRepositoryImpl(
          bleService: sl<BLEService>(),
          jsBridgeService: sl<JsBridgeService>(),
        ),
        jsBridgeService: sl<JsBridgeService>(),
      ));
}

// Helper extension to find a device by name or ID
// This is a simple implementation and might need adjustments
// based on how device names and IDs are handled in your app.
