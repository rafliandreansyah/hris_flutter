import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppNameVersionText extends StatelessWidget {
  final String appName;
  final String? customVersion;
  final bool showBuildNumber;

  const AppNameVersionText({
    super.key,
    this.appName = 'OASISH HRIS • POWERED BY MURATECH',
    this.customVersion,
    this.showBuildNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    if (customVersion != null) {
      return _buildContent(context, customVersion!);
    }

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData
            ? (showBuildNumber
                  ? 'Versi: ${snapshot.data!.version}+${snapshot.data!.buildNumber}'
                  : 'Versi: ${snapshot.data!.version}')
            : 'Versi: 1.0.0';
        return _buildContent(context, version);
      },
    );
  }

  Widget _buildContent(BuildContext context, String versionText) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          appName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          versionText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
