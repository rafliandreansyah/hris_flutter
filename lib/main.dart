import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_theme.dart';
import 'package:hris_flutter/app/routes/app_router.dart';
import 'package:hris_flutter/core/localization/bloc/locale_bloc.dart';
import 'package:hris_flutter/core/services/notification_service.dart';
import 'package:hris_flutter/firebase_options.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';

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
  final LocaleBloc? localeBloc;

  const MyApp({super.key, this.localeBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocaleBloc>(
      create: (context) =>
          (localeBloc ?? LocaleBloc())..add(const LocaleStarted()),
      child: BlocBuilder<LocaleBloc, LocaleState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'Oasish',
            locale: state.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
