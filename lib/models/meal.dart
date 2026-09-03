import 'package:foodhub_mobile/models/recipe.dart';

class MealSuggestionModel {
  const MealSuggestionModel({
    required this.status,
    required this.suggestionDate,
    this.breakfast = const [],
    this.lunch = const [],
    this.dinner = const [],
    this.errorMessage,
  });

  final String status;
  final String suggestionDate;
  final List<RecipeModel> breakfast;
  final List<RecipeModel> lunch;
  final List<RecipeModel> dinner;
  final String? errorMessage;

  bool get isPending => status == 'pending';
  bool get isReady => status == 'ready';
  bool get isFailed => status == 'failed';

  factory MealSuggestionModel.fromJson(Map<String, dynamic> json) {
    List<RecipeModel> slot(String key) {
      final recipes = <RecipeModel>[];
      for (final item in json[key] as List<dynamic>? ?? []) {
        if (item is! Map) continue;
        try {
          recipes.add(RecipeModel.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
      return recipes;
    }
    final rawDate = json['suggestion_date'];
    return MealSuggestionModel(
      status: json['status'] as String? ?? 'pending',
      suggestionDate: rawDate == null ? '' : rawDate.toString(),
      breakfast: slot('breakfast'),
      lunch: slot('lunch'),
      dinner: slot('dinner'),
      errorMessage: json['error_message'] as String?,
    );
  }
}

class MealPlanItemModel {
  const MealPlanItemModel({
    required this.id,
    required this.recipeId,
    required this.servings,
    this.recipe,
  });

  final int id;
  final int recipeId;
  final double servings;
  final RecipeModel? recipe;

  factory MealPlanItemModel.fromJson(Map<String, dynamic> json) {
    final rawRecipe = json['recipe'];
    return MealPlanItemModel(
      id: json['id'] as int,
      recipeId: json['recipe_id'] as int,
      servings: (json['servings'] as num?)?.toDouble() ?? 1,
      recipe: rawRecipe is Map<String, dynamic>
          ? RecipeModel.fromJson(rawRecipe)
          : null,
    );
  }
}

class MealSlotModel {
  const MealSlotModel({
    required this.id,
    required this.slotKey,
    required this.label,
    required this.sortOrder,
    this.items = const [],
  });

  final int id;
  final String slotKey;
  final String label;
  final int sortOrder;
  final List<MealPlanItemModel> items;

  bool get isMain =>
      slotKey == 'breakfast' || slotKey == 'lunch' || slotKey == 'dinner';

  MealSlotModel withItems(List<MealPlanItemModel> items) {
    return MealSlotModel(
      id: id,
      slotKey: slotKey,
      label: label,
      sortOrder: sortOrder,
      items: items,
    );
  }

  factory MealSlotModel.fromJson(Map<String, dynamic> json) {
    return MealSlotModel(
      id: json['id'] as int,
      slotKey: json['slot_key'] as String,
      label: json['label'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      items: [
        for (final item in json['items'] as List<dynamic>? ?? [])
          if (item is Map<String, dynamic>) MealPlanItemModel.fromJson(item),
      ],
    );
  }
}

class MealPlanModel {
  const MealPlanModel({
    required this.id,
    required this.planDate,
    this.slots = const [],
  });

  final int id;
  final String planDate;
  final List<MealSlotModel> slots;

  int get dishCount =>
      slots.fold(0, (sum, slot) => sum + slot.items.length);

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    return MealPlanModel(
      id: json['id'] as int,
      planDate: json['plan_date'] as String,
      slots: [
        for (final slot in json['slots'] as List<dynamic>? ?? [])
          if (slot is Map<String, dynamic>) MealSlotModel.fromJson(slot),
      ],
    );
  }
}

class ShoppingListSourceModel {
  const ShoppingListSourceModel({
    required this.recipeId,
    required this.recipeTitle,
    this.servings = 1,
    this.line = '',
  });

  final int recipeId;
  final String recipeTitle;
  final double servings;
  final String line;

  factory ShoppingListSourceModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListSourceModel(
      recipeId: (json['recipe_id'] as num?)?.toInt() ?? 0,
      recipeTitle: json['recipe_title'] as String? ?? '',
      servings: (json['servings'] as num?)?.toDouble() ?? 1,
      line: json['line'] as String? ?? '',
    );
  }
}

class ShoppingListItemModel {
  const ShoppingListItemModel({
    required this.key,
    required this.name,
    this.quantityText = '',
    this.sources = const [],
  });

  final String key;
  final String name;
  final String quantityText;
  final List<ShoppingListSourceModel> sources;

  String get displayLabel {
    final label = name.isNotEmpty ? name : key;
    final qty = quantityText.trim();
    if (qty.isEmpty) return label;
    return '$qty $label';
  }

  factory ShoppingListItemModel.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?) ??
        (json['text'] as String?) ??
        (json['natural_name'] as String?) ??
        '';
    final servings = (json['servings'] as num?)?.toDouble() ?? 1;
    final quantity = (json['quantity_text'] as String?) ??
        (servings > 1 ? '×${servings % 1 == 0 ? servings.toStringAsFixed(0) : servings}' : '');
    final sources = <ShoppingListSourceModel>[
      for (final source in json['sources'] as List<dynamic>? ?? [])
        if (source is Map)
          ShoppingListSourceModel.fromJson(Map<String, dynamic>.from(source)),
    ];
    if (sources.isEmpty) {
      for (final title in json['recipe_titles'] as List<dynamic>? ?? []) {
        sources.add(
          ShoppingListSourceModel(
            recipeId: 0,
            recipeTitle: title.toString(),
            servings: servings,
            line: name,
          ),
        );
      }
    }
    return ShoppingListItemModel(
      key: (json['key'] as String?)?.trim().isNotEmpty == true
          ? json['key'] as String
          : name,
      name: name,
      quantityText: quantity,
      sources: sources,
    );
  }
}

class ShoppingListGroupModel {
  const ShoppingListGroupModel({
    required this.aisleKey,
    required this.aisle,
    this.items = const [],
  });

  final String aisleKey;
  final String aisle;
  final List<ShoppingListItemModel> items;

  factory ShoppingListGroupModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListGroupModel(
      aisleKey: json['aisle_key'] as String? ?? 'other',
      aisle: json['aisle'] as String? ?? '',
      items: [
        for (final item in json['items'] as List<dynamic>? ?? [])
          if (item is Map)
            ShoppingListItemModel.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}

class ShoppingListModel {
  const ShoppingListModel({
    required this.planDate,
    this.status = 'ready',
    this.groups = const [],
    this.errorMessage,
  });

  final String planDate;
  final String status;
  final List<ShoppingListGroupModel> groups;
  final String? errorMessage;

  bool get isPending => status == 'pending';
  bool get isReady => status == 'ready';

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    var groups = [
      for (final group in json['groups'] as List<dynamic>? ?? [])
        if (group is Map)
          ShoppingListGroupModel.fromJson(Map<String, dynamic>.from(group)),
    ];
    if (groups.isEmpty) {
      final legacy = [
        for (final item in json['items'] as List<dynamic>? ?? [])
          if (item is Map)
            ShoppingListItemModel.fromJson(Map<String, dynamic>.from(item)),
      ];
      if (legacy.isNotEmpty) {
        groups = [
          ShoppingListGroupModel(aisleKey: 'other', aisle: '', items: legacy),
        ];
      }
    }
    return ShoppingListModel(
      planDate: json['plan_date'] as String? ?? '',
      status: json['status'] as String? ?? 'ready',
      groups: groups,
      errorMessage: json['error_message'] as String?,
    );
  }
}
