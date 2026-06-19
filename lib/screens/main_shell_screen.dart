import 'package:flutter/material.dart';
import 'package:foodhub_mobile/screens/favorites_screen.dart';
import 'package:foodhub_mobile/screens/home_screen.dart';
import 'package:foodhub_mobile/screens/login_screen.dart';
import 'package:foodhub_mobile/screens/profile_screen.dart';
import 'package:foodhub_mobile/screens/recs_screen.dart';
import 'package:foodhub_mobile/screens/search_screen.dart';
import 'package:foodhub_mobile/widgets/app_bottom_bar.dart';
import 'package:foodhub_mobile/widgets/app_top_bar.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  AppTab _currentTab = AppTab.home;
  bool _isDarkMode = false;
  final Map<AppTab, bool> _tabInDetail = {};

  Set<String> _dietaryRestrictions = {
    'Dairy Free',
    'Egg Free',
    'Gluten Free',
    'Nut Free',
  };
  String _primaryGoal = 'Balanced Nutrition';

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
        isDarkMode: _isDarkMode,
        onToggleTheme: _toggleTheme,
        onLogout: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
        selectedDietaryRestrictions: _dietaryRestrictions,
        onDietaryRestrictionToggled: _onDietaryRestrictionToggled,
        primaryGoal: _primaryGoal,
        onPrimaryGoalChanged: _onPrimaryGoalChanged,
      ),
    ];

    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF059669),
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
    );

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: _isDarkMode
            ? const Color(0xFF07152D)
            : const Color(0xFFF3F4F6),
      ),
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
