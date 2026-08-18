import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodhub_mobile/models/recipe.dart';
import 'package:foodhub_mobile/widgets/recipe_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows the recipe title and cooking time', (tester) async {
    const recipe = RecipeModel(
      id: 1,
      title: 'Grilled Salmon',
      directions: ['Season', 'Grill', 'Rest', 'Serve'],
    );

    await tester.pumpWidget(_wrap(const RecipeCard(recipe: recipe)));

    expect(find.text('Grilled Salmon'), findsOneWidget);
    expect(find.text('${recipe.cookingMinutes} min'), findsOneWidget);
  });

  testWidgets('shows calories only when nutrition data is present', (tester) async {
    const withoutCalories = RecipeModel(id: 1, title: 'No calories');
    final withCalories = RecipeModel.fromJson({
      'id': 2,
      'title': 'With calories',
      'nutrition': {
        'per_serving': {'Calories (kcal)': 450.0},
      },
    });

    await tester.pumpWidget(_wrap(const RecipeCard(recipe: withoutCalories)));
    expect(find.byIcon(Icons.local_fire_department_outlined), findsNothing);

    await tester.pumpWidget(_wrap(RecipeCard(recipe: withCalories)));
    expect(find.text('450 cal'), findsOneWidget);
  });

  testWidgets('renders one chip per dietary label', (tester) async {
    const recipe = RecipeModel(
      id: 1,
      title: 'Tagged',
      dietaryRestrictions: ['Vegan', 'Gluten Free'],
    );

    await tester.pumpWidget(_wrap(const RecipeCard(recipe: recipe)));

    // Falls back to the raw (English) tag text since no LangScope is provided.
    expect(find.text('Vegan'), findsOneWidget);
    expect(find.text('Gluten Free'), findsOneWidget);
  });

  testWidgets('invokes onTap when the card is tapped', (tester) async {
    const recipe = RecipeModel(id: 1, title: 'Tappable');
    var tapped = false;

    await tester.pumpWidget(
      _wrap(RecipeCard(recipe: recipe, onTap: () => tapped = true)),
    );
    await tester.tap(find.text('Tappable'));

    expect(tapped, isTrue);
  });

  testWidgets('invokes onAction without triggering onTap', (tester) async {
    const recipe = RecipeModel(id: 1, title: 'Actionable');
    var tapped = false;
    var acted = false;

    await tester.pumpWidget(
      _wrap(
        RecipeCard(
          recipe: recipe,
          onTap: () => tapped = true,
          onAction: () => acted = true,
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));

    expect(acted, isTrue);
    expect(tapped, isFalse);
  });
}
