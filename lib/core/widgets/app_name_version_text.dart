import 'package:flutter/material.dart';

class AppNameVersionText extends StatelessWidget {
  final String appName;
  final String appVersion;
  const AppNameVersionText({
    super.key,
    this.appName = 'OASISH HRIS • POWERED BY MURATECH',
    this.appVersion = 'Versi: 1.0.0',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          appName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 4),
        Text(
          appVersion,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
