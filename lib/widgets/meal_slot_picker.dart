import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';

Future<String?> showMealSlotPicker(
  BuildContext context, {
  required String recipeName,
}) async {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final s = S.of(context);

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final cardBg = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
      final textColor = isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF111827);
      final subColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF059669)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.chooseMealSlot, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textColor)),
                    Text(recipeName, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: subColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SlotButton(label: s.breakfast, icon: Icons.wb_sunny_rounded, color: const Color(0xFFF59E0B), isDarkMode: isDarkMode, onTap: () => Navigator.pop(ctx, 'breakfast')),
            const SizedBox(height: 10),
            _SlotButton(label: s.lunch, icon: Icons.restaurant_rounded, color: const Color(0xFF059669), isDarkMode: isDarkMode, onTap: () => Navigator.pop(ctx, 'lunch')),
            const SizedBox(height: 10),
            _SlotButton(label: s.dinner, icon: Icons.nights_stay_rounded, color: const Color(0xFF6366F1), isDarkMode: isDarkMode, onTap: () => Navigator.pop(ctx, 'dinner')),
          ],
        ),
      );
    },
  );
}

class _SlotButton extends StatelessWidget {
  const _SlotButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDarkMode,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF111827),
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 20,
                color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
