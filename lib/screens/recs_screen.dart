import 'package:flutter/material.dart';
import 'package:foodhub_mobile/models/ai.dart';
import 'package:foodhub_mobile/services/ai_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/widgets/ai_capture_overlay.dart';
import 'package:foodhub_mobile/widgets/recs/markdown_reply.dart';
import 'package:foodhub_mobile/widgets/recs/recipe_suggestion_card.dart';

class RecsScreen extends StatefulWidget {
  const RecsScreen({
    super.key,
    this.dietaryRestrictions = const {},
    this.primaryGoal = '',
  });

  final Set<String> dietaryRestrictions;
  final String primaryGoal;

  @override
  State<RecsScreen> createState() => _RecsScreenState();
}

class _RecsScreenState extends State<RecsScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  final List<ChatMessageModel> _conversationHistory = [];

  /// Compose-only detection lines (edited as free text; not separate chat bubbles).
  String? _composeDishText;
  String? _composeIngredientsText;
  bool _isSending = false;

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          "Hello! I'm your AI recipe assistant. Tell me what you're craving, or tap the camera icon to scan ingredients or a dish — then press send.",
      isUser: false,
    ),
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _dishNamesFrom(DishRecognitionModel dish) {
    if (dish.results.isNotEmpty) {
      return dish.results
          .take(5)
          .map((r) => r.dishName)
          .where((name) => name.isNotEmpty)
          .toList();
    }
    if (dish.dishName.isNotEmpty) return [dish.dishName];
    return dish.suggestedRecipes.take(5).toList();
  }

  /// Prefer top match for the initial compose line.
  void _setDishComposeFrom(DishRecognitionModel dish) {
    final names = _dishNamesFrom(dish);
    if (names.isEmpty) {
      _composeDishText = null;
      return;
    }
    _composeDishText = 'Dishes detected: ${names.first}';
  }

  List<String> _ingredientsForApi() {
    final text = _composeIngredientsText?.trim();
    if (text == null || text.isEmpty) return const [];
    var values = text;
    const prefix = 'Ingredients detected:';
    if (values.toLowerCase().startsWith(prefix.toLowerCase())) {
      values = values.substring(prefix.length);
    }
    return values
        .split(RegExp(r'[,;\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Single prompt from dish → ingredients → user query (only non-empty parts).
  String _buildMergedPrompt(String userQuery) {
    final parts = <String>[];
    final dishText = _composeDishText?.trim();
    final ingredientsText = _composeIngredientsText?.trim();
    if (dishText != null && dishText.isNotEmpty) parts.add(dishText);
    if (ingredientsText != null && ingredientsText.isNotEmpty) {
      parts.add(ingredientsText);
    }
    final trimmed = userQuery.trim();
    if (trimmed.isNotEmpty) parts.add(trimmed);
    return parts.join('\n');
  }

  void _clearComposeDetections() {
    _composeIngredientsText = null;
    _composeDishText = null;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _resetChat() async {
    if (_isSending) return;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF141414) : Colors.white,
        title: Text(
          'Reset chat?',
          style: TextStyle(
            color: isDarkMode
                ? const Color(0xFFF8FAFC)
                : const Color(0xFF111827),
          ),
        ),
        content: Text(
          'This clears the conversation and compose detections. Your profile preferences stay the same.',
          style: TextStyle(
            color: isDarkMode
                ? const Color(0xFF94A3B8)
                : const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _messages
        ..clear()
        ..add(
          const _ChatMessage(
            text:
                "Hello! I'm your AI recipe assistant. Tell me what you're craving, or tap the camera icon to scan ingredients or a dish — then press send.",
            isUser: false,
          ),
        );
      _conversationHistory.clear();
      _clearComposeDetections();
      _promptController.clear();
    });
  }

  Future<void> _onPromptSubmitted() async {
    if (_isSending) return;

    final userQuery = _promptController.text.trim();
    final merged = _buildMergedPrompt(userQuery);
    if (merged.isEmpty) return;

    final ingredients = _ingredientsForApi();

    setState(() {
      _messages.add(_ChatMessage(text: merged, isUser: true));
      _isSending = true;
      _clearComposeDetections();
      _promptController.clear();
    });
    _scrollToBottom();

    final dietary = widget.dietaryRestrictions.toList();

    try {
      final response = await _aiService.chat(
        message: merged,
        conversationHistory: _conversationHistory,
        dietaryRestrictions: dietary,
        primaryGoal: widget.primaryGoal,
        ingredients: ingredients,
      );

      _conversationHistory
        ..add(ChatMessageModel(role: 'user', content: merged))
        ..add(ChatMessageModel(role: 'assistant', content: response.reply));

      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            text: response.reply,
            isUser: false,
            recipes: response.recipes,
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: e.message, isUser: false));
        _isSending = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _ChatMessage(
            text: 'Unable to reach AI assistant. Please try again.',
            isUser: false,
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _openCaptureOverlay() async {
    final result = await AiCaptureScreen.show(context);
    if (!mounted || result == null) return;

    setState(() {
      switch (result) {
        case AiCaptureIngredientsResult(:final ingredients):
          _composeIngredientsText =
              'Ingredients detected: ${ingredients.join(', ')}';
        case AiCaptureDishResult(:final dish):
          _setDishComposeFrom(dish);
      }
    });
  }

  Future<void> _editComposeText({
    required String title,
    required String initialText,
    required ValueChanged<String?> onSave,
  }) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDarkMode ? const Color(0xFF141414) : Colors.white,
      builder: (context) => _TextAreaEditSheet(
        title: title,
        initialText: initialText,
        isDarkMode: isDarkMode,
      ),
    );
    if (!mounted || result == null) return;
    final trimmed = result.trim();
    onSave(trimmed.isEmpty ? null : trimmed);
  }

  void _editDishes() {
    final text = _composeDishText;
    if (text == null) return;
    _editComposeText(
      title: 'Edit dishes',
      initialText: text,
      onSave: (value) => setState(() => _composeDishText = value),
    );
  }

  void _editIngredients() {
    final text = _composeIngredientsText;
    if (text == null) return;
    _editComposeText(
      title: 'Edit ingredients',
      initialText: text,
      onSave: (value) => setState(() => _composeIngredientsText = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dishText = _composeDishText?.trim();
    final ingredientsText = _composeIngredientsText?.trim();
    final hasDish = dishText != null && dishText.isNotEmpty;
    final hasIngredients =
        ingredientsText != null && ingredientsText.isNotEmpty;

    return Container(
      color: isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFE5E7EB),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length + 1 + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _ChatHeader(
                      isDarkMode: isDarkMode,
                      onReset: _isSending ? null : _resetChat,
                    );
                  }
                  final messageIndex = index - 1;
                  if (_isSending && messageIndex == _messages.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TypingIndicatorBubble(isDarkMode: isDarkMode),
                    );
                  }
                  final message = _messages[messageIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ChatBubble(
                      message: message,
                      isDarkMode: isDarkMode,
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0A0A0A) : Colors.white,
              ),
              child: Column(
                children: [
                  if (hasDish) ...[
                    _ComposeDetectionField(
                      text: dishText,
                      icon: Icons.restaurant_menu_rounded,
                      isDarkMode: isDarkMode,
                      enabled: !_isSending,
                      onEdit: _editDishes,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (hasIngredients) ...[
                    _ComposeDetectionField(
                      text: ingredientsText,
                      icon: Icons.shopping_basket_outlined,
                      isDarkMode: isDarkMode,
                      enabled: !_isSending,
                      onEdit: _editIngredients,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _UserComposeField(
                    controller: _promptController,
                    isDarkMode: isDarkMode,
                    enabled: !_isSending,
                    onCamera: _openCaptureOverlay,
                    onSubmit: _onPromptSubmitted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.isDarkMode, required this.onReset});

  final bool isDarkMode;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF059669),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 17,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI Recommendations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF111827),
              ),
            ),
          ),
          IconButton(
            onPressed: onReset,
            tooltip: 'Reset chat',
            icon: Icon(
              Icons.restart_alt_rounded,
              size: 22,
              color: isDarkMode
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposeDetectionField extends StatelessWidget {
  const _ComposeDetectionField({
    required this.text,
    required this.icon,
    required this.isDarkMode,
    required this.enabled,
    required this.onEdit,
  });

  final String text;
  final IconData icon;
  final bool isDarkMode;
  final bool enabled;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF111827);
    final muted =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF059669).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 11, 0, 11),
            child: Icon(icon, size: 18, color: const Color(0xFF059669)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 11, 4, 11),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: textColor,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: enabled ? onEdit : null,
            tooltip: 'Edit',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.edit_outlined, size: 18, color: muted),
          ),
        ],
      ),
    );
  }
}

class _UserComposeField extends StatelessWidget {
  const _UserComposeField({
    required this.controller,
    required this.isDarkMode,
    required this.enabled,
    required this.onCamera,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isDarkMode;
  final bool enabled;
  final VoidCallback onCamera;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    // Borderless, recessed into the white/dark compose bar.
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF111111) : const Color(0xFFE8EAED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: InkWell(
              onTap: enabled ? onCamera : null,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              child: TextField(
                controller: controller,
                enabled: enabled,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  hintText: 'Ask for recipes...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280),
                  ),
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: enabled ? onSubmit : null,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, size: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.recipes = const [],
  });

  final String text;
  final bool isUser;
  final List<RagRecipeModel> recipes;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isDarkMode});

  final _ChatMessage message;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(left: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

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
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MarkdownReplyBody(
                  markdown: message.text,
                  isDarkMode: isDarkMode,
                ),
                if (message.recipes.isNotEmpty)
                  RecipeSuggestionList(
                    recipes: message.recipes,
                    isDarkMode: isDarkMode,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TextAreaEditSheet extends StatefulWidget {
  const _TextAreaEditSheet({
    required this.title,
    required this.initialText,
    required this.isDarkMode,
  });

  final String title;
  final String initialText;
  final bool isDarkMode;

  @override
  State<_TextAreaEditSheet> createState() => _TextAreaEditSheetState();
}

class _TextAreaEditSheetState extends State<_TextAreaEditSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryText = widget.isDarkMode
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF111827);
    final secondaryText = widget.isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);
    final fieldBg = widget.isDarkMode
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF9FAFB);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Edit the text below, then save.',
              style: TextStyle(fontSize: 12, color: secondaryText),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 6,
              minLines: 4,
              style: TextStyle(fontSize: 14, height: 1.4, color: primaryText),
              decoration: InputDecoration(
                filled: true,
                fillColor: fieldBg,
                hintText: 'Type here...',
                hintStyle: TextStyle(color: secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF059669).withValues(alpha: 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF059669).withValues(alpha: 0.35),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF059669),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_controller.text),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
