import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hookaba/core/injection_container/injection_container.dart'
    as di;
import 'package:hookaba/core/routes/app_router.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/core/utils/multi_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await di.init();
  runApp(const AppMultiProviders(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hookaba',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: AppFonts.dashHorizonStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          centerTitle: false,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: AppFonts.dashHorizonStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          centerTitle: false,
        ),
        useMaterial3: true,
      ),
      routerConfig: di.sl<AppRouter>().router,
    );
  }
}
