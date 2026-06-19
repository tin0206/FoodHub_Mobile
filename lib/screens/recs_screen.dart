import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          "Hello! I'm your AI recipe assistant. Tell me what you're craving, or use the buttons below to upload a photo.",
      isUser: false,
    ),
  ];

  final Set<String> _selectedFilters = {};

  List<String> get _allFilters => [
    if (widget.primaryGoal.isNotEmpty) widget.primaryGoal,
    ...widget.dietaryRestrictions,
  ];

  void _toggleFilter(String tag) {
    setState(() {
      if (_selectedFilters.contains(tag)) {
        _selectedFilters.remove(tag);
      } else {
        _selectedFilters.add(tag);
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _onPromptSubmitted() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: prompt, isUser: true));
      _messages.add(
        _ChatMessage(text: _buildDefaultReply(prompt), isUser: false),
      );
    });

    _promptController.clear();
  }

  Future<void> _onAttachIngredients() async {
    final scannedIngredients = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(builder: (_) => const _IngredientsScannerScreen()),
    );

    if (!mounted || scannedIngredients == null || scannedIngredients.isEmpty) {
      return;
    }

    final ingredientText = scannedIngredients.join(', ');
    setState(() {
      _messages.add(
        _ChatMessage(
          text: 'Ingredients scanned: $ingredientText',
          isUser: true,
        ),
      );
      _messages.add(
        _ChatMessage(
          text:
              'Awesome, I detected ${scannedIngredients.length} ingredients. I can build recipe ideas from these now: ${scannedIngredients.take(6).join(', ')}. Want quick recipes or full meal prep?',
          isUser: false,
        ),
      );
    });
  }

  Future<void> _onAttachPhoto() async {
    final source = await _showImageSourcePicker(
      title: 'Dish Photo',
      cameraLabel: 'Take photo',
      galleryLabel: 'Upload from gallery',
    );
    if (source == null) return;

    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 86,
      maxWidth: 1600,
    );
    if (!mounted || file == null) return;

    final recipeReply = _buildDishPhotoReply(file);
    setState(() {
      _messages.add(
        _ChatMessage(
          text: 'I uploaded a dish photo (${file.name}).',
          isUser: true,
        ),
      );
      _messages.add(_ChatMessage(text: recipeReply, isUser: false));
    });
  }

  String _buildDefaultReply(String prompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('quick') ||
        lower.contains('15') ||
        lower.contains('fast')) {
      return 'Got it. I can suggest 3 quick recipes under 20 minutes using simple ingredients. Want breakfast, lunch, or dinner options first?';
    }

    if (lower.contains('vegan') ||
        lower.contains('vegetarian') ||
        lower.contains('gluten') ||
        lower.contains('dairy') ||
        lower.contains('egg') ||
        lower.contains('nut')) {
      return 'Great preference. I will prioritize recipes that match your dietary restrictions and keep them balanced. Want low-calorie, high-protein, or budget-friendly choices?';
    }

    return 'Nice request. I can generate recipe ideas with ingredient list, cook time, and step-by-step instructions. Tell me your preferred meal type and total cooking time.';
  }

  Future<ImageSource?> _showImageSourcePicker({
    required String title,
    required String cameraLabel,
    required String galleryLabel,
  }) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(cameraLabel),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(galleryLabel),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildDishPhotoReply(XFile file) {
    final name = file.name.toLowerCase();

    if (name.contains('pizza')) {
      return 'This looks like pizza. Recommended recipes: Margherita Pizza, Mushroom Pizza, and Spicy Pepperoni Pizza. Want the easiest one first?';
    }

    if (name.contains('salad')) {
      return 'This dish looks like a fresh salad. You can try Greek Salad, Chicken Caesar Salad, or Quinoa Avocado Salad.';
    }

    if (name.contains('pasta') || name.contains('spaghetti')) {
      return 'This looks like a pasta dish. Recipe ideas: Creamy Mushroom Pasta, Aglio e Olio, and Tomato Basil Spaghetti.';
    }

    const fallbackRecipes = [
      'Garlic Butter Chicken Bowl',
      'One-pan Veggie Stir-fry',
      'Tomato Herb Rice with Protein',
      'Quick Soup and Toast Combo',
    ];
    final seed = file.name.hashCode.abs();
    final random = Random(seed);
    final picks = <String>{};
    while (picks.length < 3) {
      picks.add(fallbackRecipes[random.nextInt(fallbackRecipes.length)]);
    }

    return 'Dish recognized. Suggested matching recipes: ${picks.join(', ')}. If you want, I can narrow these by calories or cooking time.';
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
                              SizedBox(height: 2),
                              Text(
                                'Powered by LLM',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDarkMode
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_allFilters.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _allFilters
                            .map(
                              (tag) => _TagChip(
                                tag,
                                isDarkMode: isDarkMode,
                                isSelected: _selectedFilters.contains(tag),
                                onTap: () => _toggleFilter(tag),
                              ),
                            )
                            .toList(),
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _onAttachIngredients,
                          icon: const Icon(
                            Icons.shopping_basket_outlined,
                            size: 18,
                          ),
                          label: const Text('Ingredients'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: isDarkMode
                                ? const Color(0xFF0B1B38)
                                : const Color(0xFFF3F4F6),
                            foregroundColor: isDarkMode
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF374151),
                            side: BorderSide(
                              color: isDarkMode
                                  ? const Color(0xFF274A73)
                                  : const Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _onAttachPhoto,
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: const Text('Dish photo'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: isDarkMode
                                ? const Color(0xFF0B1B38)
                                : const Color(0xFFF3F4F6),
                            foregroundColor: isDarkMode
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF374151),
                            side: BorderSide(
                              color: isDarkMode
                                  ? const Color(0xFF274A73)
                                  : const Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 38,
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
                        Expanded(
                          child: TextField(
                            controller: _promptController,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF111827),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ask for recipes...',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF6B7280),
                              ),
                              isDense: true,
                              filled: false,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            onSubmitted: (_) => _onPromptSubmitted(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: _onPromptSubmitted,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFF059669),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send,
                                size: 14,
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

class _TagChip extends StatelessWidget {
  const _TagChip(
    this.label, {
    required this.isDarkMode,
    this.onTap,
    this.isSelected = false,
  });

  final String label;
  final bool isDarkMode;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD1FAE5)
              : (isDarkMode
                    ? const Color(0xFF102647)
                    : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF059669)
                : (isDarkMode
                      ? const Color(0xFF274A73)
                      : const Color(0xFFD1D5DB)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? const Color(0xFF065F46)
                : (isDarkMode
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF4B5563)),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isDarkMode});

  final _ChatMessage message;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.28,
                  color: Color(0xFF065F46),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 27,
          height: 27,
          decoration: const BoxDecoration(
            color: Color(0xFF059669),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 15,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFFD1D5DB),
              ),
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

class _IngredientsScannerScreen extends StatefulWidget {
  const _IngredientsScannerScreen();

  @override
  State<_IngredientsScannerScreen> createState() =>
      _IngredientsScannerScreenState();
}

class _IngredientsScannerScreenState extends State<_IngredientsScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _ingredients = <String>[];

  Future<void> _scanWithSource(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 86,
      maxWidth: 1600,
    );
    if (!mounted || image == null) return;

    final detected = _mockDetectIngredients(image.name);
    if (detected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No ingredients detected. Try another photo.'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _DetectedIngredientsSheet(
        initialItems: detected,
        sourceName: image.name,
      ),
    );

    if (!mounted || selected == null || selected.isEmpty) return;

    setState(() {
      for (final item in selected) {
        if (!_ingredients.contains(item)) {
          _ingredients.add(item);
        }
      }
    });
  }

  List<String> _mockDetectIngredients(String name) {
    final lower = name.toLowerCase();
    final output = <String>[];

    void addIf(bool condition, String ingredient) {
      if (condition) output.add(ingredient);
    }

    addIf(lower.contains('egg'), 'Egg');
    addIf(lower.contains('tomato'), 'Tomato');
    addIf(lower.contains('onion'), 'Onion');
    addIf(lower.contains('chicken'), 'Chicken');
    addIf(lower.contains('beef'), 'Beef');
    addIf(lower.contains('rice'), 'Rice');
    addIf(lower.contains('milk'), 'Milk');
    addIf(lower.contains('cheese'), 'Cheese');
    addIf(lower.contains('carrot'), 'Carrot');
    addIf(lower.contains('potato'), 'Potato');
    addIf(lower.contains('tofu'), 'Tofu');
    addIf(lower.contains('shrimp'), 'Shrimp');

    if (output.isEmpty) {
      output.addAll(const ['Tomato', 'Onion', 'Garlic']);
    }

    return output;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingredient Scanner')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scan ingredients one by one',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Use camera for live capture or upload from gallery. You can scan multiple times and confirm detected ingredients.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _scanWithSource(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Scan with camera'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _scanWithSource(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Upload image'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Detected ingredients',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: _ingredients.isEmpty
                      ? const Center(
                          child: Text(
                            'No ingredients yet. Start scanning.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _ingredients
                                .map(
                                  (item) => Chip(
                                    label: Text(item),
                                    onDeleted: () {
                                      setState(() {
                                        _ingredients.remove(item);
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _ingredients.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_ingredients),
                  child: Text(
                    _ingredients.isEmpty
                        ? 'Scan ingredients first'
                        : 'Use ${_ingredients.length} ingredients',
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

class _DetectedIngredientsSheet extends StatefulWidget {
  const _DetectedIngredientsSheet({
    required this.initialItems,
    required this.sourceName,
  });

  final List<String> initialItems;
  final String sourceName;

  @override
  State<_DetectedIngredientsSheet> createState() =>
      _DetectedIngredientsSheetState();
}

class _DetectedIngredientsSheetState extends State<_DetectedIngredientsSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialItems.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 4, 14, max(bottomInset, 12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm detected ingredients',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.sourceName,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 10),
            ...widget.initialItems.map(
              (item) => CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(item),
                value: _selected.contains(item),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selected.add(item);
                    } else {
                      _selected.remove(item);
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_selected.toList()),
                child: const Text('Add selected'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
