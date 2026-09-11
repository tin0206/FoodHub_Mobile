import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/feedback.dart';
import 'package:foodhub_mobile/models/admin.dart';
import 'package:foodhub_mobile/screens/admin/admin_feedback_detail_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/services/admin_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/feedback_service.dart';

const _kPageSize = 20;

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  final _admin = AdminService();
  List<AdminFeedbackModel>? _items;
  bool _loading = true;
  String? _error;

  String _statusFilter = '';   // '' = All
  String _categoryFilter = ''; // '' = All
  int _page = 0;
  bool _hasNext = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _setStatus(String v) {
    setState(() { _statusFilter = v; _page = 0; });
    _load();
  }

  void _setCategory(String v) {
    setState(() { _categoryFilter = v; _page = 0; });
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await _admin.listFeedback(
        skip: _page * _kPageSize,
        limit: _kPageSize + 1,
        status: _statusFilter.isEmpty ? null : _statusFilter,
        category: _categoryFilter.isEmpty ? null : _categoryFilter,
      );
      if (!mounted) return;
      setState(() {
        _hasNext = raw.length > _kPageSize;
        _items = raw.take(_kPageSize).toList();
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
    final s = S.of(context);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC);

    final statuses = ['', 'open', 'in_progress', 'resolved'];
    final categories = ['', ...FeedbackService.categories];

    return Container(
      color: bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(s.adminFeedbackTitle,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary)),
                    const SizedBox(width: 8),
                    if (_items != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kAdminAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_items!.length}${_hasNext ? '+' : ''}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kAdminAccent),
                        ),
                      ),
                    const Spacer(),
                    if (_loading)
                      const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: kAdminAccent),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Status filter
                Text('Status',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSub)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: statuses.map((st) {
                      final label = st.isEmpty
                          ? 'All'
                          : s.feedbackStatusDisplay(st);
                      final sel = _statusFilter == st;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _FilterChip(
                          label: label,
                          selected: sel,
                          isDark: isDark,
                          onTap: () => _setStatus(st),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Category filter
                Text('Category',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSub)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final label = cat.isEmpty
                          ? 'All'
                          : s.feedbackCategoryDisplay(cat);
                      final sel = _categoryFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _FilterChip(
                          label: label,
                          selected: sel,
                          isDark: isDark,
                          onTap: () => _setCategory(cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // List
          Expanded(
            child: _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!,
                            style: TextStyle(fontSize: 12, color: textSub)),
                        TextButton(
                          onPressed: _load,
                          child: Text(s.retry),
                        ),
                      ],
                    ),
                  )
                : _items == null
                    ? const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: kAdminAccent),
                      )
                    : _items!.isEmpty
                        ? Center(
                            child: Text(s.feedbackNoneYet,
                                style: TextStyle(fontSize: 13, color: textSub)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
                            itemCount: _items!.length + (_hasNext ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              if (i == _items!.length) {
                                return _PaginationRow(
                                  page: _page,
                                  hasNext: _hasNext,
                                  isDark: isDark,
                                  textSub: textSub,
                                  onPrev: _page > 0
                                      ? () {
                                          setState(() => _page--);
                                          _load();
                                        }
                                      : null,
                                  onNext: () {
                                    setState(() => _page++);
                                    _load();
                                  },
                                );
                              }
                              final fb = _items![i];
                              return _FeedbackRow(
                                feedback: fb,
                                isDark: isDark,
                                cardBg: cardBg,
                                textPrimary: textPrimary,
                                textSub: textSub,
                                s: s,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AdminFeedbackDetailScreen(
                                        feedbackId: fb.id,
                                        isDarkMode: isDark,
                                      ),
                                    ),
                                  );
                                  _load();
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({
    required this.feedback,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSub,
    required this.s,
    required this.onTap,
  });

  final AdminFeedbackModel feedback;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSub;
  final S s;
  final VoidCallback onTap;

  static Color _statusColor(String status) {
    switch (status) {
      case 'open': return const Color(0xFF10B981);
      case 'in_progress': return const Color(0xFFF59E0B);
      case 'resolved': return const Color(0xFF94A3B8);
      default: return const Color(0xFF94A3B8);
    }
  }

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 2) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final name = feedback.user.fullName ?? feedback.user.username;
    final initials = adminAvatarInitials(name);
    final avatarColor = Color(adminAvatarColorInt(name, isDark: isDark));
    final statusColor = _statusColor(feedback.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
              blurRadius: isDark ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: avatarColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(initials,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: avatarColor)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          s.feedbackStatusDisplay(feedback.status),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: kAdminAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          s.feedbackCategoryDisplay(feedback.category),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: kAdminAccent),
                        ),
                      ),
                      if (feedback.rating != null) ...[
                        const SizedBox(width: 6),
                        ...List.generate(
                          feedback.rating!,
                          (_) => const Icon(Icons.star_rounded,
                              size: 11, color: Color(0xFFF59E0B)),
                        ),
                      ],
                      const Spacer(),
                      Text(_formatDate(feedback.createdAt),
                          style: TextStyle(fontSize: 11, color: textSub)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feedback.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: textSub),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 18, color: textSub),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? kAdminAccent
              : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }
}

class _PaginationRow extends StatelessWidget {
  const _PaginationRow({
    required this.page,
    required this.hasNext,
    required this.isDark,
    required this.textSub,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final bool hasNext;
  final bool isDark;
  final Color textSub;
  final VoidCallback? onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (onPrev != null)
            TextButton.icon(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
              label: const Text('Prev'),
              style: TextButton.styleFrom(foregroundColor: kAdminAccent),
            ),
          if (onPrev != null) const SizedBox(width: 8),
          Text('Page ${page + 1}', style: TextStyle(fontSize: 12, color: textSub)),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onNext,
            icon: const Text('Next'),
            label: const Icon(Icons.chevron_right_rounded, size: 18),
            style: TextButton.styleFrom(foregroundColor: kAdminAccent),
          ),
        ],
      ),
    );
  }
}
