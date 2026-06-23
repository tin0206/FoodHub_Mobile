import 'package:flutter/material.dart';

enum AppTab { home, search, recs, favorites, profile }

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0B1B38) : Colors.white,
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
        border: isDarkMode
            ? const Border(
                top: BorderSide(color: Color(0xFF1E3A5F)),
              )
            : null,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _BottomTabItem(
                label: 'Home',
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                isSelected: currentTab == AppTab.home,
                isDarkMode: isDarkMode,
                onTap: () => onTabSelected(AppTab.home),
              ),
              _BottomTabItem(
                label: 'Search',
                icon: Icons.search_outlined,
                selectedIcon: Icons.search_rounded,
                isSelected: currentTab == AppTab.search,
                isDarkMode: isDarkMode,
                onTap: () => onTabSelected(AppTab.search),
              ),
              _BottomTabItem(
                label: 'Recs',
                icon: Icons.auto_awesome_outlined,
                selectedIcon: Icons.auto_awesome,
                isSelected: currentTab == AppTab.recs,
                isDarkMode: isDarkMode,
                onTap: () => onTabSelected(AppTab.recs),
              ),
              _BottomTabItem(
                label: 'Favorites',
                icon: Icons.favorite_border_rounded,
                selectedIcon: Icons.favorite_rounded,
                isSelected: currentTab == AppTab.favorites,
                isDarkMode: isDarkMode,
                onTap: () => onTabSelected(AppTab.favorites),
              ),
              _BottomTabItem(
                label: 'Profile',
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                isSelected: currentTab == AppTab.profile,
                isDarkMode: isDarkMode,
                onTap: () => onTabSelected(AppTab.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomTabItem extends StatelessWidget {
  const _BottomTabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF059669);
    final inactiveColor = isDarkMode
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);
    final pillColor = isDarkMode
        ? const Color(0xFF064E3B).withValues(alpha: 0.7)
        : const Color(0xFFD1FAE5);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? pillColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  size: 22,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
