import 'package:flutter/material.dart';

class RecsScreen extends StatefulWidget {
  const RecsScreen({super.key});

  @override
  State<RecsScreen> createState() => _RecsScreenState();
}

class _RecsScreenState extends State<RecsScreen> {
  final TextEditingController _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _onPromptSubmitted() {
    _showComingSoon('AI recommendation request');
  }

  void _onQuickPromptTap(String prompt) {
    _showComingSoon('Quick prompt: $prompt');
  }

  void _onAttachIngredients() {
    _showComingSoon('Attach ingredient list');
  }

  void _onAttachPhoto() {
    _showComingSoon('Upload ingredient photo');
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be implemented later.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final quickPrompts = const [
      'High protein meals under 500 calories',
      'Vegetarian dinner ideas',
      'Quick 15-minute breakfast',
      'Keto-friendly lunch options',
      'Gluten-free dinner recipes',
      'Vegan meal prep ideas',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Recipe Recommendations',
                      style: TextStyle(
                        fontSize: 30 / 2,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Powered by Large Language Model',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _TagChip('Dairy Free'),
            _TagChip('Egg Free'),
            _TagChip('Gluten Free'),
            _TagChip('Nut Free'),
            _TagChip('Vegan'),
            _TagChip('Vegetarian'),
            _TagChip('Pescetarian'),
          ],
        ),
        const SizedBox(height: 14),
        Text('Try asking:', style: TextStyle(color: colors.onSurfaceVariant)),
        const SizedBox(height: 8),
        ...quickPrompts.map(
          (prompt) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(prompt),
              onTap: () => _onQuickPromptTap(prompt),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
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
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Hello! I'm your AI recipe recommendation assistant. Tell me what you're in the mood for, your dietary preferences, or upload a photo.",
                  style: TextStyle(color: colors.onSurface),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              onPressed: _onAttachIngredients,
              icon: const Icon(Icons.science_outlined),
            ),
            IconButton(
              onPressed: _onAttachPhoto,
              icon: const Icon(Icons.image_outlined),
            ),
            Expanded(
              child: TextField(
                controller: _promptController,
                decoration: const InputDecoration(
                  hintText: 'Ask for recommendations...',
                ),
                onSubmitted: (_) => _onPromptSubmitted(),
              ),
            ),
            IconButton(
              onPressed: _onPromptSubmitted,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Ingredients — detect what\'s in your fridge · Dish photo — find matching recipes',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
    );
  }
}
