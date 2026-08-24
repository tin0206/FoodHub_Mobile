import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foodhub_mobile/models/admin.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_user_detail_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_user_form_screen.dart';
import 'package:foodhub_mobile/services/admin_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';

const _kPageSize = 20;

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _admin = AdminService();
  List<UserModel>? _users;
  bool _loading = true;
  String? _error;

  String _query = '';
  String _debouncedQuery = '';
  Timer? _debounce;
  String _filter = 'All'; // All | Admin | Active | Inactive
  int _page = 0;
  bool _hasNext = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      setState(() {
        _debouncedQuery = v.trim();
        _page = 0;
      });
      _load();
    });
  }

  void _setFilter(String f) {
    setState(() {
      _filter = f;
      _page = 0;
    });
    _load();
  }

  String? get _roleParam => _filter == 'Admin' ? 'admin' : null;
  bool? get _activeParam {
    if (_filter == 'Active') return true;
    if (_filter == 'Inactive') return false;
    return null;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_debouncedQuery.isNotEmpty) {
        var raw = await _admin.listUsers(
          skip: 0,
          limit: 200,
          q: _debouncedQuery,
          role: _roleParam,
          active: _activeParam,
        );
        final q = _debouncedQuery.toLowerCase();
        raw = raw.where((u) {
          return (u.fullName?.toLowerCase().contains(q) ?? false) ||
              u.email.toLowerCase().contains(q) ||
              u.username.toLowerCase().contains(q);
        }).toList();
        final start = _page * _kPageSize;
        final hasNext = raw.length > start + _kPageSize;
        final slice = raw.skip(start).take(_kPageSize).toList();
        if (!mounted) return;
        setState(() {
          _users = slice;
          _hasNext = hasNext;
          _loading = false;
        });
        return;
      }

      final raw = await _admin.listUsers(
        skip: _page * _kPageSize,
        limit: _kPageSize + 1,
        role: _roleParam,
        active: _activeParam,
      );
      if (!mounted) return;
      setState(() {
        _hasNext = raw.length > _kPageSize;
        _users = raw.take(_kPageSize).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;
    final list = _users ?? [];
    final rangeStart = _page * _kPageSize + 1;
    final rangeEnd = _page * _kPageSize + list.length;

    return Stack(
      children: [
        Column(
          children: [
        // ── Header ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Users',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                  ),
                  const SizedBox(width: 8),
                  if (_users != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kAdminAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$rangeStart–$rangeEnd${_hasNext ? '+' : ''}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kAdminAccent),
                      ),
                    ),
                  const Spacer(),
                  // Refresh button
                  GestureDetector(
                    onTap: _loading ? null : _load,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: kAdminAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _loading
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: kAdminAccent),
                                )
                              : const Icon(Icons.refresh_rounded, size: 13, color: kAdminAccent),
                          const SizedBox(width: 5),
                          const Text(
                            'Refresh',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kAdminAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (v) {
                    setState(() => _query = v);
                    _onQueryChanged(v);
                  },
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, username…',
                    hintStyle: TextStyle(color: textSub, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: textSub, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, size: 18, color: textSub),
                            onPressed: () {
                              setState(() => _query = '');
                              _onQueryChanged('');
                            },
                          )
                        : null,
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
                      borderSide: const BorderSide(color: kAdminAccent),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Admin', 'Active', 'Inactive'].map((f) {
                    final sel = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: GestureDetector(
                        onTap: () => _setFilter(f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel
                                ? kAdminAccent
                                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
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

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFF43F5E))),
                ),
            ],
          ),
        ),

        // ── List ────────────────────────────────────────────────────
        Expanded(
          child: _loading && _users == null
              ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: kAdminAccent),
                )
              : RefreshIndicator(
                  onRefresh: () => _load(),
                  color: kAdminAccent,
                  child: list.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: 300,
                              child: Center(
                                child: Text(
                                  _debouncedQuery.isNotEmpty
                                      ? 'No users match "$_debouncedQuery"'
                                      : 'No users found',
                                  style: TextStyle(fontSize: 13, color: textSub),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
                          children: [
                            Container(
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Column(
                                  children: list.asMap().entries.map((e) {
                                    return _UserRow(
                                      user: e.value,
                                      isDark: isDark,
                                      showTopDivider: e.key > 0,
                                      isFirst: e.key == 0,
                                      isLast: e.key == list.length - 1,
                                      onTap: () async {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => AdminUserDetailScreen(
                                              userId: e.value.id,
                                              isDarkMode: isDark,
                                            ),
                                          ),
                                        );
                                        _load();
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            _PaginationFooter(
                              isDark: isDark,
                              page: _page,
                              hasNext: _hasNext,
                              loading: _loading,
                              onPrev: _page > 0 ? () {
                                setState(() => _page--);
                                _load();
                              } : null,
                              onNext: () {
                                setState(() => _page++);
                                _load();
                              },
                            ),
                          ],
                        ),
                ),
        ),
          ],
        ),

        // ── Add User FAB ────────────────────────────────────────────────
        Positioned(
          right: 16,
          bottom: 16,
          child: GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminUserFormScreen(isDarkMode: isDark),
                ),
              );
              _load();
            },
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
              child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

// ── User row (inside grouped card) ────────────────────────────────────────────

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.isDark,
    required this.showTopDivider,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final UserModel user;
  final bool isDark;
  final bool showTopDivider;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final dividerColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);
    final name = user.fullName ?? user.username;
    final avatarColor = Color(adminAvatarColorInt(name, isDark: isDark));

    return Column(
      children: [
        if (showTopDivider) Divider(height: 1, color: dividerColor),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(14) : Radius.zero,
            bottom: isLast ? const Radius.circular(14) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: avatarColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      adminAvatarInitials(name),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: avatarColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (user.role == 'admin')
                            _RoleBadge(label: 'Admin', color: kAdminAccent)
                          else
                            const _RoleBadge(label: 'User', color: Color(0xFF10B981)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 11.5, color: textSub),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: user.isActive ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 18, color: textSub),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ── Pagination footer ─────────────────────────────────────────────────────────

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.isDark,
    required this.page,
    required this.hasNext,
    required this.loading,
    required this.onPrev,
    required this.onNext,
  });

  final bool isDark;
  final int page;
  final bool hasNext;
  final bool loading;
  final VoidCallback? onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (page > 0)
            OutlinedButton.icon(
              onPressed: loading ? null : onPrev,
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 13),
              label: const Text('Prev'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kAdminAccent,
                side: BorderSide(color: kAdminAccent.withValues(alpha: 0.4)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          if (page > 0) const SizedBox(width: 8),
          Text('Page ${page + 1}', style: TextStyle(fontSize: 12, color: textSub)),
          if (hasNext) const SizedBox(width: 8),
          if (hasNext)
            OutlinedButton.icon(
              onPressed: loading ? null : onNext,
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
              label: const Text('Next'),
              iconAlignment: IconAlignment.end,
              style: OutlinedButton.styleFrom(
                foregroundColor: kAdminAccent,
                side: BorderSide(color: kAdminAccent.withValues(alpha: 0.4)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }
}
