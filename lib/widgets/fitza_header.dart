import 'package:flutter/material.dart';

class FitzaHeader extends StatelessWidget {
  final String? centerTitle;
  final Widget? trailing;

  const FitzaHeader({
    super.key,
    this.centerTitle,
    this.trailing,
  });

  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/icon_light.png',
              height: 58,
              width: 58,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.bolt_rounded,
                  color: primaryBlue,
                  size: 44,
                );
              },
            ),
            const SizedBox(width: 6),
            const Text(
              'Fitza',
              style: TextStyle(
                color: darkText,
                fontSize: 30,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.8,
                height: 1.0,
              ),
            ),
          ],
        ),

        const Spacer(),

        if (centerTitle != null) ...[
          Text(
            centerTitle!,
            style: const TextStyle(
              color: darkText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
        ],

        if (trailing != null) trailing!,
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

  static const Color darkText = Color(0xFF0B1B4D);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: darkText,
          size: 23,
        ),
      ),
    );
  }
}