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
