import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_ui.dart';

/// Pemilih skala (mis. 1–5) dengan label deskriptif di ujung skala dari template.
class RatingSelector extends StatelessWidget {
  final int min;
  final int max;
  final int? value;
  final Map<String, String> labels;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const RatingSelector({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    this.labels = const {},
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = LifecycleColors.of(context);
    final steps = [for (var i = min; i <= max; i++) i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final s in steps)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    key: ValueKey('rating-$s'),
                    borderRadius: AppRadius.borderInput,
                    onTap: enabled ? () => onChanged(s) : null,
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: value == s ? c.brand : Colors.transparent,
                        borderRadius: AppRadius.borderInput,
                        border: Border.all(
                          color: value == s ? c.brand : c.border,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '$s',
                        style: AppTypography.titleSmall.copyWith(
                          color: value == s ? AppColors.onPrimary : c.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (labels.isNotEmpty || value != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 3, right: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    labels['$min'] ?? '',
                    style: AppTypography.labelSmall.copyWith(color: c.subtitle),
                  ),
                ),
                if (value != null && labels['$value'] != null && value != min && value != max)
                  Flexible(
                    child: Text(
                      labels['$value']!,
                      style: AppTypography.labelSmall.copyWith(
                        color: c.brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Flexible(
                  child: Text(
                    labels['$max'] ?? '',
                    textAlign: TextAlign.end,
                    style: AppTypography.labelSmall.copyWith(color: c.subtitle),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
