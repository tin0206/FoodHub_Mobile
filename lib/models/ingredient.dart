class IngredientUnit {
  const IngredientUnit({required this.unit, required this.gramsPerUnit});

  final String unit;
  final double gramsPerUnit;

  factory IngredientUnit.fromJson(Map<String, dynamic> json) {
    return IngredientUnit(
      unit: json['unit'] as String,
      gramsPerUnit: (json['grams_per_unit'] as num).toDouble(),
    );
  }
}

class IngredientHit {
  const IngredientHit({
    required this.id,
    required this.name,
    required this.naturalName,
    this.units = const [],
  });

  final int id;
  final String name;
  final String naturalName;
  final List<IngredientUnit> units;

  factory IngredientHit.fromJson(Map<String, dynamic> json) {
    return IngredientHit(
      id: json['id'] as int,
      name: json['name'] as String,
      naturalName: json['natural_name'] as String,
      units: (json['units'] as List<dynamic>? ?? [])
          .map((e) => IngredientUnit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class IngredientItemInput {
  const IngredientItemInput({
    required this.mappedId,
    required this.amount,
    required this.unit,
  });

  final int mappedId;
  final double amount;
  final String unit;

  Map<String, dynamic> toJson() => {
        'mapped_id': mappedId,
        'amount': amount,
        'unit': unit,
      };
}

class MappedIngredient {
  const MappedIngredient({
    required this.mappedId,
    required this.mappedName,
    this.naturalName,
    this.amount,
    this.unit,
    this.totalGrams = 0,
    this.gramsPerServing = 0,
  });

  final int mappedId;
  final String mappedName;
  final String? naturalName;
  final double? amount;
  final String? unit;
  final double totalGrams;
  final double gramsPerServing;

  factory MappedIngredient.fromJson(Map<String, dynamic> json) {
    return MappedIngredient(
      mappedId: json['mapped_id'] as int,
      mappedName: (json['mapped_name'] as String?) ?? '',
      naturalName: json['natural_name'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      totalGrams: (json['total_grams'] as num?)?.toDouble() ?? 0,
      gramsPerServing: (json['grams_per_serving'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RecipeNutritionLine {
  const RecipeNutritionLine({
    required this.displayString,
    required this.grams,
    this.nutrition = const {},
  });

  final String displayString;
  final double grams;
  final Map<String, double> nutrition;

  factory RecipeNutritionLine.fromJson(Map<String, dynamic> json) {
    return RecipeNutritionLine(
      displayString: json['display_string'] as String? ?? '',
      grams: (json['grams'] as num?)?.toDouble() ?? 0,
      nutrition: _parseNutrients(json['nutrition']),
    );
  }
}

class RecipeNutrition {
  const RecipeNutrition({
    this.perServing = const {},
    this.total = const {},
    this.ingredients = const [],
  });

  final Map<String, double> perServing;
  final Map<String, double> total;
  final List<RecipeNutritionLine> ingredients;

  static const kcalKey = 'Calories (kcal)';
  static const proteinKey = 'Protein (g)';
  static const carbsKey = 'Carbohydrates (g)';
  static const fatKey = 'Fat (g)';

  double? get kcalPerServing => perServing[kcalKey];
  double? get proteinPerServing => perServing[proteinKey];
  double? get carbsPerServing => perServing[carbsKey];
  double? get fatPerServing => perServing[fatKey];

  List<MapEntry<String, double>> get extraPerServing {
    const macros = {kcalKey, proteinKey, carbsKey, fatKey};
    return perServing.entries.where((e) => !macros.contains(e.key)).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  factory RecipeNutrition.fromJson(Map<String, dynamic> json) {
    return RecipeNutrition(
      perServing: _parseNutrients(json['per_serving']),
      total: _parseNutrients(json['total']),
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => RecipeNutritionLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SelectedCatalogIngredient {
  const SelectedCatalogIngredient({
    required this.id,
    required this.name,
    required this.naturalName,
    required this.units,
    required this.amount,
    required this.unit,
  });

  final int id;
  final String name;
  final String naturalName;
  final List<IngredientUnit> units;
  final double amount;
  final String unit;

  String get displayName => naturalName.isNotEmpty ? naturalName : name;

  IngredientItemInput toInput() => IngredientItemInput(
        mappedId: id,
        amount: amount,
        unit: unit,
      );

  SelectedCatalogIngredient copyWith({
    double? amount,
    String? unit,
    List<IngredientUnit>? units,
  }) {
    return SelectedCatalogIngredient(
      id: id,
      name: name,
      naturalName: naturalName,
      units: units ?? this.units,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
    );
  }

  factory SelectedCatalogIngredient.fromHit(IngredientHit hit) {
    final units = hit.units.isEmpty
        ? const [IngredientUnit(unit: 'g', gramsPerUnit: 1)]
        : hit.units;
    return SelectedCatalogIngredient(
      id: hit.id,
      name: hit.name,
      naturalName: hit.naturalName,
      units: units,
      amount: 1,
      unit: units.first.unit,
    );
  }

  factory SelectedCatalogIngredient.fromMapped(MappedIngredient item) {
    final unit = (item.unit != null && item.unit!.isNotEmpty) ? item.unit! : 'g';
    return SelectedCatalogIngredient(
      id: item.mappedId,
      name: item.mappedName,
      naturalName: (item.naturalName != null && item.naturalName!.isNotEmpty)
          ? item.naturalName!
          : item.mappedName,
      units: [
        IngredientUnit(unit: unit, gramsPerUnit: 1),
        if (unit != 'g') const IngredientUnit(unit: 'g', gramsPerUnit: 1),
      ],
      amount: item.amount != null && item.amount! > 0 ? item.amount! : 1,
      unit: unit,
    );
  }
}

Map<String, double> _parseNutrients(dynamic value) {
  if (value is! Map) return const {};
  final result = <String, double>{};
  value.forEach((key, raw) {
    if (raw is num) result[key.toString()] = raw.toDouble();
  });
  return result;
}
