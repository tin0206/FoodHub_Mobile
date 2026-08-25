import 'package:flutter/material.dart';
import 'package:foodhub_mobile/config/app_theme.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/screens/admin/admin_analytics_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_overview_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_recipes_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_users_screen.dart';
import 'package:foodhub_mobile/screens/login_screen.dart';
import 'package:foodhub_mobile/screens/main_shell_screen.dart';
import 'package:foodhub_mobile/screens/profile_screen.dart';
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
  late Set<String> _dietaryRestrictions;
  late String _primaryGoal;
  late String _language;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _isDarkMode = u.theme == 'dark';
    _dietaryRestrictions = {...u.dietaryRestrictions};
    _primaryGoal = u.primaryGoal ?? '';
    _language = u.language ?? 'en';
  }

  // Callback provided to MainShellScreen so it can navigate back to admin
  // without MainShellScreen needing to import AdminShellScreen.
  static void _goToAdmin(BuildContext ctx, UserModel user) {
    Navigator.of(ctx).pushReplacement(
      MaterialPageRoute(builder: (_) => AdminShellScreen(user: user)),
    );
  }

  void _switchToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainShellScreen(
          initialUser: widget.user,
          onSwitchToAdmin: _goToAdmin,
        ),
      ),
    );
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
      AdminAnalyticsScreen(isDarkMode: isDark),
      AdminRecipesScreen(isDarkMode: isDark),
      AdminUsersScreen(isDarkMode: isDark),
      ProfileScreen(
        user: widget.user,
        isDarkMode: isDark,
        language: _language,
        onThemeChanged: (dark) => setState(() => _isDarkMode = dark),
        onLanguageChanged: (lang) => setState(() => _language = lang),
        onLogout: _logout,
        selectedDietaryRestrictions: _dietaryRestrictions,
        onDietaryRestrictionToggled: (tag, selected) {
          setState(() {
            if (selected) {
              _dietaryRestrictions = {..._dietaryRestrictions, tag};
            } else {
              _dietaryRestrictions = _dietaryRestrictions.difference({tag});
            }
          });
        },
        primaryGoal: _primaryGoal,
        onPrimaryGoalChanged: (goal) => setState(() => _primaryGoal = goal),
        onUserUpdated: (_) {},
      ),
    ];

    const tabs = [
      (Icons.dashboard_rounded, Icons.dashboard_outlined, 'Overview'),
      (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Analytics'),
      (Icons.menu_book_rounded, Icons.menu_book_outlined, 'Recipes'),
      (Icons.people_rounded, Icons.people_outline_rounded, 'Users'),
    ];

    return LangScope(
      lang: _language,
      child: Theme(
        data: isDark ? AppTheme.dark : AppTheme.light,
        child: Scaffold(
        body: Column(
          children: [
            _AdminTopBar(
              user: widget.user,
              isDarkMode: isDark,
              onSwitchToApp: _switchToApp,
              onOpenProfile: () => setState(() => _tab = 4),
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
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.user,
    required this.isDarkMode,
    required this.onSwitchToApp,
    required this.onOpenProfile,
  });

  final UserModel user;
  final bool isDarkMode;
  final VoidCallback onSwitchToApp;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final textSub = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final pillBg = isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);

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
              // ── Left: logo + title (unchanged) ──────────────────────
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
                  color: isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
                ),
              ),
              const Spacer(),

              // ── Right: switch to App pill ────────────────────────────
              GestureDetector(
                onTap: onSwitchToApp,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.apps_rounded, size: 14, color: textSub),
                      const SizedBox(width: 5),
                      Text(
                        'App',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // ── Right: profile avatar (same style as app) ───────────
              InkWell(
                onTap: onOpenProfile,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded, size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

