import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:foodhub_mobile/models/ai.dart';

class MarkdownSection {
  const MarkdownSection({required this.title, required this.body});

  /// Empty title means intro / untitled block shown always expanded.
  final String title;
  final String body;
}

class RecipeLinkRef {
  const RecipeLinkRef({required this.title, required this.recipeId});

  final String title;
  final String recipeId;
}

final _mdLinkPattern = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

/// Extract `[Name](id)` links and replace them with plain bold names in markdown.
({String markdown, List<RecipeLinkRef> links}) extractRecipeMarkdownLinks(
  String markdown,
) {
  final links = <RecipeLinkRef>[];
  final seen = <String>{};
  final cleaned = markdown.replaceAllMapped(_mdLinkPattern, (match) {
    final title = match.group(1)!.trim();
    final id = match.group(2)!.trim();
    if (title.isNotEmpty && id.isNotEmpty && seen.add(id)) {
      links.add(RecipeLinkRef(title: title, recipeId: id));
    }
    return '**$title**';
  });
  return (markdown: cleaned, links: links);
}

/// Merges markdown links with structured recipe payloads (dedupe by id/title).
List<RecipeLinkRef> mergeRecipeCtas({
  required List<RecipeLinkRef> fromMarkdown,
  required List<RagRecipeModel> recipes,
}) {
  final out = <RecipeLinkRef>[];
  final seenIds = <String>{};
  final seenTitles = <String>{};

  void add(String title, String? id) {
    final t = title.trim();
    if (t.isEmpty) return;
    final keyId = (id ?? '').trim();
    if (keyId.isNotEmpty) {
      if (!seenIds.add(keyId)) return;
      out.add(RecipeLinkRef(title: t, recipeId: keyId));
      seenTitles.add(t.toLowerCase());
      return;
    }
    if (!seenTitles.add(t.toLowerCase())) return;
    out.add(RecipeLinkRef(title: t, recipeId: ''));
  }

  for (final link in fromMarkdown) {
    add(link.title, link.recipeId);
  }
  for (final r in recipes) {
    add(r.title, r.recipeId);
  }
  return out;
}

/// Splits markdown into an optional intro and heading-based sections (`#` / `##`).
List<MarkdownSection> parseMarkdownSections(String markdown) {
  final lines = markdown.replaceAll('\r\n', '\n').split('\n');
  final sections = <MarkdownSection>[];
  final buffer = StringBuffer();
  var currentTitle = '';

  void flush() {
    final body = buffer.toString().trim();
    buffer.clear();
    if (currentTitle.isEmpty && body.isEmpty) return;
    sections.add(MarkdownSection(title: currentTitle, body: body));
  }

  for (final line in lines) {
    final match = RegExp(r'^(#{1,2})\s+(.+)$').firstMatch(line.trimRight());
    if (match != null) {
      flush();
      currentTitle = match.group(2)!.trim();
      continue;
    }
    buffer.writeln(line);
  }
  flush();

  if (sections.isEmpty) {
    return [MarkdownSection(title: '', body: markdown.trim())];
  }
  return sections;
}

MarkdownStyleSheet recsMarkdownStyle(bool isDarkMode) {
  final textColor =
      isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF374151);
  final muted =
      isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
  final codeBg =
      isDarkMode ? const Color(0xFF262626) : const Color(0xFFF3F4F6);

  return MarkdownStyleSheet(
    p: TextStyle(fontSize: 13.5, height: 1.45, color: textColor),
    h1: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
    ),
    h2: TextStyle(
      fontSize: 15.5,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
    ),
    h3: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
    ),
    strong: TextStyle(fontWeight: FontWeight.w700, color: textColor),
    em: TextStyle(fontStyle: FontStyle.italic, color: textColor),
    listBullet: TextStyle(fontSize: 13.5, color: textColor),
    listIndent: 20,
    blockquote: TextStyle(fontSize: 13, height: 1.4, color: muted),
    blockquoteDecoration: BoxDecoration(
      color: isDarkMode
          ? const Color(0xFF059669).withValues(alpha: 0.12)
          : const Color(0xFFECFDF5),
      border: const Border(
        left: BorderSide(color: Color(0xFF059669), width: 3),
      ),
    ),
    code: TextStyle(
      fontSize: 12.5,
      fontFamily: 'monospace',
      backgroundColor: codeBg,
      color: textColor,
    ),
    codeblockDecoration: BoxDecoration(
      color: codeBg,
      borderRadius: BorderRadius.circular(8),
    ),
    codeblockPadding: const EdgeInsets.all(10),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: isDarkMode
              ? const Color(0xFF333333)
              : const Color(0xFFE5E7EB),
        ),
      ),
    ),
    a: const TextStyle(
      color: Color(0xFF059669),
      decoration: TextDecoration.underline,
    ),
  );
}

/// Full-width, tall recipe CTA for easy tap-to-detail.
class RecipeDetailCtaButton extends StatelessWidget {
  const RecipeDetailCtaButton({
    super.key,
    required this.title,
    required this.isDarkMode,
    required this.onPressed,
  });

  final String title;
  final bool isDarkMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_rounded, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'View',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded, size: 22),
          ],
        ),
      ),
    );
  }
}

class RecipeCtaList extends StatelessWidget {
  const RecipeCtaList({
    super.key,
    required this.links,
    required this.isDarkMode,
    required this.onOpen,
  });

  final List<RecipeLinkRef> links;
  final bool isDarkMode;
  final void Function(RecipeLinkRef link) onOpen;

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          'Open recipe details',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: isDarkMode
                ? const Color(0xFF94A3B8)
                : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RecipeDetailCtaButton(
              title: link.title,
              isDarkMode: isDarkMode,
              onPressed: () => onOpen(link),
            ),
          ),
        ),
      ],
    );
  }
}

class MarkdownReplyBody extends StatelessWidget {
  const MarkdownReplyBody({
    super.key,
    required this.markdown,
    required this.isDarkMode,
    this.recipes = const [],
    this.onOpenRecipe,
  });

  final String markdown;
  final bool isDarkMode;
  final List<RagRecipeModel> recipes;
  final void Function(RecipeLinkRef link)? onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    final extracted = extractRecipeMarkdownLinks(markdown);
    final ctas = mergeRecipeCtas(
      fromMarkdown: extracted.links,
      recipes: recipes,
    );
    final sections = parseMarkdownSections(extracted.markdown);
    final style = recsMarkdownStyle(isDarkMode);
    final hasHeadings = sections.any((s) => s.title.isNotEmpty);

    final content = !hasHeadings
        ? MarkdownBody(
            data: extracted.markdown.trim().isEmpty ? ' ' : extracted.markdown,
            styleSheet: style,
            softLineBreak: true,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                if (sections[i].title.isEmpty)
                  MarkdownBody(
                    data: sections[i].body,
                    styleSheet: style,
                    softLineBreak: true,
                  )
                else
                  _MarkdownSectionTile(
                    title: sections[i].title,
                    body: sections[i].body,
                    isDarkMode: isDarkMode,
                    styleSheet: style,
                    initiallyExpanded: i == 0 ||
                        (sections.first.title.isEmpty ? i == 1 : false),
                  ),
              ],
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        if (onOpenRecipe != null && ctas.isNotEmpty)
          RecipeCtaList(
            links: ctas,
            isDarkMode: isDarkMode,
            onOpen: onOpenRecipe!,
          ),
      ],
    );
  }
}

class _MarkdownSectionTile extends StatefulWidget {
  const _MarkdownSectionTile({
    required this.title,
    required this.body,
    required this.isDarkMode,
    required this.styleSheet,
    this.initiallyExpanded = false,
  });

  final String title;
  final String body;
  final bool isDarkMode;
  final MarkdownStyleSheet styleSheet;
  final bool initiallyExpanded;

  @override
  State<_MarkdownSectionTile> createState() => _MarkdownSectionTileState();
}

class _MarkdownSectionTileState extends State<_MarkdownSectionTile> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE5E7EB);
    final titleColor = widget.isDarkMode
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF111827);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? const Color(0xFF141414)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF059669),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: widget.isDarkMode
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && widget.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: MarkdownBody(
                data: widget.body,
                styleSheet: widget.styleSheet,
                softLineBreak: true,
              ),
            ),
        ],
      ),
    );
  }
}

class TypingIndicatorBubble extends StatelessWidget {
  const TypingIndicatorBubble({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF059669), Color(0xFF047857)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDarkMode ? 0.35 : 0.06,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const _TypingDots(),
        ),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value + i * 0.2) % 1.0;
            final opacity =
                0.35 + 0.65 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
