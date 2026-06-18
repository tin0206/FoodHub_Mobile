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

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
      children: [
        Text(
          'Profile',
          style: TextStyle(
            fontSize: 28 / 2,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Settings & preferences',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 10),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appearance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.isDarkMode ? 'Dark mode' : 'Light mode',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: widget.isDarkMode,
                    onChanged: (_) => widget.onToggleTheme(),
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
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Personal Info',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Full Name',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              TextField(controller: _fullNameController),
              const SizedBox(height: 10),
              Text(
                'Email',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              TextField(controller: _emailController),
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
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.food_bank_outlined,
                      size: 14,
                      color: Color(0xFFA855F7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dietary Restrictions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 8,
                children: dietaryTags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
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
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      size: 14,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
          height: 42,
          child: FilledButton(
            onPressed: _saveChanges,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save changes'),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 12, color: colors.onSurface),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
