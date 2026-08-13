import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:foodhub_mobile/config/app_theme.dart';
import 'package:foodhub_mobile/screens/splash_screen.dart';

/// Multi-device UI preview (iPhone/Android frames).
/// On by default in debug. Disable if camera breaks:
///   flutter run -d chrome --dart-define=DEVICE_PREVIEW=false
const bool _kDevicePreview = bool.fromEnvironment(
  'DEVICE_PREVIEW',
  defaultValue: true,
);

Future<void> main() async {
  await dotenv.load();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode && _kDevicePreview,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodHub',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: (context, child) {
        final preview = DevicePreview.appBuilder(context, child);
        final mediaQuery = MediaQuery.of(context);
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: MediaQuery(
            data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.12)),
            child: preview,
          ),
        );
      },
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
