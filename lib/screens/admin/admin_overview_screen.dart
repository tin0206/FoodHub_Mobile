import 'package:flutter/material.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({
    super.key,
    required this.user,
    required this.isDarkMode,
  });

  final UserModel user;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDarkMode
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF111827);
    final textSub = isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);
    final cardBg = isDarkMode ? const Color(0xFF141414) : Colors.white;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ── Greeting ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kAdminAccent, Color(0xFF4F46E5)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: kAdminAccent.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.fullName ?? user.username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Administrator',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Stat tiles ────────────────────────────────────────────────
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        GridView.count(
          padding: const EdgeInsets.only(top: 8),
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: const [
            _StatTile(
              icon: Icons.people_rounded,
              label: 'Total Users',
              value: '247',
              trend: '+12 this week',
              color: Color(0xFF6366F1),
            ),
            _StatTile(
              icon: Icons.menu_book_rounded,
              label: 'Total Recipes',
              value: '1,842',
              trend: '+34 this week',
              color: Color(0xFF10B981),
            ),
            _StatTile(
              icon: Icons.favorite_rounded,
              label: 'Total Favorites',
              value: '4,391',
              trend: '+208 this week',
              color: Color(0xFFF43F5E),
            ),
            _StatTile(
              icon: Icons.smart_toy_rounded,
              label: 'AI Scans',
              value: '893',
              trend: '+57 this week',
              color: Color(0xFFF59E0B),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── Recent activity ───────────────────────────────────────────
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.06),
                blurRadius: isDarkMode ? 12 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ..._kRecentActivity.asMap().entries.map((e) {
                final item = e.value;
                final isLast = e.key == _kRecentActivity.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, size: 16, color: item.color),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  item.time,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 58,
                        color: isDarkMode
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF3F4F6),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: isDark ? 12 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF111827),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String time;
}

const _kRecentActivity = [
  _ActivityItem(
    icon: Icons.person_add_rounded,
    color: Color(0xFF6366F1),
    title: 'New user registered: kieu_anh',
    time: '2 minutes ago',
  ),
  _ActivityItem(
    icon: Icons.menu_book_rounded,
    color: Color(0xFF10B981),
    title: 'Recipe "Phở Bò Hà Nội" added',
    time: '14 minutes ago',
  ),
  _ActivityItem(
    icon: Icons.favorite_rounded,
    color: Color(0xFFF43F5E),
    title: '12 new favorites in the last hour',
    time: '1 hour ago',
  ),
  _ActivityItem(
    icon: Icons.smart_toy_rounded,
    color: Color(0xFFF59E0B),
    title: 'AI scan by minh_duc: 5 ingredients',
    time: '2 hours ago',
  ),
  _ActivityItem(
    icon: Icons.person_add_rounded,
    color: Color(0xFF6366F1),
    title: 'New user registered: thanh_nam',
    time: '3 hours ago',
  ),
  _ActivityItem(
    icon: Icons.menu_book_rounded,
    color: Color(0xFF10B981),
    title: 'Recipe "Avocado Toast" added',
    time: '5 hours ago',
  ),
];
