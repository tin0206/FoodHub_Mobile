import 'package:flutter/material.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';

/// First line of a backend-modified recipe:
/// `**🍽️ {title} (Modified)**` / `**🍽️ {title} (Đã chỉnh sửa)**`
final modifiedRecipeFirstLinePattern = RegExp(
  r'^\*\*\s*(.+?)\s+\((?:Modified|Đã chỉnh sửa)\)\s*\*\*\s*$',
);

final _ingredientHeaderPattern = RegExp(
  r'(?:^#{1,4}[^\n]*(?:ingredient|nguy[eê]n\s*li[eê]u)|\*\*[^*\n]*(?:ingredient|nguy[eê]n\s*li[eê]u)[^*\n]*\*\*)',
  caseSensitive: false,
  multiLine: true,
);

final _stepsHeaderPattern = RegExp(
  r'(?:^#{1,4}[^\n]*(?:(?:cooking\s+)?steps?|instructions?|directions?|c[aá]ch\s+l[aà]m)|\*\*[^*\n]*(?:(?:cooking\s+)?steps?|instructions?|directions?|c[aá]ch\s+l[aà]m)[^*\n]*\*\*)',
  caseSensitive: false,
  multiLine: true,
);

final _sectionTitlePattern = RegExp(
  r'ingredient|nguy[eê]n\s*li[eê]u|(?:cooking\s+)?steps?|instructions?|directions?|c[aá]ch\s+l[aà]m|nutrition|dinh\s*d[uư][ơỡ]ng',
  caseSensitive: false,
);

enum RecipeDiffOp { equal, added, removed, changed }

class RecipeDiffHunk {
  const RecipeDiffHunk({
    required this.op,
    required this.text,
    this.previous,
  });

  factory RecipeDiffHunk.equal(String text) =>
      RecipeDiffHunk(op: RecipeDiffOp.equal, text: text);

  factory RecipeDiffHunk.added(String text) =>
      RecipeDiffHunk(op: RecipeDiffOp.added, text: text);

  factory RecipeDiffHunk.removed(String text) =>
      RecipeDiffHunk(op: RecipeDiffOp.removed, text: text);

  factory RecipeDiffHunk.changed({
    required String previous,
    required String current,
  }) =>
      RecipeDiffHunk(
        op: RecipeDiffOp.changed,
        text: current,
        previous: previous,
      );

  final RecipeDiffOp op;
  final String text;
  final String? previous;

  bool get isBlank => text.trim().isEmpty;
  bool get isHighlight =>
      !isBlank &&
      (op == RecipeDiffOp.added ||
          op == RecipeDiffOp.removed ||
          op == RecipeDiffOp.changed);
}

bool isDetailRecipeMarkdown(String text) {
  return _ingredientHeaderPattern.hasMatch(text) &&
      _stepsHeaderPattern.hasMatch(text);
}

String firstNonEmptyLine(String text) {
  for (final line in text.replaceAll('\r\n', '\n').split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

/// Title from a modified-recipe first line, or null if this is not that format.
String? parseModifiedRecipeTitle(String text) {
  final match = modifiedRecipeFirstLinePattern.firstMatch(firstNonEmptyLine(text));
  final title = match?.group(1);
  if (title == null) return null;
  final cleaned = stripRecipeDecor(title);
  return cleaned.isEmpty ? null : cleaned;
}

bool isModifiedRecipeMarkdown(String text) =>
    parseModifiedRecipeTitle(text) != null;

String stripRecipeDecor(String line) {
  var s = line.trim();
  s = s.replaceAll('**', '');
  s = s.replaceAll('\uFE0F', '');
  // Drop leading emoji/punctuation so `🍽️ Title` and `Title` compare equal.
  s = s.replaceFirst(RegExp(r'^[^\p{L}\p{N}]+', unicode: true), '');
  s = s.replaceAll(RegExp(r'\s+\((?:Modified|Đã chỉnh sửa)\)\s*$'), '');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String canonicalRecipeTitle(String raw) => stripRecipeDecor(raw).toLowerCase();

String extractComparableRecipeTitle(String text) {
  final modified = parseModifiedRecipeTitle(text);
  if (modified != null) return modified;
  for (final line in text.replaceAll('\r\n', '\n').split('\n')) {
    final cleaned = stripRecipeDecor(line);
    if (cleaned.isEmpty) continue;
    if (_sectionTitlePattern.hasMatch(cleaned)) continue;
    return cleaned;
  }
  return '';
}

bool recipeTitlesMatch(String a, String b) {
  final left = canonicalRecipeTitle(a);
  final right = canonicalRecipeTitle(b);
  if (left.isEmpty || right.isEmpty) return false;
  if (left == right) return true;
  if (left.length >= 8 && right.length >= 8) {
    return left.contains(right) || right.contains(left);
  }
  return false;
}

bool isComparableRecipeMarkdown(String text, String expectedTitle) {
  if (!recipeTitlesMatch(extractComparableRecipeTitle(text), expectedTitle)) {
    return false;
  }
  return isModifiedRecipeMarkdown(text) || isDetailRecipeMarkdown(text);
}

/// Walks displayed chat *before* [currentIndex] and returns the nearest
/// previous original/modified recipe with the same title.
String? findPreviousRecipeMarkdown({
  required List<({bool isUser, String text})> messages,
  required int currentIndex,
}) {
  if (currentIndex < 0 || currentIndex >= messages.length) return null;
  final current = messages[currentIndex];
  if (current.isUser) return null;
  final title = parseModifiedRecipeTitle(current.text);
  if (title == null) return null;

  for (var i = currentIndex - 1; i >= 0; i--) {
    final msg = messages[i];
    if (msg.isUser) continue;
    if (isComparableRecipeMarkdown(msg.text, title)) return msg.text;
  }
  return null;
}

String normalizeRecipeCompareLine(String line) => stripRecipeDecor(line);

bool _isSectionHeading(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return false;
  return RegExp(r'^#{1,4}\s+').hasMatch(trimmed) ||
      RegExp(r'^\*\*[^*]+\*\*\s*:?\s*$').hasMatch(trimmed);
}

bool _isIngredientHeader(String line) {
  return _ingredientHeaderPattern.hasMatch(line.trim());
}

({List<String> before, List<String> ingredients, List<String> after})
    _splitIngredientSection(String text) {
  final lines = text.replaceAll('\r\n', '\n').split('\n');
  var start = -1;
  var end = lines.length;
  for (var i = 0; i < lines.length; i++) {
    if (_isIngredientHeader(lines[i])) {
      start = i;
      break;
    }
  }
  if (start < 0) {
    return (before: lines, ingredients: const <String>[], after: const <String>[]);
  }
  for (var i = start + 1; i < lines.length; i++) {
    if (_isSectionHeading(lines[i]) && !_isIngredientHeader(lines[i])) {
      end = i;
      break;
    }
  }
  return (
    before: lines.sublist(0, start + 1),
    ingredients: lines.sublist(start + 1, end),
    after: lines.sublist(end),
  );
}

List<RecipeDiffHunk> diffRecipeLines(String previous, String current) {
  final prev = _splitIngredientSection(previous);
  final curr = _splitIngredientSection(current);
  return [
    for (final line in curr.before) RecipeDiffHunk.equal(line),
    ..._diffLineLists(prev.ingredients, curr.ingredients),
    for (final line in curr.after) RecipeDiffHunk.equal(line),
  ];
}

List<RecipeDiffHunk> _diffLineLists(List<String> oldLines, List<String> newLines) {
  final oldNorm = oldLines.map(normalizeRecipeCompareLine).toList();
  final newNorm = newLines.map(normalizeRecipeCompareLine).toList();
  final n = oldLines.length;
  final m = newLines.length;

  final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      if (oldNorm[i] == newNorm[j]) {
        dp[i][j] = dp[i + 1][j + 1] + 1;
      } else {
        dp[i][j] = dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1];
      }
    }
  }

  final raw = <RecipeDiffHunk>[];
  var i = 0;
  var j = 0;
  while (i < n && j < m) {
    if (oldNorm[i] == newNorm[j]) {
      raw.add(RecipeDiffHunk.equal(newLines[j]));
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      raw.add(RecipeDiffHunk.removed(oldLines[i]));
      i++;
    } else {
      raw.add(RecipeDiffHunk.added(newLines[j]));
      j++;
    }
  }
  while (i < n) {
    raw.add(RecipeDiffHunk.removed(oldLines[i++]));
  }
  while (j < m) {
    raw.add(RecipeDiffHunk.added(newLines[j++]));
  }

  final out = <RecipeDiffHunk>[];
  for (var k = 0; k < raw.length; k++) {
    final a = raw[k];
    if (k + 1 < raw.length) {
      final b = raw[k + 1];
      if (a.op == RecipeDiffOp.removed && b.op == RecipeDiffOp.added) {
        out.add(RecipeDiffHunk.changed(previous: a.text, current: b.text));
        k++;
        continue;
      }
      if (a.op == RecipeDiffOp.added && b.op == RecipeDiffOp.removed) {
        out.add(RecipeDiffHunk.changed(previous: b.text, current: a.text));
        k++;
        continue;
      }
    }
    out.add(a);
  }
  return out;
}

bool recipeDiffHasVisibleChanges(List<RecipeDiffHunk> hunks) =>
    hunks.any((h) => h.isHighlight);

class RecipeDiffBody extends StatelessWidget {
  const RecipeDiffBody({
    super.key,
    required this.hunks,
    required this.isDarkMode,
  });

  final List<RecipeDiffHunk> hunks;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF374151);
    final base = TextStyle(fontSize: 13.5, height: 1.45, color: textColor);
    final bold = base.copyWith(fontWeight: FontWeight.w700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < hunks.length; i++)
          _DiffLine(
            hunk: hunks[i],
            index: i,
            isDarkMode: isDarkMode,
            base: base,
            bold: bold,
          ),
      ],
    );
  }
}

class _DiffLine extends StatelessWidget {
  const _DiffLine({
    required this.hunk,
    required this.index,
    required this.isDarkMode,
    required this.base,
    required this.bold,
  });

  final RecipeDiffHunk hunk;
  final int index;
  final bool isDarkMode;
  final TextStyle base;
  final TextStyle bold;

  @override
  Widget build(BuildContext context) {
    final lineStyle = hunk.op == RecipeDiffOp.removed
        ? base.copyWith(
            decoration: TextDecoration.lineThrough,
            color: base.color?.withValues(alpha: 0.7),
          )
        : base;
    final line = _RecipeLineText(text: hunk.text, base: lineStyle, bold: bold);

    if (hunk.isBlank) {
      return const SizedBox(height: 8);
    }
    if (!hunk.isHighlight) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: line,
      );
    }

    final colors = _diffColors(hunk.op, isDarkMode);
    final tooltip = _tooltipMessage(context, hunk);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 400),
        showDuration: const Duration(seconds: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('recipe-diff-${hunk.op.name}-$index'),
            onTap: () => _showDiffDetails(context, hunk),
            borderRadius: BorderRadius.circular(6),
            child: Ink(
              decoration: BoxDecoration(
                color: colors.$1,
                borderRadius: BorderRadius.circular(6),
                border: Border(
                  left: BorderSide(color: colors.$2, width: 3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: line,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

(Color, Color) _diffColors(RecipeDiffOp op, bool isDarkMode) {
  switch (op) {
    case RecipeDiffOp.added:
      return (
        isDarkMode
            ? const Color(0xFF059669).withValues(alpha: 0.18)
            : const Color(0xFFD1FAE5),
        const Color(0xFF059669),
      );
    case RecipeDiffOp.removed:
      return (
        isDarkMode
            ? const Color(0xFFEF4444).withValues(alpha: 0.16)
            : const Color(0xFFFEE2E2),
        const Color(0xFFEF4444),
      );
    case RecipeDiffOp.changed:
      return (
        isDarkMode
            ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
            : const Color(0xFFFEF3C7),
        const Color(0xFFD97706),
      );
    case RecipeDiffOp.equal:
      return (Colors.transparent, Colors.transparent);
  }
}

String _tooltipMessage(BuildContext context, RecipeDiffHunk hunk) {
  final s = S.of(context);
  switch (hunk.op) {
    case RecipeDiffOp.added:
      return s.recipeDiffAdded;
    case RecipeDiffOp.removed:
      return '${s.recipeDiffRemoved}: ${stripRecipeDecor(hunk.text)}';
    case RecipeDiffOp.changed:
      return '${s.recipeDiffPrevious}: ${stripRecipeDecor(hunk.previous ?? '')}';
    case RecipeDiffOp.equal:
      return '';
  }
}

void _showDiffDetails(BuildContext context, RecipeDiffHunk hunk) {
  final s = S.of(context);
  final title = switch (hunk.op) {
    RecipeDiffOp.added => s.recipeDiffAdded,
    RecipeDiffOp.removed => s.recipeDiffRemoved,
    RecipeDiffOp.changed => s.recipeDiffChanged,
    RecipeDiffOp.equal => s.recipeDiffChanged,
  };

  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hunk.op != RecipeDiffOp.added) ...[
                Text(
                  s.recipeDiffPrevious,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  stripRecipeDecor(
                    hunk.op == RecipeDiffOp.removed
                        ? hunk.text
                        : (hunk.previous ?? ''),
                  ),
                ),
              ],
              if (hunk.op == RecipeDiffOp.changed) const SizedBox(height: 12),
              if (hunk.op != RecipeDiffOp.removed) ...[
                Text(
                  s.recipeDiffCurrent,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(stripRecipeDecor(hunk.text)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.close),
          ),
        ],
      );
    },
  );
}

class _RecipeLineText extends StatelessWidget {
  const _RecipeLineText({
    required this.text,
    required this.base,
    required this.bold,
  });

  final String text;
  final TextStyle base;
  final TextStyle bold;

  @override
  Widget build(BuildContext context) {
    final bullet = RegExp(r'^(\s*)[-*•]\s+(.*)$').firstMatch(text);
    final numbered = RegExp(r'^(\s*)(\d+)\.\s+(.*)$').firstMatch(text);

    String body = text;
    Widget? marker;
    if (bullet != null) {
      body = bullet.group(2)!;
      marker = Padding(
        padding: const EdgeInsets.only(right: 8, top: 7),
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: base.color,
            shape: BoxShape.circle,
          ),
        ),
      );
    } else if (numbered != null) {
      body = numbered.group(3)!;
      marker = Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text('${numbered.group(2)}.', style: bold.copyWith(fontSize: 13)),
      );
    }

    final span = _boldSpans(body, base, bold);
    final rich = Text.rich(span);
    if (marker == null) return rich;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        marker,
        Expanded(child: rich),
      ],
    );
  }
}

TextSpan _boldSpans(String text, TextStyle base, TextStyle bold) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*');
  var last = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > last) {
      spans.add(TextSpan(text: text.substring(last, match.start)));
    }
    spans.add(TextSpan(text: match.group(1), style: bold));
    last = match.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last)));
  }
  if (spans.isEmpty) {
    spans.add(TextSpan(text: text));
  }
  return TextSpan(style: base, children: spans);
}
