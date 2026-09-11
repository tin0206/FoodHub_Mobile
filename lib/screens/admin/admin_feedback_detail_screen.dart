import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/admin.dart';
import 'package:foodhub_mobile/models/feedback.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/screens/admin/admin_user_detail_screen.dart';
import 'package:foodhub_mobile/services/admin_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';

class AdminFeedbackDetailScreen extends StatefulWidget {
  const AdminFeedbackDetailScreen({
    super.key,
    required this.feedbackId,
    required this.isDarkMode,
  });

  final int feedbackId;
  final bool isDarkMode;

  @override
  State<AdminFeedbackDetailScreen> createState() =>
      _AdminFeedbackDetailScreenState();
}

class _AdminFeedbackDetailScreenState
    extends State<AdminFeedbackDetailScreen> {
  final _admin = AdminService();
  final _replyCtrl = TextEditingController();

  AdminFeedbackModel? _feedback;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  // Track pending edits to enable Save only on real change
  String _pendingStatus = '';

  @override
  void initState() {
    super.initState();
    _load();
    _replyCtrl.addListener(_onReplyChanged);
  }

  @override
  void dispose() {
    _replyCtrl.removeListener(_onReplyChanged);
    _replyCtrl.dispose();
    super.dispose();
  }

  void _onReplyChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final fb = await _admin.getFeedback(widget.feedbackId);
      if (!mounted) return;
      setState(() {
        _feedback = fb;
        _loading = false;
        _pendingStatus = fb.status;
        _replyCtrl.text = fb.adminReply ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : '$e';
      });
    }
  }

  bool get _hasChanges {
    final fb = _feedback;
    if (fb == null) return false;
    if (_pendingStatus != fb.status) return true;
    if (_replyCtrl.text.trim() != (fb.adminReply ?? '').trim()) return true;
    return false;
  }

  Future<void> _save() async {
    if (_saving || !_hasChanges) return;
    setState(() => _saving = true);
    try {
      final updated = await _admin.updateFeedback(widget.feedbackId, {
        'status': _pendingStatus,
        'admin_reply': _replyCtrl.text.trim().isEmpty
            ? null
            : _replyCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _feedback = updated;
        _saving = false;
        _pendingStatus = updated.status;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).adminFeedbackSaveSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e is ApiException ? e.message : 'Unable to save.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final s = S.of(context);
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;
    final textPrimary =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final divColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);
    final fieldFill =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: kAdminAccent)),
      );
    }

    if (_error != null || _feedback == null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Not found',
                  style: TextStyle(color: textSub)),
              TextButton(onPressed: _load, child: Text(s.retry)),
            ],
          ),
        ),
      );
    }

    final fb = _feedback!;
    final user = fb.user;
    final userName = user.fullName ?? user.username;
    final initials = adminAvatarInitials(userName);
    final avatarColor = Color(adminAvatarColorInt(userName, isDark: isDark));

    final statuses = ['open', 'in_progress', 'resolved'];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: textSub),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '#${fb.id} — ${s.feedbackCategoryDisplay(fb.category)}',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: divColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ── Submitted By ────────────────────────────────────────────────
          _FormSection(
            title: 'Submitted By',
            icon: Icons.person_rounded,
            isDark: isDark,
            cardBg: cardBg,
            textPrimary: textPrimary,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => AdminUserDetailScreen(
                      userId: user.id, isDarkMode: isDark),
                )),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: avatarColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(initials,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: avatarColor)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary)),
                            Text(user.email,
                                style: TextStyle(
                                    fontSize: 11, color: textSub)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: textSub),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Feedback ────────────────────────────────────────────────────
          _FormSection(
            title: 'Feedback',
            icon: Icons.forum_rounded,
            isDark: isDark,
            cardBg: cardBg,
            textPrimary: textPrimary,
            children: [
              _InfoRow(
                label: 'Category',
                value: s.feedbackCategoryDisplay(fb.category),
                textPrimary: textPrimary,
                textSub: textSub,
                divColor: divColor,
              ),
              if (fb.rating != null)
                _InfoRow(
                  label: 'Rating',
                  value: '${fb.rating}/5',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < fb.rating!
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 14,
                        color: i < fb.rating!
                            ? const Color(0xFFF59E0B)
                            : textSub,
                      ),
                    ),
                  ),
                  textPrimary: textPrimary,
                  textSub: textSub,
                  divColor: divColor,
                ),
              _InfoRow(
                label: 'Submitted',
                value: _fmtDate(fb.createdAt),
                textPrimary: textPrimary,
                textSub: textSub,
                divColor: divColor,
              ),
              const SizedBox(height: 8),
              Text('Message',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSub)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fieldFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(fb.message,
                    style: TextStyle(fontSize: 13, color: textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Status & Reply ──────────────────────────────────────────────
          _FormSection(
            title: 'Status & Reply',
            icon: Icons.edit_note_rounded,
            isDark: isDark,
            cardBg: cardBg,
            textPrimary: textPrimary,
            children: [
              Text(s.adminFeedbackStatusFieldLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSub)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statuses.map((st) {
                  final sel = _pendingStatus == st;
                  Color stColor;
                  switch (st) {
                    case 'open':
                      stColor = const Color(0xFF10B981);
                      break;
                    case 'in_progress':
                      stColor = const Color(0xFFF59E0B);
                      break;
                    default:
                      stColor = const Color(0xFF94A3B8);
                  }
                  return GestureDetector(
                    onTap: () => setState(() => _pendingStatus = st),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? stColor.withValues(alpha: isDark ? 0.22 : 0.12)
                            : fieldFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel
                              ? stColor.withValues(alpha: 0.7)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                                color: stColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s.feedbackStatusDisplay(st),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sel ? stColor : textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text(s.adminFeedbackReplyFieldLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSub)),
              const SizedBox(height: 8),
              TextField(
                controller: _replyCtrl,
                minLines: 3,
                maxLines: 6,
                style: TextStyle(fontSize: 13, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Write a reply to the user…',
                  hintStyle: TextStyle(color: textSub, fontSize: 13),
                  filled: true,
                  fillColor: fieldFill,
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
                        const BorderSide(color: kAdminAccent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: (_saving || !_hasChanges) ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: kAdminAccent,
                  disabledBackgroundColor:
                      kAdminAccent.withValues(alpha: 0.35),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(s.adminFeedbackSaveCta,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
              Text(title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSub,
    required this.divColor,
    this.trailing,
  });

  final String label;
  final String value;
  final Color textPrimary;
  final Color textSub;
  final Color divColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12.5, color: textSub)),
              const Spacer(),
              trailing ??
                  Text(value,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
            ],
          ),
        ),
        Divider(height: 1, color: divColor),
      ],
    );
  }
}
