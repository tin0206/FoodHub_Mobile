import 'package:foodhub_mobile/models/meal.dart';
import 'package:foodhub_mobile/services/api_client.dart';
import 'package:foodhub_mobile/services/session_service.dart';

String localIsoDate([DateTime? value]) {
  final now = value ?? DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class MealService {
  MealService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  String? get _lang {
    final language = SessionService.instance.currentUser?.language;
    if (language == null || language.isEmpty) return null;
    return language;
  }

  Map<String, String> _query([Map<String, String>? extra]) {
    final query = <String, String>{...?extra};
    final lang = _lang;
    if (lang != null && !query.containsKey('lang')) {
      query['lang'] = lang;
    }
    return query;
  }

  Future<MealSuggestionModel> getTodaySuggestions({String? date}) async {
    final data = await _api.get(
      '/meal-suggestions/today',
      query: _query({
        if (date != null && date.isNotEmpty) 'suggestion_date': date,
      }),
    );
    return MealSuggestionModel.fromJson(data as Map<String, dynamic>);
  }

  Future<MealSuggestionModel> refreshTodaySuggestions({
    String? date,
    List<int> extraExcludeIds = const [],
  }) async {
    final data = await _api.post(
      '/meal-suggestions/today/refresh',
      query: _query({
        if (date != null && date.isNotEmpty) 'suggestion_date': date,
      }),
      body: {'extra_exclude_ids': extraExcludeIds},
    );
    return MealSuggestionModel.fromJson(data as Map<String, dynamic>);
  }

  Future<MealPlanModel> getPlan({String? date}) async {
    final planDate = date ?? localIsoDate();
    final data = await _api.get(
      '/meal-plans/$planDate',
      query: _query(),
    );
    return MealPlanModel.fromJson(data as Map<String, dynamic>);
  }

  Future<MealPlanModel> replacePlan(
    MealPlanModel plan, {
    String? date,
  }) async {
    final planDate = date ?? plan.planDate;
    final data = await _api.put(
      '/meal-plans/$planDate',
      query: _query(),
      body: {
        'slots': [
          for (final slot in plan.slots)
            {
              'slot_key': slot.slotKey,
              'label': slot.label,
              'sort_order': slot.sortOrder,
              'items': [
                for (final item in slot.items)
                  {
                    'recipe_id': item.recipeId,
                    'servings': item.servings,
                  },
              ],
            },
        ],
      },
    );
    return MealPlanModel.fromJson(data as Map<String, dynamic>);
  }

  Future<MealPlanModel> addRecipeToSlot({
    required String slotKey,
    required int recipeId,
    double servings = 1,
    String? date,
  }) async {
    final plan = await getPlan(date: date);
    final slots = [
      for (final slot in plan.slots)
        MealSlotModel(
          id: slot.id,
          slotKey: slot.slotKey,
          label: slot.label,
          sortOrder: slot.sortOrder,
          items: [
            ...slot.items,
            if (slot.slotKey == slotKey)
              MealPlanItemModel(
                id: 0,
                recipeId: recipeId,
                servings: servings,
              ),
          ],
        ),
    ];
    return replacePlan(
      MealPlanModel(id: plan.id, planDate: plan.planDate, slots: slots),
      date: date,
    );
  }

  Future<MealPlanModel> addExtraSlot({
    required String label,
    String? date,
  }) async {
    final planDate = date ?? localIsoDate();
    final data = await _api.post(
      '/meal-plans/$planDate/slots',
      query: _query(),
      body: {'label': label},
    );
    return MealPlanModel.fromJson(data as Map<String, dynamic>);
  }

  Future<MealPlanModel> deleteSlot({
    required int slotId,
    String? date,
  }) async {
    final planDate = date ?? localIsoDate();
    final data = await _api.delete(
      '/meal-plans/$planDate/slots/$slotId',
      query: _query(),
    );
    if (data is Map<String, dynamic>) {
      return MealPlanModel.fromJson(data);
    }
    return getPlan(date: planDate);
  }

  Future<ShoppingListModel> getShoppingList({String? date}) async {
    final planDate = date ?? localIsoDate();
    final data = await _api.get(
      '/meal-plans/$planDate/shopping-list',
      query: _query(),
    );
    return ShoppingListModel.fromJson(data as Map<String, dynamic>);
  }
}
