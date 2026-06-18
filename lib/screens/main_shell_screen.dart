import 'package:flutter/material.dart';
import 'package:foodhub_mobile/screens/favorites_screen.dart';
import 'package:foodhub_mobile/screens/home_screen.dart';
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

  void _onTabSelected(AppTab tab) {
    setState(() {
      _currentTab = tab;
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
      const HomeScreen(),
      const SearchScreen(),
      const RecsScreen(),
      const FavoritesScreen(),
      ProfileScreen(isDarkMode: _isDarkMode, onToggleTheme: _toggleTheme),
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
            ? const Color(0xFF111827)
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
        bottomNavigationBar: AppBottomBar(
          currentTab: _currentTab,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }
}
