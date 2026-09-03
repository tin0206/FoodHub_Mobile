import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/screens/main_shell_screen.dart';
import 'package:foodhub_mobile/screens/profile_screen.dart' show kDietaryTags, kPrimaryGoals;
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/auth_service.dart';
import 'package:foodhub_mobile/widgets/favorite_toast.dart';

const _kTotalSteps = 3;

bool _isPositiveNumber(String v) {
  if (v.trim().isEmpty) return true;
  final n = num.tryParse(v.trim());
  return n != null && n > 0;
}

/// Post sign-up survey.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _userService = UserService();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();

  int _step = 1;
  String? _ageError;
  String? _weightError;
  String _primaryGoal = '';
  final Set<String> _dietaryRestrictions = {};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defaults to English regardless of any stored preference; the user can
    // switch to Vietnamese with the toggle in the header below.
    LangScope.current.value = 'en';
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _goHome([UserModel? updated]) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainShellScreen(initialUser: updated ?? widget.user),
      ),
    );
  }

  // MainShellScreen re-seeds the global language from the user's saved
  // preference on init, which would otherwise silently undo a language
  // switch made here (via the header toggle) the moment the survey is
  // skipped or finished. Persist it first so it sticks.
  Future<void> _skip() async {
    var user = widget.user;
    final lang = LangScope.current.value;
    if (lang != (user.language ?? 'en')) {
      try {
        user = await _userService.updateMe({'language': lang});
      } catch (_) {
        // Best-effort — still let them into the app.
      }
    }
    if (!mounted) return;
    _goHome(user);
  }

  bool _validateAboutStep() {
    final s = S.of(context);
    final ageErr = _isPositiveNumber(_ageController.text)
        ? null
        : s.mustBePositiveNumber;
    final weightErr = _isPositiveNumber(_weightController.text)
        ? null
        : s.mustBePositiveNumber;
    setState(() {
      _ageError = ageErr;
      _weightError = weightErr;
    });
    return ageErr == null && weightErr == null;
  }

  void _toggleDietary(String tag) {
    setState(() {
      if (_dietaryRestrictions.contains(tag)) {
        _dietaryRestrictions.remove(tag);
      } else {
        _dietaryRestrictions.add(tag);
      }
    });
  }

  void _handleNext() {
    if (_step == 1 && !_validateAboutStep()) return;
    setState(() => _step = (_step + 1).clamp(1, _kTotalSteps));
  }

  void _handleBack() {
    setState(() => _step = (_step - 1).clamp(1, _kTotalSteps));
  }

  Future<void> _handleFinish() async {
    if (!_validateAboutStep()) {
      setState(() => _step = 1);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final age = _ageController.text.trim();
      final weight = _weightController.text.trim();
      final updated = await _userService.updateMe(
        widget.user.toProfileUpdateJson(
          age: age.isNotEmpty ? int.tryParse(age) : null,
          weight: weight.isNotEmpty ? double.tryParse(weight) : null,
          primaryGoal: _primaryGoal,
          dietaryRestrictions: _dietaryRestrictions.toList(),
          language: LangScope.current.value,
        ),
      );
      if (!mounted) return;
      _goHome(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorToast(context, e.message);
    } catch (_) {
      if (!mounted) return;
      final s = S.of(context);
      setState(() => _saving = false);
      showErrorToast(context, s.unableToSaveProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF059669),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        fit: BoxFit.contain,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'FoodHub',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  _LangSwitch(current: s.lang),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: _saving ? null : _skip,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: Text(s.onboardingSkip),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.onboardingWelcomeTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.onboardingWelcomeSubtitle,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 18),

                    // ── Progress ─────────────────────────────────────────
                    Row(
                      children: List.generate(_kTotalSteps, (i) {
                        final active = i < _step;
                        return Expanded(
                          child: Container(
                            height: 5,
                            margin: EdgeInsets.only(
                              right: i == _kTotalSteps - 1 ? 0 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.onboardingStepOf(_step, _kTotalSteps),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12.5),
                        ),
                      ),
                    ],

                    if (_step == 1) _AboutStep(
                      title: s.onboardingStepAboutTitle,
                      subtitle: s.onboardingStepAboutSubtitle,
                      ageLabel: s.ageLabel,
                      weightLabel: s.weightLabel,
                      ageController: _ageController,
                      weightController: _weightController,
                      ageError: _ageError,
                      weightError: _weightError,
                      onAgeChanged: () {
                        if (_ageError != null) setState(() => _ageError = null);
                      },
                      onWeightChanged: () {
                        if (_weightError != null) setState(() => _weightError = null);
                      },
                    ),
                    if (_step == 2) _GoalStep(
                      title: s.onboardingStepGoalTitle,
                      subtitle: s.onboardingStepGoalSubtitle,
                      selected: _primaryGoal,
                      onSelect: (goal) => setState(
                        () => _primaryGoal = _primaryGoal == goal ? '' : goal,
                      ),
                      display: s.goalDisplay,
                    ),
                    if (_step == 3) _DietaryStep(
                      title: s.onboardingStepDietaryTitle,
                      subtitle: s.onboardingStepDietarySubtitle,
                      selected: _dietaryRestrictions,
                      onToggle: _toggleDietary,
                      display: s.dietaryTagDisplay,
                    ),

                    const SizedBox(height: 18),
                    Text(
                      s.onboardingChangeLaterHint,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        if (_step > 1) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving ? null : _handleBack,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                foregroundColor: const Color(0xFF374151),
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: Text(s.onboardingBack),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          flex: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: _saving
                                  ? null
                                  : const LinearGradient(
                                      colors: [Color(0xFF059669), Color(0xFF047857)],
                                    ),
                              color: _saving ? const Color(0xFFD1D5DB) : null,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: _saving
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF059669).withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: ElevatedButton(
                              onPressed: _saving
                                  ? null
                                  : (_step < _kTotalSteps ? _handleNext : _handleFinish),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _step < _kTotalSteps
                                          ? s.onboardingContinue
                                          : s.onboardingFinish,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact EN/VI toggle for the onboarding header — lets the user switch
/// off the English default without leaving the survey.
class _LangSwitch extends StatelessWidget {
  const _LangSwitch({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangSwitchOption(
            flag: '🇺🇸',
            selected: current == 'en',
            onTap: () => LangScope.current.value = 'en',
          ),
          _LangSwitchOption(
            flag: '🇻🇳',
            selected: current == 'vi',
            onTap: () => LangScope.current.value = 'vi',
          ),
        ],
      ),
    );
  }
}

class _LangSwitchOption extends StatelessWidget {
  const _LangSwitchOption({
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha: 0.9) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(flag, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF059669)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _AboutStep extends StatelessWidget {
  const _AboutStep({
    required this.title,
    required this.subtitle,
    required this.ageLabel,
    required this.weightLabel,
    required this.ageController,
    required this.weightController,
    required this.ageError,
    required this.weightError,
    required this.onAgeChanged,
    required this.onWeightChanged,
  });

  final String title;
  final String subtitle;
  final String ageLabel;
  final String weightLabel;
  final TextEditingController ageController;
  final TextEditingController weightController;
  final String? ageError;
  final String? weightError;
  final VoidCallback onAgeChanged;
  final VoidCallback onWeightChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(icon: Icons.calendar_today_outlined, title: title, subtitle: subtitle),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _OnboardingField(
                label: ageLabel,
                icon: Icons.calendar_today_outlined,
                controller: ageController,
                hint: '28',
                keyboardType: TextInputType.number,
                errorText: ageError,
                onChanged: onAgeChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OnboardingField(
                label: weightLabel,
                icon: Icons.monitor_weight_outlined,
                controller: weightController,
                hint: '60',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                errorText: weightError,
                onChanged: onWeightChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OnboardingField extends StatelessWidget {
  const _OnboardingField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final VoidCallback onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 10.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onSelect,
    required this.display,
  });

  final String title;
  final String subtitle;
  final String selected;
  final ValueChanged<String> onSelect;
  final String Function(String) display;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(icon: Icons.track_changes_outlined, title: title, subtitle: subtitle),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.6,
          children: kPrimaryGoals.map((goal) {
            final active = selected == goal;
            return GestureDetector(
              onTap: () => onSelect(goal),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFD1FAE5) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  display(goal),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? const Color(0xFF065F46) : const Color(0xFF374151),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DietaryStep extends StatelessWidget {
  const _DietaryStep({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onToggle,
    required this.display,
  });

  final String title;
  final String subtitle;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String Function(String) display;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(icon: Icons.eco_outlined, title: title, subtitle: subtitle),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kDietaryTags.map((tag) {
            final active = selected.contains(tag);
            return GestureDetector(
              onTap: () => onToggle(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFD1FAE5) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  display(tag),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? const Color(0xFF065F46) : const Color(0xFF374151),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
