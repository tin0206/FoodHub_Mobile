import 'package:flutter/material.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_user_detail_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_user_form_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _query = '';
  String _filter = 'All';

  List<AdminUserData> get _filtered {
    var list = kAdminUsers.where((u) {
      if (_filter == 'Admin') return u.role == 'admin';
      if (_filter == 'Active') return u.isActive;
      if (_filter == 'Inactive') return !u.isActive;
      return true;
    }).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.username.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final textPrimary =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;
    final list = _filtered;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Users',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kAdminAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${kAdminUsers.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kAdminAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.3 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v.trim()),
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, username…',
                        hintStyle:
                            TextStyle(color: textSub, fontSize: 13),
                        prefixIcon:
                            Icon(Icons.search, color: textSub, size: 20),
                        filled: true,
                        fillColor: cardBg,
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
                          borderSide:
                              const BorderSide(color: kAdminAccent),
                        ),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          ['All', 'Admin', 'Active', 'Inactive'].map((f) {
                        final sel = _filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: sel
                                    ? kAdminAccent
                                    : (isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: isDark ? 0.25 : 0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white : textSub,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('No users found',
                          style: TextStyle(color: textSub)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final u = list[i];
                        return GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminUserDetailScreen(
                                user: u,
                                isDarkMode: isDark,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                      alpha: isDark ? 0.3 : 0.06),
                                  blurRadius: isDark ? 10 : 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                AdminAvatarCircle(
                                    name: u.fullName,
                                    size: 42,
                                    fontSize: 15),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              u.fullName,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: textPrimary,
                                              ),
                                            ),
                                          ),
                                          AdminRoleBadge(role: u.role),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(u.email,
                                          style: TextStyle(
                                              fontSize: 11.5,
                                              color: textSub)),
                                      const SizedBox(height: 2),
                                      Text('@${u.username}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: textSub.withValues(
                                                  alpha: 0.7))),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${u.recipeCount} recipes',
                                      style: TextStyle(
                                          fontSize: 11, color: textSub),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: u.isActive
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFF43F5E),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          u.isActive
                                              ? 'Active'
                                              : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: u.isActive
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFF43F5E),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded,
                                    size: 18, color: textSub),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),

        // ── Add User FAB ─────────────────────────────────────────────
        Positioned(
          right: 16,
          bottom: 16,
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AdminUserFormScreen(isDarkMode: isDark),
              ),
            ),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kAdminAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kAdminAccent.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.person_add_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class AdminAvatarCircle extends StatelessWidget {
  const AdminAvatarCircle({
    super.key,
    required this.name,
    required this.size,
    required this.fontSize,
  });

  final String name;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final initials =
        name.trim().split(' ').take(2).map((w) => w[0]).join();
    final hue =
        (name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    final color = HSLColor.fromAHSL(1, hue, 0.55, 0.45).toColor();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }
}

class AdminRoleBadge extends StatelessWidget {
  const AdminRoleBadge({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin
            ? kAdminAccent.withValues(alpha: 0.13)
            : const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'User',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isAdmin ? kAdminAccent : const Color(0xFF10B981),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class AdminUserData {
  const AdminUserData({
    required this.id,
    required this.fullName,
    required this.email,
    required this.username,
    required this.role,
    required this.isActive,
    required this.recipeCount,
    required this.savedCount,
    required this.createdAt,
    this.age,
    this.weight,
    this.calorieTarget,
    this.proteinTarget,
    this.dietaryRestrictions = const [],
    this.primaryGoal,
  });

  final int id;
  final String fullName;
  final String email;
  final String username;
  final String role;
  final bool isActive;
  final int recipeCount;
  final int savedCount;
  final String createdAt;
  final int? age;
  final double? weight;
  final int? calorieTarget;
  final int? proteinTarget;
  final List<String> dietaryRestrictions;
  final String? primaryGoal;
}

const kAdminUsers = [
  AdminUserData(
    id: 1,
    fullName: 'Trung Tin',
    email: 'tin@foodhub.app',
    username: 'trungtin',
    role: 'admin',
    isActive: true,
    recipeCount: 12,
    savedCount: 34,
    createdAt: 'Jan 15, 2024',
    age: 20,
    weight: 65.0,
    calorieTarget: 2200,
    proteinTarget: 150,
    dietaryRestrictions: ['High Protein'],
    primaryGoal: 'Build Muscle',
  ),
  AdminUserData(
    id: 2,
    fullName: 'Minh Duc',
    email: 'duc@gmail.com',
    username: 'minhduc',
    role: 'user',
    isActive: true,
    recipeCount: 5,
    savedCount: 18,
    createdAt: 'Feb 20, 2024',
    age: 25,
    weight: 70.0,
    calorieTarget: 2000,
    proteinTarget: 120,
    dietaryRestrictions: ['Vegan'],
    primaryGoal: 'Lose Weight',
  ),
  AdminUserData(
    id: 3,
    fullName: 'Thu Hang',
    email: 'hang@gmail.com',
    username: 'thuhang',
    role: 'user',
    isActive: true,
    recipeCount: 8,
    savedCount: 42,
    createdAt: 'Mar 10, 2024',
    age: 28,
    weight: 55.0,
    calorieTarget: 1800,
    proteinTarget: 90,
    dietaryRestrictions: ['Vegan', 'Gluten Free'],
    primaryGoal: 'Balanced Nutrition',
  ),
  AdminUserData(
    id: 4,
    fullName: 'Van Long',
    email: 'long@gmail.com',
    username: 'vanlong',
    role: 'user',
    isActive: false,
    recipeCount: 3,
    savedCount: 7,
    createdAt: 'Apr 5, 2024',
    age: 32,
    weight: 80.0,
    calorieTarget: null,
    proteinTarget: null,
    dietaryRestrictions: [],
    primaryGoal: null,
  ),
  AdminUserData(
    id: 5,
    fullName: 'Phuong Thao',
    email: 'thao@gmail.com',
    username: 'phuongthao',
    role: 'user',
    isActive: true,
    recipeCount: 15,
    savedCount: 61,
    createdAt: 'Apr 22, 2024',
    age: 23,
    weight: 52.0,
    calorieTarget: 1600,
    proteinTarget: 80,
    dietaryRestrictions: ['Vegan', 'Healthy'],
    primaryGoal: 'Improve Health',
  ),
  AdminUserData(
    id: 6,
    fullName: 'Bao Ngoc',
    email: 'ngoc@gmail.com',
    username: 'baongoc',
    role: 'user',
    isActive: true,
    recipeCount: 2,
    savedCount: 9,
    createdAt: 'May 1, 2024',
    age: 21,
    weight: 58.0,
    calorieTarget: 1900,
    proteinTarget: 100,
    dietaryRestrictions: ['Keto'],
    primaryGoal: 'Lose Weight',
  ),
  AdminUserData(
    id: 7,
    fullName: 'Thanh Nam',
    email: 'nam@gmail.com',
    username: 'thanhnam',
    role: 'user',
    isActive: false,
    recipeCount: 0,
    savedCount: 0,
    createdAt: 'May 10, 2024',
    age: null,
    weight: null,
    calorieTarget: null,
    proteinTarget: null,
    dietaryRestrictions: [],
    primaryGoal: null,
  ),
  AdminUserData(
    id: 8,
    fullName: 'Kieu Anh',
    email: 'anh@gmail.com',
    username: 'kieuanh',
    role: 'user',
    isActive: true,
    recipeCount: 7,
    savedCount: 29,
    createdAt: 'Jun 12, 2024',
    age: 26,
    weight: 61.0,
    calorieTarget: 2100,
    proteinTarget: 130,
    dietaryRestrictions: ['High Protein', 'Breakfast'],
    primaryGoal: 'Build Muscle',
  ),
];
