import 'package:flutter/material.dart';
import 'package:foodhub_mobile/config/app_theme.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/screens/admin/admin_analytics_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_overview_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_recipes_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_users_screen.dart';
import 'package:foodhub_mobile/screens/login_screen.dart';
import 'package:foodhub_mobile/services/auth_service.dart';

const kAdminAccent = Color(0xFF6366F1);

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _tab = 0;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.user.theme == 'dark';
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;

    final screens = [
      AdminOverviewScreen(user: widget.user, isDarkMode: isDark),
      AdminUsersScreen(isDarkMode: isDark),
      AdminRecipesScreen(isDarkMode: isDark),
      AdminAnalyticsScreen(isDarkMode: isDark),
    ];

    const tabs = [
      (Icons.dashboard_rounded, Icons.dashboard_outlined, 'Overview'),
      (Icons.people_rounded, Icons.people_outline_rounded, 'Users'),
      (Icons.menu_book_rounded, Icons.menu_book_outlined, 'Recipes'),
      (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Analytics'),
    ];

    return Theme(
      data: isDark ? AppTheme.dark : AppTheme.light,
      child: Scaffold(
        body: Column(
          children: [
            _AdminTopBar(
              isDarkMode: isDark,
              onToggleTheme: () => setState(() => _isDarkMode = !isDark),
              onLogout: _logout,
            ),
            Expanded(
              child: IndexedStack(index: _tab, children: screens),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: List.generate(tabs.length, (i) {
                  final (activeIcon, inactiveIcon, label) = tabs[i];
                  final selected = _tab == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              selected ? activeIcon : inactiveIcon,
                              key: ValueKey(selected),
                              size: 22,
                              color: selected
                                  ? kAdminAccent
                                  : (isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF9CA3AF)),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? kAdminAccent
                                  : (isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF9CA3AF)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDarkMode ? const Color(0xFF0A0A0A) : Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF0A0A0A) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: kAdminAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 17,
                  color: kAdminAccent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Admin Panel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDarkMode
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onToggleTheme,
                icon: Icon(
                  isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  size: 20,
                  color: isDarkMode
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                onPressed: onLogout,
                icon: Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: isDarkMode
                      ? const Color(0xFFF87171)
                      : const Color(0xFFEF4444),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
