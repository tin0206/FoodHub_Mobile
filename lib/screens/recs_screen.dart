import 'package:flutter/material.dart';
import 'package:foodhub_mobile/models/ai.dart';
import 'package:foodhub_mobile/services/ai_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/widgets/ai_capture_overlay.dart';

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
  final AiService _aiService = AiService();
  final List<ChatMessageModel> _conversationHistory = [];
  List<String>? _pendingIngredients;
  DishRecognitionModel? _pendingDish;
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
    super.dispose();
  }

  List<DishResultModel> get _pendingDishResults {
    final dish = _pendingDish;
    if (dish == null) return const [];
    if (dish.results.isNotEmpty) {
      return dish.results.take(5).toList();
    }
    if (dish.dishName.isNotEmpty) {
      return [DishResultModel(rank: 1, dishName: dish.dishName, confidence: 1)];
    }
    return dish.suggestedRecipes
        .take(5)
        .map((name) => DishResultModel(rank: 0, dishName: name, confidence: 0))
        .toList();
  }

  bool get _hasPendingContext =>
      (_pendingIngredients?.isNotEmpty ?? false) || _pendingDish != null;

  String _buildApiMessage(String userPrompt) {
    final dishes = _pendingDishResults
        .map((r) => r.dishName)
        .where((name) => name.isNotEmpty)
        .toList();
    if (dishes.isEmpty) return userPrompt;
    return 'Recognized dishes (possible matches): ${dishes.join(', ')}.\n$userPrompt';
  }

  void _clearPendingContext() {
    _pendingIngredients = null;
    _pendingDish = null;
  }

  List<String> _dishNamesFrom(DishRecognitionModel? dish) {
    if (dish == null) return const [];
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

  Future<void> _resetChat() async {
    if (_isSending) return;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF0B1B38) : Colors.white,
        title: Text(
          'Reset chat?',
          style: TextStyle(
            color: isDarkMode
                ? const Color(0xFFF8FAFC)
                : const Color(0xFF111827),
          ),
        ),
        content: Text(
          'This clears the conversation and attached context. Your profile preferences stay the same.',
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
      _clearPendingContext();
      _promptController.clear();
    });
  }

  Future<void> _onPromptSubmitted() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _isSending) return;

    final apiMessage = _buildApiMessage(prompt);
    final ingredients = List<String>.from(_pendingIngredients ?? const []);
    final dishNames = _dishNamesFrom(_pendingDish);

    setState(() {
      _messages.add(
        _ChatMessage(
          text: prompt,
          isUser: true,
          attachedIngredients: ingredients,
          attachedDishes: dishNames,
        ),
      );
      _isSending = true;
    });
    _promptController.clear();

    final dietary = widget.dietaryRestrictions.toList();

    try {
      final response = await _aiService.chat(
        message: apiMessage,
        conversationHistory: _conversationHistory,
        dietaryRestrictions: dietary,
        primaryGoal: widget.primaryGoal,
        ingredients: ingredients,
      );

      _conversationHistory
        ..add(ChatMessageModel(role: 'user', content: apiMessage))
        ..add(ChatMessageModel(role: 'assistant', content: response.reply));

      var reply = response.reply;
      if (response.recipes.isNotEmpty) {
        reply +=
            '\n\nSuggested recipes:\n${response.recipes.map((r) => '• ${r.title}').join('\n')}';
      }

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
        _isSending = false;
        _clearPendingContext();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: e.message, isUser: false));
        _isSending = false;
      });
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
    }
  }

  Future<void> _openCaptureOverlay() async {
    final result = await AiCaptureScreen.show(context);
    if (!mounted || result == null) return;

    setState(() {
      switch (result) {
        case AiCaptureIngredientsResult(:final ingredients):
          _pendingIngredients = ingredients;
        case AiCaptureDishResult(:final dish):
          _pendingDish = dish;
      }
    });
  }

  void _showIngredientsContextDetail() {
    final items = _pendingIngredients;
    if (items == null || items.isEmpty) return;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDarkMode ? const Color(0xFF0B1B38) : Colors.white,
      builder: (context) => _IngredientsContextSheet(
        ingredients: items,
        isDarkMode: isDarkMode,
        onClear: () {
          setState(() => _pendingIngredients = null);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showDishContextDetail() {
    final dish = _pendingDish;
    if (dish == null) return;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDarkMode ? const Color(0xFF0B1B38) : Colors.white,
      builder: (context) => _DishContextSheet(
        results: _pendingDishResults,
        suggestedRecipes: dish.suggestedRecipes,
        isDarkMode: isDarkMode,
        onClear: () {
          setState(() => _pendingDish = null);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDarkMode ? const Color(0xFF07152D) : const Color(0xFFE5E7EB),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Recommendations',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode
                                      ? const Color(0xFFF8FAFC)
                                      : const Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _isSending ? null : _resetChat,
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
                    const SizedBox(height: 14),
                    ..._messages.map(
                      (message) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ChatBubble(
                          message: message,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF07152D)
                    : const Color(0xFFE5E7EB),
                border: Border(
                  top: BorderSide(
                    color: isDarkMode
                        ? const Color(0xFF1E3A5F)
                        : const Color(0xFFD1D5DB),
                  ),
                ),
              ),
              child: Column(
                children: [
                  if (_hasPendingContext)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_pendingIngredients != null &&
                              _pendingIngredients!.isNotEmpty)
                            _ContextPreviewChip(
                              icon: Icons.shopping_basket_outlined,
                              label:
                                  '${_pendingIngredients!.length} ingredient${_pendingIngredients!.length == 1 ? '' : 's'}',
                              subtitle: 'Tap for details',
                              accentColor: const Color(0xFF059669),
                              isDarkMode: isDarkMode,
                              onTap: _showIngredientsContextDetail,
                              onRemove: () =>
                                  setState(() => _pendingIngredients = null),
                            ),
                          if (_pendingDish != null)
                            _ContextPreviewChip(
                              icon: Icons.image_outlined,
                              label:
                                  '${_pendingDishResults.length} dish${_pendingDishResults.length == 1 ? '' : 'es'} recognized',
                              subtitle: 'Tap for details',
                              accentColor: const Color(0xFFA855F7),
                              isDarkMode: isDarkMode,
                              onTap: _showDishContextDetail,
                              onRemove: () =>
                                  setState(() => _pendingDish = null),
                            ),
                        ],
                      ),
                    ),
                  Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF102647)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDarkMode
                            ? const Color(0xFF274A73)
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: InkWell(
                            onTap: _isSending ? null : _openCaptureOverlay,
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
                              controller: _promptController,
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => _onPromptSubmitted(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: _isSending ? null : _onPromptSubmitted,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0xFF059669),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.attachedIngredients = const [],
    this.attachedDishes = const [],
  });

  final String text;
  final bool isUser;
  final List<String> attachedIngredients;
  final List<String> attachedDishes;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (message.attachedIngredients.isNotEmpty)
                      _SentContextBlock(
                        icon: Icons.shopping_basket_outlined,
                        title: 'Ingredients attached',
                        items: message.attachedIngredients,
                      ),
                    if (message.attachedDishes.isNotEmpty) ...[
                      if (message.attachedIngredients.isNotEmpty)
                        const SizedBox(height: 8),
                      _SentContextBlock(
                        icon: Icons.image_outlined,
                        title: 'Dishes recognized',
                        items: message.attachedDishes,
                      ),
                    ],
                    if (message.text.isNotEmpty) ...[
                      if (message.attachedIngredients.isNotEmpty ||
                          message.attachedDishes.isNotEmpty)
                        const SizedBox(height: 8),
                      Text(
                        message.text,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
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
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: isDarkMode
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
              border: isDarkMode
                  ? Border.all(color: const Color(0xFF334155))
                  : null,
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 12,
                height: 1.28,
                color: isDarkMode
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF374151),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SentContextBlock extends StatelessWidget {
  const _SentContextBlock({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ContextPreviewChip extends StatelessWidget {
  const _ContextPreviewChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.isDarkMode,
    required this.onTap,
    required this.onRemove,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final bool isDarkMode;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? accentColor.withValues(alpha: 0.12)
                : accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF111827),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: isDarkMode
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientsContextSheet extends StatelessWidget {
  const _IngredientsContextSheet({
    required this.ingredients,
    required this.isDarkMode,
    required this.onClear,
  });

  final List<String> ingredients;
  final bool isDarkMode;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final primaryText = isDarkMode
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF111827);
    final secondaryText = isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attached ingredients',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sent with your next message as context.',
              style: TextStyle(fontSize: 12, color: secondaryText),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ingredients
                      .map(
                        (item) => Chip(
                          label: Text(item),
                          backgroundColor: isDarkMode
                              ? const Color(0xFF102647)
                              : const Color(0xFFECFDF5),
                          side: const BorderSide(color: Color(0xFF059669)),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                ),
                child: const Text('Remove attachment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DishContextSheet extends StatelessWidget {
  const _DishContextSheet({
    required this.results,
    required this.suggestedRecipes,
    required this.isDarkMode,
    required this.onClear,
  });

  final List<DishResultModel> results;
  final List<String> suggestedRecipes;
  final bool isDarkMode;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final primaryText = isDarkMode
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF111827);
    final secondaryText = isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);
    final cardBg = isDarkMode
        ? const Color(0xFF102647)
        : const Color(0xFFFAF5FF);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recognized dishes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All matches below are equally possible — sent with your next message.',
              style: TextStyle(
                fontSize: 12,
                color: secondaryText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: results.map((item) {
                    final confidence = item.confidence > 0
                        ? '${(item.confidence * 100).round()}% match'
                        : 'Possible match';
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(
                            0xFFA855F7,
                          ).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.restaurant_menu_rounded,
                            size: 18,
                            color: Color(0xFFA855F7),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.dishName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: primaryText,
                                  ),
                                ),
                                Text(
                                  confidence,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (suggestedRecipes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Related recipe ideas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: suggestedRecipes
                    .map(
                      (name) => Chip(
                        label: Text(name, style: const TextStyle(fontSize: 11)),
                        backgroundColor: cardBg,
                        side: BorderSide(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.3),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                ),
                child: const Text('Remove attachment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
