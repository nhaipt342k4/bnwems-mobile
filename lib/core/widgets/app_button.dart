import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final AppButtonVariant variant;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.goldPrimary;
        fg = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bg = const Color(0xFF2C241E);
        fg = Colors.white;
        break;
      case AppButtonVariant.outline:
        bg = Colors.white;
        fg = AppColors.warmTextDark;
        borderSide = const BorderSide(color: Color(0xFFF0E8DC));
        break;
      case AppButtonVariant.danger:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFB91C1C);
        borderSide = const BorderSide(color: Color(0xFFFFD6D6));
        break;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: variant == AppButtonVariant.primary ? 2 : 0,
      shadowColor: variant == AppButtonVariant.primary ? AppColors.goldPrimary.withValues(alpha: 0.3) : Colors.transparent,
      side: borderSide,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    );

    Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              ),
            ],
          );

    final button = SizedBox(
      height: 48,
      child: ElevatedButton(
        style: buttonStyle,
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: button,
      );
    }
    return button;
  }
}
