import 'package:flutter/material.dart';
import 'package:foodhub_mobile/config/app_theme.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/screens/favorites_screen.dart';
import 'package:foodhub_mobile/screens/home_screen.dart';
import 'package:foodhub_mobile/screens/login_screen.dart';
import 'package:foodhub_mobile/screens/profile_screen.dart';
import 'package:foodhub_mobile/screens/recs_screen.dart';
import 'package:foodhub_mobile/screens/search_screen.dart';
import 'package:foodhub_mobile/services/auth_service.dart';
import 'package:foodhub_mobile/widgets/app_bottom_bar.dart';
import 'package:foodhub_mobile/widgets/app_top_bar.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    required this.initialUser,
    this.initialTab,
    this.onSwitchToAdmin,
  });

  final UserModel initialUser;
  final AppTab? initialTab;
  // Called with current context + user when user taps "Admin" button in the top bar.
  // Defined by AdminShellScreen to avoid a circular import.
  final void Function(BuildContext context, UserModel user)? onSwitchToAdmin;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  AppTab _currentTab = AppTab.home;
  final List<AppTab> _tabHistory = [AppTab.home];
  bool _isDarkMode = false;
  final Map<AppTab, bool> _tabInDetail = {};
  late UserModel _user;
  final _authService = AuthService();

  late Set<String> _dietaryRestrictions;
  late String _primaryGoal;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    LangScope.current.value = widget.initialUser.language ?? 'en';
    LangScope.current.addListener(_onGlobalLanguageChanged);
    _isDarkMode = widget.initialUser.theme == 'dark';
    _dietaryRestrictions = {..._user.dietaryRestrictions};
    _primaryGoal = _user.primaryGoal ?? '';
    if (widget.initialTab != null) _currentTab = widget.initialTab!;
  }

  @override
  void dispose() {
    LangScope.current.removeListener(_onGlobalLanguageChanged);
    super.dispose();
  }

  // ProfileScreen takes the current language as a constructor prop rather
  // than reading LangScope.of(context) itself, so this screen needs to
  // rebuild whenever the global language changes.
  void _onGlobalLanguageChanged() {
    if (mounted) setState(() {});
  }

  void _onUserUpdated(UserModel user) {
    setState(() {
      _user = user;
      _isDarkMode = user.theme == 'dark';
      _dietaryRestrictions = {...user.dietaryRestrictions};
      if (user.primaryGoal != null && user.primaryGoal!.isNotEmpty) {
        _primaryGoal = user.primaryGoal!;
      }
    });
    if (user.language != null && user.language!.isNotEmpty) {
      LangScope.current.value = user.language!;
    }
  }

  void _onLanguageChanged(String lang) {
    LangScope.current.value = lang;
  }

  void _onDietaryRestrictionToggled(String tag, bool selected) {
    setState(() {
      if (selected) {
        _dietaryRestrictions = {..._dietaryRestrictions, tag};
      } else {
        _dietaryRestrictions = _dietaryRestrictions.difference({tag});
      }
    });
  }

  void _onPrimaryGoalChanged(String goal) {
    setState(() => _primaryGoal = goal);
  }

  bool get _showBottomBar => !(_tabInDetail[_currentTab] ?? false);

  void _onTabSelected(AppTab tab) {
    setState(() {
      if (tab == AppTab.home) {
        _tabHistory
          ..clear()
          ..add(AppTab.home);
      } else if (tab != _currentTab) {
        _tabHistory.add(tab);
      }
      _currentTab = tab;
    });
  }

  void _onDetailModeChanged(AppTab tab, bool inDetail) {
    setState(() {
      _tabInDetail[tab] = inDetail;
    });
  }

  void _onThemeChanged(bool isDark) {
    setState(() => _isDarkMode = isDark);
  }

  void _openProfile() {
    _onTabSelected(AppTab.profile);
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onDetailModeChanged: (v) => _onDetailModeChanged(AppTab.home, v),
      ),
      SearchScreen(
        onDetailModeChanged: (v) => _onDetailModeChanged(AppTab.search, v),
      ),
      RecsScreen(
        dietaryRestrictions: _dietaryRestrictions,
        primaryGoal: _primaryGoal,
        onDetailModeChanged: (v) => _onDetailModeChanged(AppTab.recs, v),
      ),
      FavoritesScreen(
        onDetailModeChanged: (v) => _onDetailModeChanged(AppTab.favorites, v),
      ),
      ProfileScreen(
        user: _user,
        isDarkMode: _isDarkMode,
        language: LangScope.current.value,
        onThemeChanged: _onThemeChanged,
        onLanguageChanged: _onLanguageChanged,
        onLogout: _logout,
        selectedDietaryRestrictions: _dietaryRestrictions,
        onDietaryRestrictionToggled: _onDietaryRestrictionToggled,
        primaryGoal: _primaryGoal,
        onPrimaryGoalChanged: _onPrimaryGoalChanged,
        onUserUpdated: _onUserUpdated,
      ),
    ];

    return Theme(
      data: _isDarkMode ? AppTheme.dark : AppTheme.light,
      child: PopScope(
        canPop: _tabHistory.length <= 1,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_tabHistory.length > 1 &&
              !(_tabInDetail[_currentTab] ?? false)) {
            setState(() {
              _tabHistory.removeLast();
              _currentTab = _tabHistory.last;
            });
          }
        },
        child: Scaffold(
          body: Column(
            children: [
              AppTopBar(
                onOpenProfile: _openProfile,
                onSwitchToAdmin: widget.onSwitchToAdmin != null
                    ? () => widget.onSwitchToAdmin!(context, _user)
                    : null,
              ),
              Expanded(
                child: IndexedStack(index: _currentTab.index, children: screens),
              ),
            ],
          ),
          bottomNavigationBar: _showBottomBar
              ? AppBottomBar(
                  currentTab: _currentTab,
                  onTabSelected: _onTabSelected,
                )
              : null,
        ),
      ),
    );
  }
}
