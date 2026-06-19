import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

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

  Color get _screenBackground =>
      widget.isDarkMode ? const Color(0xFF07152D) : const Color(0xFFE5E7EB);

  Color get _cardBackground =>
      widget.isDarkMode ? const Color(0xFF0B1B38) : const Color(0xFFF3F4F6);

  Color get _cardBorder =>
      widget.isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFD1D5DB);

  Color get _primaryText =>
      widget.isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF111827);

  Color get _secondaryText =>
      widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

  Color get _fieldFill =>
      widget.isDarkMode ? const Color(0xFF1A2B49) : const Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
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
      color: _screenBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
        children: [
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Settings & preferences',
            style: TextStyle(color: _secondaryText, fontSize: 10.5),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            backgroundColor: _cardBackground,
            borderColor: _cardBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
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
                            style: TextStyle(fontSize: 11, color: _primaryText),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.isDarkMode ? 'Dark mode' : 'Light mode',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: _secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.9,
                      child: Switch(
                        value: widget.isDarkMode,
                        onChanged: (_) => widget.onToggleTheme(),
                        activeThumbColor: const Color(0xFFF59E0B),
                        activeTrackColor: const Color(0xFF10B981),
                        inactiveThumbColor: const Color(0xFFE5E7EB),
                        inactiveTrackColor: widget.isDarkMode
                            ? const Color(0xFF274A73)
                            : const Color(0xFFF3F4F6),
                        trackOutlineColor: WidgetStatePropertyAll(
                          widget.isDarkMode
                              ? const Color(0xFF274A73)
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            backgroundColor: _cardBackground,
            borderColor: _cardBorder,
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
                        color: _primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Full Name',
                  style: TextStyle(fontSize: 10.5, color: _secondaryText),
                ),
                const SizedBox(height: 4),
                _ProfileField(
                  controller: _fullNameController,
                  isDarkMode: widget.isDarkMode,
                  fillColor: _fieldFill,
                ),
                const SizedBox(height: 8),
                Text(
                  'Email',
                  style: TextStyle(fontSize: 10.5, color: _secondaryText),
                ),
                const SizedBox(height: 4),
                _ProfileField(
                  controller: _emailController,
                  isDarkMode: widget.isDarkMode,
                  fillColor: _fieldFill,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            backgroundColor: _cardBackground,
            borderColor: _cardBorder,
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
                        color: _primaryText,
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
                                : _secondaryText,
                            fontSize: 10,
                            fontWeight: _selectedDietaryTags.contains(tag)
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          backgroundColor: widget.isDarkMode
                              ? const Color(0xFF102647)
                              : const Color(0xFFF9FAFB),
                          selectedColor: const Color(0xFFD1FAE5),
                          side: BorderSide(
                            color: _selectedDietaryTags.contains(tag)
                                ? const Color(0xFF10B981)
                                : (widget.isDarkMode
                                      ? const Color(0xFF274A73)
                                      : const Color(0xFFD1D5DB)),
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
            backgroundColor: _cardBackground,
            borderColor: _cardBorder,
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
                        color: _primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _ToggleRow(
                  title: 'Recipe recommendations',
                  value: _notifyRecommendations,
                  isDarkMode: widget.isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _notifyRecommendations = value;
                    });
                  },
                ),
                _ToggleRow(
                  title: 'New features',
                  value: _notifyNewFeatures,
                  isDarkMode: widget.isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _notifyNewFeatures = value;
                    });
                  },
                ),
                _ToggleRow(
                  title: 'Weekly summary',
                  value: _notifyWeeklySummary,
                  isDarkMode: widget.isDarkMode,
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
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout, size: 16),
              label: const Text(
                'Log out',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                backgroundColor: const Color(0xFFFFF1F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.isDarkMode,
    required this.fillColor,
  });

  final TextEditingController controller;
  final bool isDarkMode;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontSize: 12,
        color: isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF374151),
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode
                ? const Color(0xFF274A73)
                : const Color(0xFFD1D5DB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode
                ? const Color(0xFF274A73)
                : const Color(0xFFD1D5DB),
          ),
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.value,
    required this.isDarkMode,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final bool isDarkMode;
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
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? const Color(0xFFE2E8F0) : colors.onSurface,
              ),
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
