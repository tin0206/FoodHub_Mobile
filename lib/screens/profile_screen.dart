import 'package:flutter/material.dart';

const _kDietaryTags = [
  'Dairy Free',
  'Egg Free',
  'Gluten Free',
  'Nut Free',
  'Vegan',
  'Vegetarian',
  'Pescetarian',
];

const _kPrimaryGoals = [
  'Balanced Nutrition',
  'Weight Loss',
  'Muscle Gain',
  'High Protein',
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
    required this.selectedDietaryRestrictions,
    required this.onDietaryRestrictionToggled,
    required this.primaryGoal,
    required this.onPrimaryGoalChanged,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;
  final Set<String> selectedDietaryRestrictions;
  final void Function(String tag, bool selected) onDietaryRestrictionToggled;
  final String primaryGoal;
  final ValueChanged<String> onPrimaryGoalChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _calorieTargetController;
  late final TextEditingController _proteinTargetController;

  bool _notifyRecommendations = true;
  bool _notifyNewFeatures = true;
  bool _notifyWeeklySummary = true;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: 'John Doe');
    _emailController = TextEditingController(text: 'john@example.com');
    _ageController = TextEditingController();
    _weightController = TextEditingController();
    _calorieTargetController = TextEditingController(text: '2000');
    _proteinTargetController = TextEditingController(text: '120');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _calorieTargetController.dispose();
    _proteinTargetController.dispose();
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
      widget.isDarkMode ? const Color(0xFF1A2B49) : Colors.white;

  Color get _fieldBorder =>
      widget.isDarkMode ? const Color(0xFF274A73) : const Color(0xFFD1D5DB);

  @override
  Widget build(BuildContext context) {
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

          // ── Appearance ────────────────────────────────────────────────
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

          // ── Personal Information ──────────────────────────────────────
          _SectionCard(
            backgroundColor: _cardBackground,
            borderColor: _cardBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  badgeBackground: const Color(0xFFDCFCE7),
                  icon: Icons.person_outline,
                  iconColor: const Color(0xFF16A34A),
                  title: 'Personal Information',
                  subtitle: 'Update your profile details',
                  primaryText: _primaryText,
                  secondaryText: _secondaryText,
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Full Name',
                        controller: _fullNameController,
                        secondaryText: _secondaryText,
                        fillColor: _fieldFill,
                        borderColor: _fieldBorder,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LabeledField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        secondaryText: _secondaryText,
                        fillColor: _fieldFill,
                        borderColor: _fieldBorder,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Age',
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        hintText: 'e.g. 28',
                        secondaryText: _secondaryText,
                        fillColor: _fieldFill,
                        borderColor: _fieldBorder,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LabeledField(
                        label: 'Weight (kg)',
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        hintText: 'e.g. 75',
                        secondaryText: _secondaryText,
                        fillColor: _fieldFill,
                        borderColor: _fieldBorder,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Nutrition Goals ───────────────────────────────────────────
          _SectionCard(
            backgroundColor: _cardBackground,
            borderColor: _cardBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  badgeBackground: const Color(0xFFF3E8FF),
                  icon: Icons.adjust,
                  iconColor: const Color(0xFFA855F7),
                  title: 'Nutrition Goals',
                  subtitle: 'Set your dietary objectives',
                  primaryText: _primaryText,
                  secondaryText: _secondaryText,
                ),
                const SizedBox(height: 10),
                Text(
                  'Primary Goal',
                  style: TextStyle(fontSize: 10.5, color: _secondaryText),
                ),
                const SizedBox(height: 6),
                GridView.count(
                  padding: EdgeInsets.zero,
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 4,
                  children: _kPrimaryGoals.map((goal) {
                    final isSelected = widget.primaryGoal == goal;
                    return GestureDetector(
                      onTap: () => widget.onPrimaryGoalChanged(goal),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFD1FAE5)
                              : (widget.isDarkMode
                                    ? const Color(0xFF102647)
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF059669)
                                : _fieldBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          goal,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFF065F46)
                                : _primaryText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Daily Calorie Target',
                        controller: _calorieTargetController,
                        keyboardType: TextInputType.number,
                        secondaryText: _secondaryText,
                        fillColor: _fieldFill,
                        borderColor: _fieldBorder,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LabeledField(
                        label: 'Target Protein (g/day)',
                        controller: _proteinTargetController,
                        keyboardType: TextInputType.number,
                        secondaryText: _secondaryText,
                        fillColor: _fieldFill,
                        borderColor: _fieldBorder,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Dietary Restrictions',
                  style: TextStyle(fontSize: 10.5, color: _secondaryText),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _kDietaryTags.map((tag) {
                    final isSelected = widget.selectedDietaryRestrictions
                        .contains(tag);
                    return GestureDetector(
                      onTap: () =>
                          widget.onDietaryRestrictionToggled(tag, !isSelected),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFD1FAE5)
                              : (widget.isDarkMode
                                    ? const Color(0xFF102647)
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF10B981)
                                : _fieldBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFF065F46)
                                : _secondaryText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Notifications ─────────────────────────────────────────────
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
                  onChanged: (v) => setState(() => _notifyRecommendations = v),
                ),
                _ToggleRow(
                  title: 'New features',
                  value: _notifyNewFeatures,
                  isDarkMode: widget.isDarkMode,
                  onChanged: (v) => setState(() => _notifyNewFeatures = v),
                ),
                _ToggleRow(
                  title: 'Weekly summary',
                  value: _notifyWeeklySummary,
                  isDarkMode: widget.isDarkMode,
                  onChanged: (v) => setState(() => _notifyWeeklySummary = v),
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

// ── Shared section header ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.badgeBackground,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.primaryText,
    required this.secondaryText,
  });

  final Color badgeBackground;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color primaryText;
  final Color secondaryText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBadge(
          background: badgeBackground,
          icon: icon,
          iconColor: iconColor,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: secondaryText),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Labeled text field ────────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.secondaryText,
    required this.fillColor,
    required this.borderColor,
    required this.isDarkMode,
    this.keyboardType,
    this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final Color secondaryText;
  final Color fillColor;
  final Color borderColor;
  final bool isDarkMode;
  final TextInputType? keyboardType;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10.5, color: secondaryText)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF374151),
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: fillColor,
            hintText: hintText,
            hintStyle: TextStyle(color: secondaryText, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF059669)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

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
