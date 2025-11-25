import 'package:dlsud_go/firebase_options.dart';
import 'package:dlsud_go/services/settings_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'package:dlsud_go/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Remove the redundant second call to WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize EasyLocalization (Must run immediately after bindings are ensured)
  await EasyLocalization.ensureInitialized();

  // 3. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. Load the .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

  // 5. Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 6. Set preferred orientations (portrait only for better UX)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final settingsService = SettingsService();
  await settingsService.loadSettings();

  // 7. WRAP YOUR APP WITH EasyLocalization
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('tl', 'PH')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: DLSUGoApp(settingsService: settingsService),
    ),
  );
}

class DLSUGoApp extends StatelessWidget {
  final SettingsService settingsService;
  const DLSUGoApp({super.key, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: settingsService,
      child: Consumer<SettingsService>(
        builder: (context, settings, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,

            // USE THE .tr() EXTENSION FOR TITLE
            onGenerateTitle: (context) => 'app_title'.tr(),

            // ADD LOCALIZATION DELEGATES AND SUPPORTED LOCALES
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,

            // THEME LOGIC REMAINS CORRECT
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            home: const SplashScreen(),

            // ... builder logic
            builder: (context, widget) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.of(context)
                      .textScaler
                      .clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2),
                ),
                child: widget ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}

