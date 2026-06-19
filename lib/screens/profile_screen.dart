import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;

  bool _notifyRecommendations = true;
  bool _notifyNewFeatures = true;
  bool _notifyWeeklySummary = true;
  final Set<String> _selectedDietaryTags = {
    'Dairy Free',
    'Egg Free',
    'Gluten Free',
    'Nut Free',
  };

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: 'John Doe');
    _emailController = TextEditingController(text: 'john@example.com');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Profile changes saved locally. Backend sync will be added later.',
        ),
      ),
    );
  }

  void _setTheme(bool darkMode) {
    if (widget.isDarkMode == darkMode) return;
    widget.onToggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dietaryTags = const [
      'Dairy Free',
      'Egg Free',
      'Gluten Free',
      'Nut Free',
      'Vegan',
      'Vegetarian',
      'Pescetarian',
    ];

    return Container(
      color: const Color(0xFFE5E7EB),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
        children: [
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Settings & preferences',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10.5),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.isDarkMode ? 'Dark mode' : 'Light mode',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ThemeModeChip(
                            label: 'Light',
                            selected: !widget.isDarkMode,
                            onTap: () => _setTheme(false),
                          ),
                          const SizedBox(width: 4),
                          _ThemeModeChip(
                            label: 'Dark',
                            selected: widget.isDarkMode,
                            onTap: () => _setTheme(true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBadge(
                      background: const Color(0xFFDCFCE7),
                      icon: Icons.person_outline,
                      iconColor: const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Personal Info',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                _ProfileField(controller: _fullNameController),
                const SizedBox(height: 8),
                Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                _ProfileField(controller: _emailController),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBadge(
                      background: const Color(0xFFF3E8FF),
                      icon: Icons.adjust,
                      iconColor: const Color(0xFFA855F7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dietary Restrictions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: dietaryTags
                      .map(
                        (tag) => FilterChip(
                          label: Text(tag),
                          selected: _selectedDietaryTags.contains(tag),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDietaryTags.add(tag);
                              } else {
                                _selectedDietaryTags.remove(tag);
                              }
                            });
                          },
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            color: _selectedDietaryTags.contains(tag)
                                ? const Color(0xFF065F46)
                                : colors.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: _selectedDietaryTags.contains(tag)
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          backgroundColor: const Color(0xFFF9FAFB),
                          selectedColor: const Color(0xFFD1FAE5),
                          side: BorderSide(
                            color: _selectedDietaryTags.contains(tag)
                                ? const Color(0xFF10B981)
                                : const Color(0xFFD1D5DB),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBadge(
                      background: const Color(0xFFDBEAFE),
                      icon: Icons.notifications_none,
                      iconColor: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _ToggleRow(
                  title: 'Recipe recommendations',
                  value: _notifyRecommendations,
                  onChanged: (value) {
                    setState(() {
                      _notifyRecommendations = value;
                    });
                  },
                ),
                _ToggleRow(
                  title: 'New features',
                  value: _notifyNewFeatures,
                  onChanged: (value) {
                    setState(() {
                      _notifyNewFeatures = value;
                    });
                  },
                ),
                _ToggleRow(
                  title: 'Weekly summary',
                  value: _notifyWeeklySummary,
                  onChanged: (value) {
                    setState(() {
                      _notifyWeeklySummary = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: _saveChanges,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Save changes',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFE5E7EB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF059669)),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.background,
    required this.icon,
    required this.iconColor,
  });

  final Color background;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(icon, size: 13, color: iconColor),
    );
  }
}

class _ThemeModeChip extends StatelessWidget {
  const _ThemeModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF059669) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 11, color: colors.onSurface),
            ),
          ),
          Transform.scale(
            scale: 0.83,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF10B981),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFD1D5DB),
            ),
          ),
        ],
      ),
    );
  }
}
