import 'package:flutter/material.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/services/admin_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';

class AdminUserFormScreen extends StatefulWidget {
  const AdminUserFormScreen({
    super.key,
    required this.isDarkMode,
    this.user,
  });

  final bool isDarkMode;
  final UserModel? user;

  bool get isEditing => user != null;

  @override
  State<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<AdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _calorieCtrl;
  late final TextEditingController _proteinCtrl;

  late String _role;
  late bool _isActive;
  late Set<String> _dietaryRestrictions;
  late String? _primaryGoal;
  bool _isSaving = false;
  bool _obscurePassword = false;
  String? _notice;

  static const _goals = [
    'Lose Weight',
    'Build Muscle',
    'Balanced Nutrition',
    'Improve Health',
    'Maintain Weight',
  ];

  static const _dietaryOptions = [
    'Vegan', 'Vegetarian', 'Gluten Free', 'High Protein',
    'Keto', 'Pescetarian', 'Healthy', 'Breakfast',
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _passwordCtrl = TextEditingController(text: widget.isEditing ? '' : '123456');
    _fullNameCtrl = TextEditingController(text: u?.fullName ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _usernameCtrl = TextEditingController(text: u?.username ?? '');
    _ageCtrl = TextEditingController(
        text: u?.age != null ? '${u!.age}' : '');
    _weightCtrl = TextEditingController(
        text: u?.weight != null ? '${u!.weight}' : '');
    _calorieCtrl = TextEditingController(
        text: u?.calorieTarget != null ? '${u!.calorieTarget}' : '');
    _proteinCtrl = TextEditingController(
        text: u?.proteinTarget != null ? '${u!.proteinTarget}' : '');
    _role = u?.role ?? 'user';
    _isActive = u?.isActive ?? true;
    _dietaryRestrictions = {...?u?.dietaryRestrictions};
    _primaryGoal = u?.primaryGoal;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _calorieCtrl.dispose();
    _proteinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final admin = AdminService();
      final fields = <String, dynamic>{
        'full_name': _fullNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'role': _role,
        'is_active': _isActive,
        if (_ageCtrl.text.trim().isNotEmpty)
          'age': int.parse(_ageCtrl.text.trim()),
        if (_weightCtrl.text.trim().isNotEmpty)
          'weight': double.parse(_weightCtrl.text.trim()),
        if (_calorieCtrl.text.trim().isNotEmpty)
          'calorie_target': int.parse(_calorieCtrl.text.trim()),
        if (_proteinCtrl.text.trim().isNotEmpty)
          'protein_target': int.parse(_proteinCtrl.text.trim()),
        if (_primaryGoal != null) 'primary_goal': _primaryGoal,
        'dietary_restrictions': _dietaryRestrictions.toList(),
      };
      if (widget.isEditing) {
        await admin.updateUser(widget.user!.id, fields);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        fields['password'] = _passwordCtrl.text;
        await admin.createUser(fields);
        if (!mounted) return;
        _fullNameCtrl.clear();
        _emailCtrl.clear();
        _usernameCtrl.clear();
        _passwordCtrl.text = '123456';
        _ageCtrl.clear();
        _weightCtrl.clear();
        _calorieCtrl.clear();
        _proteinCtrl.clear();
        setState(() {
          _isSaving = false;
          _role = 'user';
          _isActive = true;
          _dietaryRestrictions = {};
          _primaryGoal = null;
          _notice = 'User created successfully.';
        });
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : '$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;
    final textPrimary =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final hintColor =
        isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);
    final divColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);

    InputDecoration fieldDec(String label, {IconData? icon, Widget? suffix}) =>
        InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13, color: textSub),
          hintStyle: TextStyle(color: hintColor),
          prefixIcon: icon != null
              ? Icon(icon, size: 18, color: textSub)
              : null,
          suffixIcon: suffix,
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: isDark
                ? BorderSide.none
                : const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: kAdminAccent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFFF43F5E)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(
                color: Color(0xFFF43F5E), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textSub),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEditing ? 'Edit User' : 'Add User',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: divColor),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // ── Basic Info ─────────────────────────────────────────────
            _FormSection(
              title: 'Account Info',
              icon: Icons.badge_rounded,
              isDark: isDark,
              cardBg: cardBg,
              textPrimary: textPrimary,
              children: [
                TextFormField(
                  controller: _fullNameCtrl,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: fieldDec('Full Name', icon: Icons.person_rounded),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailCtrl,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  keyboardType: TextInputType.emailAddress,
                  decoration: fieldDec('Email', icon: Icons.email_rounded),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _usernameCtrl,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: fieldDec('Username',
                      icon: Icons.alternate_email_rounded),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                if (!widget.isEditing) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    decoration: fieldDec(
                      'Password',
                      icon: Icons.lock_rounded,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                          color: textSub,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (widget.isEditing) return null;
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // ── Role & Status ──────────────────────────────────────────
            _FormSection(
              title: 'Role & Status',
              icon: Icons.admin_panel_settings_rounded,
              isDark: isDark,
              cardBg: cardBg,
              textPrimary: textPrimary,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Role',
                              style:
                                  TextStyle(fontSize: 12, color: textSub)),
                          const SizedBox(height: 6),
                          Row(
                            children: ['user', 'admin'].map((r) {
                              final sel = _role == r;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _role = r),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? kAdminAccent
                                          : (isDark
                                              ? const Color(0xFF1E1E1E)
                                              : const Color(0xFFF3F4F6)),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      r[0].toUpperCase() + r.substring(1),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: sel
                                            ? Colors.white
                                            : textSub,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Active',
                            style:
                                TextStyle(fontSize: 12, color: textSub)),
                        const SizedBox(height: 4),
                        Switch(
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                          activeThumbColor: const Color(0xFF10B981),
                          activeTrackColor:
                              const Color(0xFF10B981).withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Nutrition Goals ────────────────────────────────────────
            _FormSection(
              title: 'Nutrition Goals',
              icon: Icons.local_fire_department_rounded,
              isDark: isDark,
              cardBg: cardBg,
              textPrimary: textPrimary,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageCtrl,
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        keyboardType: TextInputType.number,
                        decoration:
                            fieldDec('Age', icon: Icons.cake_rounded),
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            if (int.tryParse(v) == null) {
                              return 'Invalid';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _weightCtrl,
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: fieldDec('Weight (kg)',
                            icon: Icons.monitor_weight_rounded),
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            if (double.tryParse(v) == null) {
                              return 'Invalid';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _calorieCtrl,
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        keyboardType: TextInputType.number,
                        decoration: fieldDec('Calorie Target',
                            icon: Icons.local_fire_department_outlined),
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            if (int.tryParse(v) == null) return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _proteinCtrl,
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        keyboardType: TextInputType.number,
                        decoration: fieldDec('Protein Target (g)',
                            icon: Icons.fitness_center_rounded),
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            if (int.tryParse(v) == null) return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Primary Goal',
                    style: TextStyle(fontSize: 12, color: textSub)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: _goals.map((g) {
                    final sel = _primaryGoal == g;
                    return GestureDetector(
                      onTap: () => setState(() =>
                          _primaryGoal = sel ? null : g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? kAdminAccent
                              : (isDark
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          g,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : textSub,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Dietary Restrictions ───────────────────────────────────
            _FormSection(
              title: 'Dietary Restrictions',
              icon: Icons.eco_rounded,
              isDark: isDark,
              cardBg: cardBg,
              textPrimary: textPrimary,
              children: [
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: _dietaryOptions.map((d) {
                    final sel = _dietaryRestrictions.contains(d);
                    return GestureDetector(
                      onTap: () => setState(() {
                        sel
                            ? _dietaryRestrictions.remove(d)
                            : _dietaryRestrictions.add(d);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? kAdminAccent.withValues(alpha: 0.15)
                              : (isDark
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(8),
                          border: sel
                              ? Border.all(
                                  color: kAdminAccent.withValues(alpha: 0.5),
                                  width: 1)
                              : null,
                        ),
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                sel ? kAdminAccent : textSub,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Success notice ─────────────────────────────────────────
            if (_notice != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 15, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _notice!,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _notice = null),
                      child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),

            // ── Submit ─────────────────────────────────────────────────
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: kAdminAccent,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      widget.isEditing ? 'Save Changes' : 'Create User',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.children,
  });

  final String title;
  final IconData icon;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: isDark ? 10 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: kAdminAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: kAdminAccent),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
