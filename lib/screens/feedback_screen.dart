import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/feedback.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/feedback_service.dart';
import 'package:foodhub_mobile/widgets/favorite_toast.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _service = FeedbackService();
  final _messageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _category = 'general';
  int? _rating;
  bool _submitting = false;
  List<FeedbackModel>? _history;
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final list = await _service.listMyFeedback();
      if (!mounted) return;
      setState(() {
        _history = list;
        _historyLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _historyLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final created = await _service.submitFeedback(
        category: _category,
        message: _messageCtrl.text.trim(),
        rating: _rating,
      );
      if (!mounted) return;
      _messageCtrl.clear();
      setState(() {
        _submitting = false;
        _rating = null;
        _category = 'general';
        _history = [created, ...(_history ?? [])];
      });
      showSuccessToast(context, S.of(context).feedbackSubmitSuccess);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showErrorToast(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showErrorToast(context, 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final divColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);
    final fieldFill = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);
    final accent = const Color(0xFF059669);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textSub),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.feedbackPageTitle,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
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
            // ── Submit card ────────────────────────────────────────────────
            _Card(isDark: isDark, cardBg: cardBg, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category
                Text(s.feedbackCategoryLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSub)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FeedbackService.categories.map((cat) {
                    final sel = _category == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? accent.withValues(alpha: isDark ? 0.22 : 0.1)
                              : fieldFill,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: sel
                                ? accent.withValues(alpha: 0.7)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          s.feedbackCategoryDisplay(cat),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? (isDark ? const Color(0xFF4ADE80) : accent)
                                : textSub,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Rating
                Text(s.feedbackRatingLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSub)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    final filled = (_rating ?? 0) >= star;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = _rating == star ? null : star),
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 4 ? 6 : 0),
                        child: Icon(
                          filled ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 28,
                          color: filled ? const Color(0xFFF59E0B) : textSub,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),

                // Message
                Text(s.feedbackMessageLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSub)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageCtrl,
                  minLines: 3,
                  maxLines: 6,
                  style: TextStyle(fontSize: 13, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: s.feedbackMessagePlaceholder,
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
                      borderSide: BorderSide(color: accent),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFF43F5E)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim().length < 5) return 'Too short';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Submit
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(s.feedbackSubmitCta,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ],
            )),
            const SizedBox(height: 20),

            // ── History ────────────────────────────────────────────────────
            Text(s.feedbackHistoryTitle,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 10),

            if (_historyLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF059669)),
                ),
              )
            else if (_history == null || _history!.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(s.feedbackNoneYet,
                      style: TextStyle(fontSize: 13, color: textSub)),
                ),
              )
            else
              ...(_history!.map((fb) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FeedbackHistoryItem(
                  feedback: fb,
                  isDark: isDark,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSub: textSub,
                  s: s,
                ),
              ))),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.isDark, required this.cardBg, required this.child});

  final bool isDark;
  final Color cardBg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}

class _FeedbackHistoryItem extends StatefulWidget {
  const _FeedbackHistoryItem({
    required this.feedback,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSub,
    required this.s,
  });

  final FeedbackModel feedback;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSub;
  final S s;

  @override
  State<_FeedbackHistoryItem> createState() => _FeedbackHistoryItemState();
}

class _FeedbackHistoryItemState extends State<_FeedbackHistoryItem> {
  static const _kMaxLines = 4;
  bool _expanded = false;

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 2) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  bool _isLong(String text, TextStyle style, double maxWidth) {
    final span = TextSpan(text: text, style: style);
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      maxLines: _kMaxLines,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final fb = widget.feedback;
    final isDark = widget.isDark;
    final textPrimary = widget.textPrimary;
    final textSub = widget.textSub;
    final s = widget.s;

    final accent = const Color(0xFF059669);
    final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);
    final hasReply = fb.adminReply != null && fb.adminReply!.isNotEmpty;
    final msgStyle = TextStyle(fontSize: 13, color: textPrimary);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
            blurRadius: isDark ? 10 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  s.feedbackCategoryDisplay(fb.category),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF4ADE80) : accent,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(fb.createdAt),
                style: TextStyle(fontSize: 11, color: textSub),
              ),
            ],
          ),
          if (fb.rating != null) ...[
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (i) => Icon(
                i < fb.rating! ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 14,
                color: i < fb.rating! ? const Color(0xFFF59E0B) : textSub,
              )),
            ),
          ],
          const SizedBox(height: 8),

          // Message with show more/less
          LayoutBuilder(
            builder: (_, constraints) {
              final isLong = _isLong(fb.message, msgStyle, constraints.maxWidth);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fb.message,
                    style: msgStyle,
                    maxLines: (_expanded || !isLong) ? null : _kMaxLines,
                    overflow: (_expanded || !isLong)
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if (isLong) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Text(
                        _expanded ? 'Show less' : 'Show more',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),

          if (hasReply) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: borderColor),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      size: 13, color: Color(0xFF6366F1)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.feedbackAdminReplyLabel,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1))),
                      const SizedBox(height: 3),
                      Text(fb.adminReply!,
                          style: TextStyle(fontSize: 13, color: textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
