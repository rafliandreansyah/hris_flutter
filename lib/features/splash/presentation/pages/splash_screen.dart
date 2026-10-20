import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/app_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/utils/share_link_util.dart';
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
    try {
      final results = await Future.wait([
        AuthRepositoryImpl().hasActiveSession(),
        Future.delayed(const Duration(milliseconds: 750)),
      ]);
      if (!mounted) return;

      final hasSession = results.first as bool;
      final pendingLink = ShareLinkUtil.pendingLinkOf(context);
      AppRouter.sessionChecked = true;
      if (hasSession) {
        final router = GoRouter.of(context);
        router.replaceNamed(Routes.DASHBOARD);
        if (pendingLink != null) router.push(pendingLink);
      } else if (pendingLink != null) {
        context.replaceNamed(
          Routes.LOGIN,
          queryParameters: {'from': pendingLink},
        );
      } else {
        context.replaceNamed(Routes.LOGIN);
      }
    } catch (e) {
      debugPrint('[SplashScreen] gagal memeriksa sesi: $e');
      AppRouter.sessionChecked = true;
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
          const Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: AppNameVersionText(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
