import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/app_name_version_text.dart';
import 'package:hris_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hris_flutter/gen/assets.gen.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      final hasSession = await AuthRepositoryImpl().hasActiveSession();
      if (!mounted) return;

      if (hasSession) {
        context.replaceNamed(Routes.DASHBOARD);
      } else {
        context.replaceNamed(Routes.LOGIN);
      }
    } catch (_) {
      if (!mounted) return;
      context.replaceNamed(Routes.LOGIN);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(Assets.icons.logo.path, width: 180, height: 180),
                const SizedBox(height: 8),
                Text(
                  'Oasish',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: AppNameVersionText(),
            ),
          ),
        ],
      ),
    );
  }
}
