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
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
          ),
          child: Row(
            children: [
              _BottomTabItem(
                label: 'Home',
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                isSelected: currentTab == AppTab.home,
                onTap: () => onTabSelected(AppTab.home),
              ),
              _BottomTabItem(
                label: 'Search',
                icon: Icons.search_outlined,
                selectedIcon: Icons.search,
                isSelected: currentTab == AppTab.search,
                onTap: () => onTabSelected(AppTab.search),
              ),
              _BottomTabItem(
                label: 'Recs',
                icon: Icons.auto_awesome_outlined,
                selectedIcon: Icons.auto_awesome,
                isSelected: currentTab == AppTab.recs,
                onTap: () => onTabSelected(AppTab.recs),
              ),
              _BottomTabItem(
                label: 'Favorites',
                icon: Icons.favorite_border,
                selectedIcon: Icons.favorite,
                isSelected: currentTab == AppTab.favorites,
                onTap: () => onTabSelected(AppTab.favorites),
              ),
              _BottomTabItem(
                label: 'Profile',
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                isSelected: currentTab == AppTab.profile,
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
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final activeColor = const Color(0xFF059669);
    final inactiveColor = colors.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 21,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
