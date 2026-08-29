import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Widget Input Field standar global Oasish HRIS dengan dukungan Label,
/// Trailing Action, Password Obscure Toggle, dan Validasi.
class AppTextField extends StatefulWidget {
  final String? label;
  final Widget? labelTrailing;
  final String? hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;
  final EdgeInsetsGeometry? contentPadding;

  const AppTextField({
    super.key,
    this.label,
    this.labelTrailing,
    this.hintText,
    this.controller,
    this.isPassword = false,
    this.obscureText = false,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixWidget,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.focusNode,
    this.autovalidateMode,
    this.contentPadding,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isPassword || widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final inputBg = isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final iconCol = isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant;

    Widget? resolvedPrefix;
    if (widget.prefixWidget != null) {
      resolvedPrefix = widget.prefixWidget;
    } else if (widget.prefixIcon != null) {
      resolvedPrefix = Icon(
        widget.prefixIcon,
        size: 20,
        color: iconCol,
      );
    }

    Widget? resolvedSuffix;
    if (widget.isPassword) {
      resolvedSuffix = IconButton(
        onPressed: () {
          setState(() {
            _isObscured = !_isObscured;
          });
        },
        icon: Icon(
          _isObscured ? LucideIcons.eye : LucideIcons.eyeOff,
          size: 20,
          color: iconCol,
        ),
      );
    } else if (widget.suffixWidget != null) {
      resolvedSuffix = widget.suffixWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Label Area (dengan optional trailing action seperti 'Forgot Password?')
        if (widget.label != null || widget.labelTrailing != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: AppTypography.labelMedium.copyWith(
                    color: labelCol,
                  ),
                )
              else
                const SizedBox.shrink(),
              if (widget.labelTrailing != null) widget.labelTrailing!,
            ],
          ),
          const SizedBox(height: 6),
        ],

        // 2. Input Box
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.isPassword ? _isObscured : widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          style: AppTypography.bodyMedium.copyWith(color: textCol),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: iconCol,
            ),
            filled: true,
            fillColor: widget.enabled ? inputBg : inputBg.withValues(alpha: 0.5),
            prefixIcon: resolvedPrefix,
            suffixIcon: resolvedSuffix,
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderCol),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderCol),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.brandTeal,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.errorRed,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.errorRed,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
