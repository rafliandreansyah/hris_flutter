import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_repository_providers.dart';
import 'package:hris_flutter/app/config/app_theme.dart';
import 'package:hris_flutter/app/routes/app_router.dart';
import 'package:hris_flutter/core/localization/bloc/locale_bloc.dart';
import 'package:hris_flutter/core/network/alice_service.dart';
import 'package:hris_flutter/core/services/notification_service.dart';
import 'package:hris_flutter/core/widgets/offline_status_banner.dart';
import 'package:hris_flutter/features/employee/domain/repositories/organization_filter_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/organization_filter/organization_filter_bloc.dart';
import 'package:hris_flutter/firebase_options.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Alice HTTP Inspector (Debug Mode)
  if (kDebugMode) {
    AliceService.instance;
  }

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
  final OrganizationFilterBloc? organizationFilterBloc;

  const MyApp({
    super.key,
    this.localeBloc,
    this.organizationFilterBloc,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: AppRepositoryProviders.providers,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LocaleBloc>(
            create: (context) =>
                (localeBloc ?? LocaleBloc())..add(const LocaleStarted()),
          ),
          BlocProvider<OrganizationFilterBloc>(
            create: (context) =>
                organizationFilterBloc ??
                OrganizationFilterBloc(
                  repository: context.read<OrganizationFilterRepository>(),
                ),
          ),
        ],
        child: BlocBuilder<LocaleBloc, LocaleState>(
          builder: (context, state) {
            return MaterialApp.router(
              title: 'Oasish',
              locale: state.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.system,
              routerConfig: AppRouter.router,
              debugShowCheckedModeBanner: false,
              builder: (context, child) =>
                  OfflineStatusBanner(child: child ?? const SizedBox.shrink()),
            );
          },
        ),
      ),
    );
  }
}
