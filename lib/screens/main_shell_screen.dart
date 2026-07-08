import 'package:flutter/material.dart';
import 'package:foodhub_mobile/config/app_theme.dart';
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
  const MainShellScreen({super.key, required this.initialUser});

  final UserModel initialUser;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  AppTab _currentTab = AppTab.home;
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
    _dietaryRestrictions = {..._user.dietaryRestrictions};
    _primaryGoal = _user.primaryGoal ?? 'Balanced Nutrition';
  }

  void _onUserUpdated(UserModel user) {
    setState(() {
      _user = user;
      _dietaryRestrictions = {...user.dietaryRestrictions};
      if (user.primaryGoal != null && user.primaryGoal!.isNotEmpty) {
        _primaryGoal = user.primaryGoal!;
      }
    });
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
      _currentTab = tab;
    });
  }

  void _onDetailModeChanged(AppTab tab, bool inDetail) {
    setState(() {
      _tabInDetail[tab] = inDetail;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
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
      ),
      FavoritesScreen(
        onDetailModeChanged: (v) => _onDetailModeChanged(AppTab.favorites, v),
      ),
      ProfileScreen(
        user: _user,
        isDarkMode: _isDarkMode,
        onToggleTheme: _toggleTheme,
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
      child: Scaffold(
        body: Column(
          children: [
            AppTopBar(onOpenProfile: _openProfile),
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
    );
  }
}
