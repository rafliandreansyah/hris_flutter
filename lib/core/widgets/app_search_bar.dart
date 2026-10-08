import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Reusable Search Bar Component (Stitch M3 "Teal Oasis" Standard).
/// Digunakan secara seragam di seluruh modul (Jadwal Kerja, Klaim & Kasbon, Asset, Resign, dll.)
/// untuk menjamin konsistensi background, border radius, elevation, dan perilaku keyboard dismiss.
class AppSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String? hintText;
  final Widget? trailing;
  final FocusNode? focusNode;
  final bool autoFocus;
  final EdgeInsetsGeometry margin;
  final double height;
  final bool enabled;

  const AppSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.hintText,
    this.trailing,
    this.focusNode,
    this.autoFocus = false,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
    this.height = 46,
    this.enabled = true,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _effectiveController;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _effectiveController = TextEditingController();
      _internalController = true;
    } else {
      _effectiveController = widget.controller!;
    }
    _effectiveController.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      if (widget.controller == null) {
        _effectiveController = TextEditingController();
        _internalController = true;
      } else {
        if (_internalController) {
          _effectiveController.dispose();
          _internalController = false;
        }
        _effectiveController = widget.controller!;
      }
      _effectiveController.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleControllerChanged);
    if (_internalController) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  void _handleClear() {
    _effectiveController.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;

    final hasText = _effectiveController.text.isNotEmpty;

    return Padding(
      padding: widget.margin,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: surfaceCol,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.2 : 0.03,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: TextField(
                  controller: _effectiveController,
                  focusNode: widget.focusNode,
                  autofocus: widget.autoFocus,
                  enabled: widget.enabled,
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  onChanged: widget.onChanged,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textCol,
                    fontSize: 14,
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.hintText ?? 'Cari...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: subtitleCol,
                      fontSize: 13.5,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 42,
                      minHeight: 42,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 18,
                      color: subtitleCol,
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 42,
                      minHeight: 42,
                    ),
                    suffixIcon: hasText
                        ? IconButton(
                            icon: Icon(
                              LucideIcons.x,
                              size: 16,
                              color: subtitleCol,
                            ),
                            splashRadius: 18,
                            padding: EdgeInsets.zero,
                            onPressed: _handleClear,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 8),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}
