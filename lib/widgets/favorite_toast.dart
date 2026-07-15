import 'package:flutter/material.dart';

void showFavoriteToast(
  BuildContext context, {
  required String recipeName,
  required bool saved,
}) {
  _showAppToast(
    context,
    icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
    iconColor: saved ? const Color(0xFF34D399) : const Color(0xFFF87171),
    iconBg: saved
        ? const Color(0xFF059669).withValues(alpha: 0.15)
        : const Color(0xFFDC2626).withValues(alpha: 0.15),
    message: saved
        ? '$recipeName saved to favorites'
        : '$recipeName removed from favorites',
  );
}

void showErrorToast(BuildContext context, String message) {
  _showAppToast(
    context,
    icon: Icons.error_rounded,
    iconColor: const Color(0xFFF87171),
    iconBg: const Color(0xFFDC2626).withValues(alpha: 0.15),
    message: message,
  );
}

void showSuccessToast(BuildContext context, String message) {
  _showAppToast(
    context,
    icon: Icons.check_circle_rounded,
    iconColor: const Color(0xFF34D399),
    iconBg: const Color(0xFF059669).withValues(alpha: 0.15),
    message: message,
  );
}

void showProfileToast(BuildContext context) {
  _showAppToast(
    context,
    icon: Icons.person_rounded,
    iconColor: const Color(0xFF34D399),
    iconBg: const Color(0xFF059669).withValues(alpha: 0.15),
    message: 'Profile updated successfully',
  );
}

void showRecipeToast(
  BuildContext context, {
  required String recipeName,
  required bool isNew,
}) {
  _showAppToast(
    context,
    icon: isNew ? Icons.add_circle_rounded : Icons.check_circle_rounded,
    iconColor: const Color(0xFF34D399),
    iconBg: const Color(0xFF059669).withValues(alpha: 0.15),
    message: isNew ? '$recipeName created!' : '$recipeName updated!',
  );
}

void _showAppToast(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required Color iconBg,
  required String message,
}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (ctx) => _AppToast(
      icon: icon,
      iconColor: iconColor,
      iconBg: iconBg,
      message: message,
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 2200), entry.remove);
}

class _AppToast extends StatefulWidget {
  const _AppToast({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String message;

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 90,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, size: 16, color: widget.iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
