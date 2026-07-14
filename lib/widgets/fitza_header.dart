import 'package:flutter/material.dart';

import '../main.dart';

class FitzaHeader extends StatelessWidget {
  final String? centerTitle;
  final Widget? trailing;
  final bool showBrand;

  const FitzaHeader({
    super.key,
    this.centerTitle,
    this.trailing,
    this.showBrand = true,
  });

  @override
  Widget build(BuildContext context) {
    final fitzaColors = Theme.of(context).extension<FitzaThemeColors>()!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 50,
      child: Row(
        children: [
          if (showBrand) _FitzaBrand(isDarkMode: isDarkMode),

          if (showBrand) const SizedBox(width: 10),

          Expanded(
            child: centerTitle == null
                ? const SizedBox.shrink()
                : Text(
                    centerTitle!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fitzaColors.primaryText,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
          ),

          if (trailing != null)
            trailing!
          else
            const SizedBox(
              height: 44,
              width: 44,
            ),
        ],
      ),
    );
  }
}

class _FitzaBrand extends StatelessWidget {
  final bool isDarkMode;

  const _FitzaBrand({
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final fitzaColors = Theme.of(context).extension<FitzaThemeColors>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          isDarkMode
              ? 'assets/icon/icon_dark.png'
              : 'assets/icon/icon_light.png',
          height: 40,
          width: 40,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.bolt_rounded,
              color: fitzaColors.primaryBlue,
              size: 34,
            );
          },
        ),
        const SizedBox(width: 7),
        Text(
          'Fitza',
          style: TextStyle(
            color: fitzaColors.primaryText,
            fontSize: 27,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.7,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class FitzaHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const FitzaHeaderIconButton({
    super.key,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fitzaColors = Theme.of(context).extension<FitzaThemeColors>()!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: fitzaColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: fitzaColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? const Color(0x33000000)
                  : const Color(0x0F000000),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: fitzaColors.primaryText,
          size: 23,
        ),
      ),
    );
  }
}