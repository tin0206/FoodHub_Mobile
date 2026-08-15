import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/auth_service.dart';
import 'package:foodhub_mobile/widgets/favorite_toast.dart';

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
    required this.user,
    required this.isDarkMode,
    required this.language,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onLogout,
    required this.selectedDietaryRestrictions,
    required this.onDietaryRestrictionToggled,
    required this.primaryGoal,
    required this.onPrimaryGoalChanged,
    required this.onUserUpdated,
  });

  final UserModel user;
  final bool isDarkMode;
  final String language;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onLogout;
  final Set<String> selectedDietaryRestrictions;
  final void Function(String tag, bool selected) onDietaryRestrictionToggled;
  final String primaryGoal;
  final ValueChanged<String> onPrimaryGoalChanged;
  final ValueChanged<UserModel> onUserUpdated;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _calorieTargetController;
  late TextEditingController _proteinTargetController;

  late String _snapFullName;
  late String _snapEmail;
  late String _snapAge;
  late String _snapWeight;
  late String _snapCalorie;
  late String _snapProtein;
  late String _snapLanguage;
  late String _snapTheme;
  late bool _snapNotifyRecs;
  late bool _snapNotifyFeatures;
  late bool _snapNotifyWeekly;

  late bool _pendingDarkMode;
  late String _pendingLanguage;

  bool _isSaving = false;
  bool _notifyRecommendations = true;
  bool _notifyNewFeatures = true;
  bool _notifyWeeklySummary = true;
  String? _ageError;
  String? _weightError;
  String? _calorieError;
  String? _proteinError;

  final _scrollController = ScrollController();
  bool _actionButtonsVisible = false;

  void _onFieldChanged() { if (mounted) setState(() {}); }

  @override
  void initState() {
    super.initState();
    _applyUser(widget.user);
    _pendingDarkMode = widget.isDarkMode;
    _pendingLanguage = widget.language;
    _fullNameController = TextEditingController(text: _snapFullName)..addListener(_onFieldChanged);
    _emailController = TextEditingController(text: _snapEmail);
    _ageController = TextEditingController(text: _snapAge)..addListener(_onFieldChanged);
    _weightController = TextEditingController(text: _snapWeight)..addListener(_onFieldChanged);
    _calorieTargetController = TextEditingController(text: _snapCalorie)..addListener(_onFieldChanged);
    _proteinTargetController = TextEditingController(text: _snapProtein)..addListener(_onFieldChanged);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      _applyUser(widget.user);
      _pendingDarkMode = widget.isDarkMode;
      _pendingLanguage = widget.language;
      _fullNameController.text = _snapFullName;
      _emailController.text = _snapEmail;
      _ageController.text = _snapAge;
      _weightController.text = _snapWeight;
      _calorieTargetController.text = _snapCalorie;
      _proteinTargetController.text = _snapProtein;
    }
  }

  void _applyUser(UserModel user) {
    _snapFullName = user.fullName ?? '';
    _snapEmail = user.email;
    _snapAge = user.age?.toString() ?? '';
    _snapWeight = user.weight?.toString() ?? '';
    _snapCalorie = user.calorieTarget?.toString() ?? '';
    _snapProtein = user.proteinTarget?.toString() ?? '';
    _snapLanguage = user.language ?? 'en';
    _snapTheme = user.theme;
    _notifyRecommendations = _snapNotifyRecs = user.notifyRecommendations;
    _notifyNewFeatures = _snapNotifyFeatures = user.notifyNewFeatures;
    _notifyWeeklySummary = _snapNotifyWeekly = user.notifyWeeklySummary;
  }

  bool get _hasChanges {
    if (_fullNameController.text.trim() != _snapFullName) return true;
    if (_ageController.text.trim() != _snapAge) return true;
    if (_weightController.text.trim() != _snapWeight) return true;
    if (_calorieTargetController.text.trim() != _snapCalorie) return true;
    if (_proteinTargetController.text.trim() != _snapProtein) return true;
    if (_pendingLanguage != _snapLanguage) return true;
    if (_pendingDarkMode != (_snapTheme == 'dark')) return true;
    if (_notifyRecommendations != _snapNotifyRecs) return true;
    if (_notifyNewFeatures != _snapNotifyFeatures) return true;
    if (_notifyWeeklySummary != _snapNotifyWeekly) return true;
    final userDiet = widget.user.dietaryRestrictions.toSet();
    if (widget.selectedDietaryRestrictions.length != userDiet.length ||
        !widget.selectedDietaryRestrictions.containsAll(userDiet)) return true;
    if (widget.primaryGoal != (widget.user.primaryGoal ?? '')) return true;
    return false;
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_onFieldChanged);
    _ageController.removeListener(_onFieldChanged);
    _weightController.removeListener(_onFieldChanged);
    _calorieTargetController.removeListener(_onFieldChanged);
    _proteinTargetController.removeListener(_onFieldChanged);
    _fullNameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _calorieTargetController.dispose();
    _proteinTargetController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    final s = S.of(context);

    String? ageErr, weightErr, calorieErr, proteinErr;

    final ageVal = _ageController.text.trim();
    if (ageVal.isNotEmpty) {
      final v = int.tryParse(ageVal);
      if (v == null || v <= 0) ageErr = s.mustBePositiveNumber;
    }

    final weightVal = _weightController.text.trim();
    if (weightVal.isNotEmpty) {
      final v = double.tryParse(weightVal);
      if (v == null || v <= 0) weightErr = s.mustBePositiveNumber;
    }

    final calorieVal = _calorieTargetController.text.trim();
    if (calorieVal.isNotEmpty) {
      final v = int.tryParse(calorieVal);
      if (v == null || v <= 0) calorieErr = s.mustBePositiveNumber;
    }

    final proteinVal = _proteinTargetController.text.trim();
    if (proteinVal.isNotEmpty) {
      final v = int.tryParse(proteinVal);
      if (v == null || v <= 0) proteinErr = s.mustBePositiveNumber;
    }

    setState(() {
      _ageError = ageErr;
      _weightError = weightErr;
      _calorieError = calorieErr;
      _proteinError = proteinErr;
    });

    if (ageErr != null || weightErr != null || calorieErr != null || proteinErr != null) {
      return;
    }

    setState(() => _isSaving = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: CircularProgressIndicator(color: Color(0xFF059669)),
          ),
        ),
      ),
    );

    try {
      final updated = await _userService.updateMe({
        'full_name': _fullNameController.text.trim(),
        if (ageVal.isNotEmpty) 'age': int.parse(ageVal),
        if (weightVal.isNotEmpty) 'weight': double.parse(weightVal),
        if (calorieVal.isNotEmpty) 'calorie_target': int.parse(calorieVal),
        if (proteinVal.isNotEmpty) 'protein_target': int.parse(proteinVal),
        'dietary_restrictions': widget.selectedDietaryRestrictions.toList(),
        'primary_goal': widget.primaryGoal,
        'language': _pendingLanguage,
        'theme': _pendingDarkMode ? 'dark' : 'light',
        'notify_recommendations': _notifyRecommendations,
        'notify_new_features': _notifyNewFeatures,
        'notify_weekly_summary': _notifyWeeklySummary,
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() {
        _isSaving = false;
        _applyUser(updated);
        _fullNameController.text = _snapFullName;
        _emailController.text = _snapEmail;
        _ageController.text = _snapAge;
        _weightController.text = _snapWeight;
        _calorieTargetController.text = _snapCalorie;
        _proteinTargetController.text = _snapProtein;
      });
      widget.onUserUpdated(updated);
      showProfileToast(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _isSaving = false);
      showErrorToast(context, e.message);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _isSaving = false);
      showErrorToast(context, s.unableToSaveProfile);
    }
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(
        isDarkMode: widget.isDarkMode,
        cardBackground: _cardBackground,
        cardBorder: _cardBorder,
        primaryText: _primaryText,
        secondaryText: _secondaryText,
        fieldFill: _fieldFill,
        fieldBorder: _fieldBorder,
      ),
    );
  }

  void _cancelChanges() {
    // Reset dietary restrictions to original
    final originalDiet = widget.user.dietaryRestrictions.toSet();
    for (final tag in widget.selectedDietaryRestrictions.difference(originalDiet)) {
      widget.onDietaryRestrictionToggled(tag, false);
    }
    for (final tag in originalDiet.difference(widget.selectedDietaryRestrictions)) {
      widget.onDietaryRestrictionToggled(tag, true);
    }

    // Reset primary goal to original
    final originalGoal = widget.user.primaryGoal ?? '';
    if (widget.primaryGoal != originalGoal) {
      widget.onPrimaryGoalChanged(originalGoal);
    }

    setState(() {
      _pendingDarkMode = _snapTheme == 'dark';
      _pendingLanguage = _snapLanguage;
      _fullNameController.text = _snapFullName;
      _emailController.text = _snapEmail;
      _ageController.text = _snapAge;
      _weightController.text = _snapWeight;
      _calorieTargetController.text = _snapCalorie;
      _proteinTargetController.text = _snapProtein;
      _notifyRecommendations = _snapNotifyRecs;
      _notifyNewFeatures = _snapNotifyFeatures;
      _notifyWeeklySummary = _snapNotifyWeekly;
      _ageError = null;
      _weightError = null;
      _calorieError = null;
      _proteinError = null;
    });
  }

  Color get _screenBackground =>
      widget.isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFE5E7EB);

  Color get _cardBackground =>
      widget.isDarkMode ? const Color(0xFF141414) : Colors.white;

  Color get _cardBorder =>
      widget.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFD1D5DB);

  Color get _primaryText =>
      widget.isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF111827);

  Color get _secondaryText =>
      widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

  Color get _fieldFill =>
      widget.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);

  Color get _fieldBorder =>
      widget.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFD1D5DB);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Stack(
      children: [
        Container(
          color: _screenBackground,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              final atBottom = notification.metrics.extentAfter < 50;
              if (atBottom != _actionButtonsVisible) {
                setState(() => _actionButtonsVisible = atBottom);
              }
              return false;
            },
            child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
        children: [
          // ── Avatar card ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: _cardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.4 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 10),
                Text(
                  _fullNameController.text.isNotEmpty
                      ? _fullNameController.text
                      : s.yourProfile,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _emailController.text.isNotEmpty
                      ? _emailController.text
                      : s.settingsPreferences,
                  style: TextStyle(color: _secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Appearance ──────────────────────────────────────────────────
          _SectionCard(
            backgroundColor: _cardBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.appearance,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _primaryText),
                ),
                const SizedBox(height: 6),
                // Theme toggle
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.themeLabel, style: TextStyle(fontSize: 13, color: _primaryText)),
                          const SizedBox(height: 1),
                          Text(
                            _pendingDarkMode ? s.darkMode : s.lightMode,
                            style: TextStyle(fontSize: 11, color: _secondaryText),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.9,
                      child: Switch(
                        value: _pendingDarkMode,
                        onChanged: (v) => setState(() => _pendingDarkMode = v),
                        activeThumbColor: const Color(0xFFF59E0B),
                        activeTrackColor: const Color(0xFF10B981),
                        inactiveThumbColor: const Color(0xFFE5E7EB),
                        inactiveTrackColor: widget.isDarkMode
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF3F4F6),
                        trackOutlineColor: WidgetStatePropertyAll(
                          widget.isDarkMode
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: _fieldBorder),
                const SizedBox(height: 10),
                // Language selector
                Text(s.languageLabel, style: TextStyle(fontSize: 13, color: _primaryText)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _LangOption(
                      label: s.langVietnamese,
                      flag: '🇻🇳',
                      isSelected: _pendingLanguage == 'vi',
                      isDarkMode: widget.isDarkMode,
                      onTap: () => setState(() => _pendingLanguage = 'vi'),
                    ),
                    const SizedBox(width: 8),
                    _LangOption(
                      label: s.langEnglish,
                      flag: '🇺🇸',
                      isSelected: _pendingLanguage == 'en',
                      isDarkMode: widget.isDarkMode,
                      onTap: () => setState(() => _pendingLanguage = 'en'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Personal Information ────────────────────────────────────────
          _SectionCard(
            backgroundColor: _cardBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  badgeBackground: widget.isDarkMode
                      ? const Color(0xFF16A34A).withValues(alpha: 0.18)
                      : const Color(0xFFDCFCE7),
                  icon: Icons.person_outline,
                  iconColor: widget.isDarkMode
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFF16A34A),
                  title: s.personalInformation,
                  subtitle: s.updateProfileDetails,
                  primaryText: _primaryText,
                  secondaryText: _secondaryText,
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: s.fullNameLabel,
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
                        label: s.emailLabel,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: true,
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
                        label: s.ageLabel,
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        hintText: 'e.g. 28',
                        errorText: _ageError,
                        secondaryText: _secondaryText,
                        fillColor: _fieldFill,
                        borderColor: _fieldBorder,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LabeledField(
                        label: s.weightLabel,
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        hintText: 'e.g. 75',
                        errorText: _weightError,
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

          // ── Nutrition Goals ─────────────────────────────────────────────
          _SectionCard(
            backgroundColor: _cardBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  badgeBackground: widget.isDarkMode
                      ? const Color(0xFFA855F7).withValues(alpha: 0.18)
                      : const Color(0xFFF3E8FF),
                  icon: Icons.adjust,
                  iconColor: widget.isDarkMode
                      ? const Color(0xFFC084FC)
                      : const Color(0xFFA855F7),
                  title: s.nutritionGoals,
                  subtitle: s.setDietaryObjectives,
                  primaryText: _primaryText,
                  secondaryText: _secondaryText,
                ),
                const SizedBox(height: 10),
                Text(s.primaryGoalLabel, style: TextStyle(fontSize: 11, color: _secondaryText)),
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
                              ? (widget.isDarkMode
                                  ? const Color(0xFF059669).withValues(alpha: 0.22)
                                  : const Color(0xFFD1FAE5))
                              : (widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: const Color(0xFF059669), width: 1.5)
                              : null,
                          boxShadow: isSelected
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.06),
                                    blurRadius: widget.isDarkMode ? 8 : 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Text(
                          s.goalDisplay(goal),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? (widget.isDarkMode
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFF065F46))
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
                        label: s.dailyCalorieTarget,
                        controller: _calorieTargetController,
                        keyboardType: TextInputType.number,
                        errorText: _calorieError,
                        secondaryText: _secondaryText,
                        fillColor: _fieldFill,
                        borderColor: _fieldBorder,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LabeledField(
                        label: s.targetProtein,
                        controller: _proteinTargetController,
                        keyboardType: TextInputType.number,
                        errorText: _proteinError,
                        secondaryText: _secondaryText,
                        fillColor: _fieldFill,
                        borderColor: _fieldBorder,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(s.dietaryRestrictionsLabel, style: TextStyle(fontSize: 10.5, color: _secondaryText)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _kDietaryTags.map((tag) {
                    final isSelected = widget.selectedDietaryRestrictions.contains(tag);
                    return GestureDetector(
                      onTap: () => widget.onDietaryRestrictionToggled(tag, !isSelected),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (widget.isDarkMode
                                  ? const Color(0xFF10B981).withValues(alpha: 0.22)
                                  : const Color(0xFFD1FAE5))
                              : (widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white),
                          borderRadius: BorderRadius.circular(999),
                          border: isSelected
                              ? Border.all(color: const Color(0xFF10B981), width: 1.5)
                              : null,
                          boxShadow: isSelected
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.06),
                                    blurRadius: widget.isDarkMode ? 8 : 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Text(
                          s.dietaryTagDisplay(tag),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? (widget.isDarkMode
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFF065F46))
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

          // ── Security ────────────────────────────────────────────────────
          _SectionCard(
            backgroundColor: _cardBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBadge(
                      background: widget.isDarkMode
                          ? const Color(0xFFEA580C).withValues(alpha: 0.18)
                          : const Color(0xFFFFEDD5),
                      icon: Icons.lock_outline_rounded,
                      iconColor: widget.isDarkMode
                          ? const Color(0xFFFB923C)
                          : const Color(0xFFEA580C),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.securityLabel,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _primaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SecurityRow(
                  icon: Icons.key_rounded,
                  label: s.changePasswordLabel,
                  onTap: _showChangePasswordSheet,
                  primaryText: _primaryText,
                  secondaryText: _secondaryText,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 2),

          // ── Action buttons ──────────────────────────────────────────────
          SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _cancelChanges,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryText,
                      side: BorderSide.none,
                      backgroundColor: _cardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      s.cancel,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: (_isSaving || !_hasChanges) ? null : _saveChanges,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      s.saveChanges,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout, size: 16),
              label: Text(
                s.logOut,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.isDarkMode
                    ? const Color(0xFFF87171)
                    : const Color(0xFFDC2626),
                side: BorderSide.none,
                backgroundColor: widget.isDarkMode
                    ? const Color(0xFFDC2626).withValues(alpha: 0.15)
                    : const Color(0xFFFFF1F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          ],
          ),
        ),
      ),
        if (_hasChanges && !_actionButtonsVisible)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _cancelChanges,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryText,
                        backgroundColor: _cardBackground,
                        side: BorderSide.none,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 2,
                        shadowColor: Colors.black26,
                      ),
                      child: Text(
                        s.cancel,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF059669),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              s.saveChanges,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Language option chip ──────────────────────────────────────────────────────

class _LangOption extends StatelessWidget {
  const _LangOption({
    required this.label,
    required this.flag,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
  });

  final String label;
  final String flag;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode
                    ? const Color(0xFF059669).withValues(alpha: 0.2)
                    : const Color(0xFFD1FAE5))
                : (isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF059669) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? (isDarkMode ? const Color(0xFF4ADE80) : const Color(0xFF065F46))
                      : (isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF374151)),
                ),
              ),
            ],
          ),
        ),
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
        _IconBadge(background: badgeBackground, icon: icon, iconColor: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryText),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: secondaryText),
              ),
            ],
          ),
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
    this.errorText,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final Color secondaryText;
  final Color fillColor;
  final Color borderColor;
  final bool isDarkMode;
  final TextInputType? keyboardType;
  final String? hintText;
  final String? errorText;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: secondaryText)),
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.06),
                blurRadius: isDarkMode ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF374151),
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: fillColor,
              hintText: hintText,
              hintStyle: TextStyle(color: secondaryText, fontSize: 13),
              errorText: errorText,
              errorStyle: const TextStyle(fontSize: 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF059669)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, required this.backgroundColor});

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.38 : 0.05),
            blurRadius: isDarkMode ? 10 : 12,
            offset: const Offset(0, 3),
          ),
        ],
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
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Icon(icon, size: 13, color: iconColor),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primaryText,
    required this.secondaryText,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color primaryText;
  final Color secondaryText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: secondaryText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 13, color: primaryText)),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: secondaryText),
          ],
        ),
      ),
    );
  }
}

// ── Change Password Sheet ─────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({
    required this.isDarkMode,
    required this.cardBackground,
    required this.cardBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.fieldFill,
    required this.fieldBorder,
  });

  final bool isDarkMode;
  final Color cardBackground;
  final Color cardBorder;
  final Color primaryText;
  final Color secondaryText;
  final Color fieldFill;
  final Color fieldBorder;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = S.of(context);
    String? curErr, newErr, confErr;
    if (_currentCtrl.text.isEmpty) curErr = s.enterCurrentPassword;
    if (_newCtrl.text.length < 6) newErr = s.mustBeAtLeast6;
    if (_confirmCtrl.text != _newCtrl.text) confErr = s.passwordsDoNotMatch;

    setState(() {
      _currentError = curErr;
      _newError = newErr;
      _confirmError = confErr;
    });
    if (curErr != null || newErr != null || confErr != null) return;

    setState(() => _isSaving = true);
    try {
      await AuthService().changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessToast(context, s.passwordUpdated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showErrorToast(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showErrorToast(context, S.of(context).unableToUpdatePassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: widget.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: widget.fieldBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text(
            s.changePasswordTitle,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: widget.primaryText),
          ),
          const SizedBox(height: 4),
          Text(
            s.chooseStrongPassword,
            style: TextStyle(fontSize: 12, color: widget.secondaryText),
          ),
          const SizedBox(height: 20),
          _PwField(
            controller: _currentCtrl,
            label: s.currentPassword,
            obscure: _obscureCurrent,
            errorText: _currentError,
            secondaryText: widget.secondaryText,
            fillColor: widget.fieldFill,
            borderColor: widget.fieldBorder,
            isDarkMode: widget.isDarkMode,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
            onChanged: (_) => setState(() => _currentError = null),
          ),
          const SizedBox(height: 12),
          _PwField(
            controller: _newCtrl,
            label: s.newPassword,
            obscure: _obscureNew,
            errorText: _newError,
            secondaryText: widget.secondaryText,
            fillColor: widget.fieldFill,
            borderColor: widget.fieldBorder,
            isDarkMode: widget.isDarkMode,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
            onChanged: (_) => setState(() => _newError = null),
          ),
          const SizedBox(height: 12),
          _PwField(
            controller: _confirmCtrl,
            label: s.confirmNewPassword,
            obscure: _obscureConfirm,
            errorText: _confirmError,
            secondaryText: widget.secondaryText,
            fillColor: widget.fieldFill,
            borderColor: widget.fieldBorder,
            isDarkMode: widget.isDarkMode,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            onChanged: (_) => setState(() => _confirmError = null),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: widget.primaryText,
                    side: BorderSide.none,
                    backgroundColor: widget.isDarkMode
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF3F4F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(s.cancel, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(s.updateLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PwField extends StatelessWidget {
  const _PwField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
    required this.secondaryText,
    required this.fillColor,
    required this.borderColor,
    required this.isDarkMode,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final Color secondaryText;
  final Color fillColor;
  final Color borderColor;
  final bool isDarkMode;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: secondaryText),
        ),
        const SizedBox(height: 5),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.06),
                blurRadius: isDarkMode ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF374151),
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: fillColor,
              errorText: errorText,
              errorStyle: const TextStyle(fontSize: 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 17,
                  color: secondaryText,
                ),
                onPressed: onToggle,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF059669)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
