/// Search/filter chips. Hardcoded — not loaded from the API.
const kMealTypeCategories = <(String, String)>[
  ('🌅', 'Breakfast'),
  ('🥗', 'Lunch'),
  ('🍝', 'Dinner'),
];

const kDietaryCategories = <(String, String)>[
  ('🍸', 'Alcoholic'),
  ('🥤', 'Beverage'),
  ('🥛', 'Dairy Free'),
  ('🌾', 'Gluten Free'),
  ('🥜', 'Nut Free'),
  ('🐟', 'Pescetarian'),
  ('🌱', 'Vegan'),
  ('🥦', 'Vegetarian'),
];

const kSearchCategoryChips = <(String, String)>[
  ...kMealTypeCategories,
  ...kDietaryCategories,
];

const kDietaryLabels = <String>[
  'Alcoholic',
  'Beverage',
  'Dairy Free',
  'Gluten Free',
  'Nut Free',
  'Pescetarian',
  'Vegan',
  'Vegetarian',
];

const kRecipeLabelOptions = <String>[
  'Breakfast',
  'Lunch',
  'Dinner',
  ...kDietaryLabels,
];

bool isDietaryCategory(String label) => kDietaryLabels.contains(label);

/// Same windows as the home greeting: morning → Breakfast, afternoon → Lunch,
/// evening → Dinner.
String defaultMealCategory([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return 'Breakfast';
  if (hour < 17) return 'Lunch';
  return 'Dinner';
}

/// Search uses `q` only: selected chips plus typed text,
/// e.g. Dinner + Vegan + cake → "Dinner Vegan cake".
String? recipeSearchQuery({
  required String text,
  Iterable<String> categories = const [],
}) {
  final selected = {for (final c in categories) c.trim()}.difference({''});
  final chips = [
    for (final (_, label) in kSearchCategoryChips)
      if (selected.contains(label)) label,
  ];
  final typed = text.trim();
  final parts = [...chips, if (typed.isNotEmpty) typed];
  if (parts.isEmpty) return null;
  return parts.join(' ');
}
