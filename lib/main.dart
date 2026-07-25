import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_theme.dart';
import 'package:hris_flutter/app/routes/app_router.dart';

void main() {
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
      routerConfig: AppRouter.router, // Menggunakan GoRouter
      debugShowCheckedModeBanner: false,
    );
  }
}
