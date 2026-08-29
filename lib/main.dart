import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_theme.dart';
import 'package:hris_flutter/app/routes/app_router.dart';
import 'package:hris_flutter/core/services/notification_service.dart';
import 'package:hris_flutter/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase & Push Notification Service
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('ℹ️ [Firebase Setup]: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Oasish',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Default light, can be set to ThemeMode.system
      routerConfig: AppRouter.router, // Menggunakan GoRouter
      debugShowCheckedModeBanner: false,
    );
  }
}
