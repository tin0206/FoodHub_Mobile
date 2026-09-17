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
