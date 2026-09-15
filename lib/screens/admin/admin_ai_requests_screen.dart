import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/admin.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_user_detail_screen.dart';
import 'package:foodhub_mobile/services/admin_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';

const _kPageSize = 20;
const _kStatuses = [
  'pending',
  'processing',
  'completed',
  'failed',
  'cancelled',
];
const _kRequestTypes = [
  'chat',
  'dish',
  'ingredients',
  'meal_suggest',
  'shopping_list',
  'map_aisles',
];

class AdminAiRequestsScreen extends StatefulWidget {
  const AdminAiRequestsScreen({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<AdminAiRequestsScreen> createState() => _AdminAiRequestsScreenState();
}

class _AdminAiRequestsScreenState extends State<AdminAiRequestsScreen> {
  final _admin = AdminService();
  List<AdminAiRequestLogEntry>? _items;
  bool _loading = true;
  String? _error;

  String? _statusFilter; // null = All
  String? _typeFilter; // null = All
  int _page = 0;
  bool _hasNext = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _setStatusFilter(String? f) {
    setState(() {
      _statusFilter = f;
      _page = 0;
    });
    _load();
  }

  void _setTypeFilter(String? f) {
    setState(() {
      _typeFilter = f;
      _page = 0;
    });
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _admin.listAiRequests(
        skip: _page * _kPageSize,
        limit: _kPageSize + 1,
        status: _statusFilter,
        requestType: _typeFilter,
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

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'failed':
        return const Color(0xFFEF4444);
      case 'cancelled':
        return const Color(0xFF6B7280);
      case 'processing':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFF59E0B); // pending
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final lang = LangScope.of(context);
    final s = S.of(context);
    final textPrimary = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;
    final list = _items ?? [];
    final rangeStart = list.isEmpty ? 0 : _page * _kPageSize + 1;
    final rangeEnd = _page * _kPageSize + list.length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 13,
                          color: kAdminAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.adminBackToAnalytics,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kAdminAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        s.adminAiRequestsPageTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _loading ? null : _load,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
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
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: kAdminAccent,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh_rounded,
                                      size: 13,
                                      color: kAdminAccent,
                                    ),
                              const SizedBox(width: 5),
                              const Text(
                                'Refresh',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: kAdminAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Status filter chips
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'All',
                          isDark: isDark,
                          selected: _statusFilter == null,
                          onTap: () => _setStatusFilter(null),
                        ),
                        for (final st in _kStatuses)
                          Padding(
                            padding: const EdgeInsets.only(left: 7),
                            child: _FilterChip(
                              label: s.adminAiRequestStatusDisplay(st),
                              isDark: isDark,
                              selected: _statusFilter == st,
                              onTap: () => _setStatusFilter(st),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Request type filter
                  Row(
                    children: [
                      Text(
                        s.adminRequestTypeFilterLabel,
                        style: TextStyle(fontSize: 11.5, color: textSub),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _typeFilter,
                              isExpanded: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: textPrimary,
                              ),
                              dropdownColor: cardBg,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: textSub,
                                size: 18,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All'),
                                ),
                                for (final t in _kRequestTypes)
                                  DropdownMenuItem(
                                    value: t,
                                    child: Text(s.adminAiRequestTypeDisplay(t)),
                                  ),
                              ],
                              onChanged: _setTypeFilter,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                      child: Text(
                        s.adminAiRequestsLoadError,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFF43F5E),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: _loading && _items == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: kAdminAccent,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: kAdminAccent,
                      child: list.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: Text(
                                      s.adminAiRequestsEmpty,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textSub,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    s.adminAiRequestsPagination(
                                      rangeStart,
                                      rangeEnd,
                                      _hasNext,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSub,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.3 : 0.06,
                                        ),
                                        blurRadius: isDark ? 10 : 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Column(
                                      children: list.asMap().entries.map((e) {
                                        return _AiRequestRow(
                                          entry: e.value,
                                          isDark: isDark,
                                          lang: lang,
                                          showTopDivider: e.key > 0,
                                          statusColor: _statusColor(
                                            e.value.status,
                                          ),
                                          onTapUser: () =>
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      AdminUserDetailScreen(
                                                        userId: e.value.userId,
                                                        isDarkMode: isDark,
                                                      ),
                                                ),
                                              ),
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
                                ),
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
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
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : textSub,
          ),
        ),
      ),
    );
  }
}

// ── Row ────────────────────────────────────────────────────────────────────────

class _AiRequestRow extends StatelessWidget {
  const _AiRequestRow({
    required this.entry,
    required this.isDark,
    required this.lang,
    required this.showTopDivider,
    required this.statusColor,
    required this.onTapUser,
  });

  final AdminAiRequestLogEntry entry;
  final bool isDark;
  final String lang;
  final bool showTopDivider;
  final Color statusColor;
  final VoidCallback onTapUser;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final textPrimary = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final dividerColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF3F4F6);
    final subtle = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);

    final durationText = entry.durationMs != null
        ? '${entry.durationMs} ms'
        : s.adminNotTrackedYet;
    final tokensText = entry.tokenUsage != null
        ? '${entry.tokenUsage}'
        : s.adminNotTrackedYet;
    final providerText = (entry.provider != null && entry.provider!.isNotEmpty)
        ? entry.provider!
        : s.adminNotTrackedYet;

    return Column(
      children: [
        if (showTopDivider) Divider(height: 1, color: dividerColor),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.adminAiRequestTypeDisplay(entry.requestType),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      s.adminAiRequestStatusDisplay(entry.status),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _MiniStat(
                    label: s.adminAiRequestDurationLabel,
                    value: durationText,
                    textSub: textSub,
                    textPrimary: textPrimary,
                  ),
                  _MiniStat(
                    label: s.adminAiRequestTokensLabel,
                    value: tokensText,
                    textSub: textSub,
                    textPrimary: textPrimary,
                  ),
                  _MiniStat(
                    label: s.adminAiRequestProviderLabel,
                    value: providerText,
                    textSub: textSub,
                    textPrimary: textPrimary,
                  ),
                ],
              ),
              if (entry.errorMessage != null &&
                  entry.errorMessage!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${s.adminErrorLabel}: ${entry.errorMessage}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFEF4444),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  InkWell(
                    onTap: onTapUser,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: subtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.displayUser,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kAdminAccent,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    adminRelativeTime(entry.createdAt, lang),
                    style: TextStyle(fontSize: 10.5, color: textSub),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.textSub,
    required this.textPrimary,
  });

  final String label;
  final String value;
  final Color textSub;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(fontSize: 11, color: textSub),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ],
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
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          if (page > 0) const SizedBox(width: 8),
          Text(
            'Page ${page + 1}',
            style: TextStyle(fontSize: 12, color: textSub),
          ),
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
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
