import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/widgets/recs/markdown_reply.dart';
import 'package:foodhub_mobile/widgets/recs/recipe_version_diff.dart';

const originalFriedRice = '''
Easy And Simple Fried Rice
A quick and flavorful dish that combines cooked rice with a savory mix of vegetables and seasonings.

**Nutrition (Per Serving):**
- Calories: 115.2 cal
- Protein: 2.68 g
- Carbohydrates: 18.41 g
- Fat: 3.46 g

**Ingredients (Servings: 3):**
- 1 tablespoon oil
- 3 tablespoons fresh ginger, chopped
- 2 cups onions, thinly sliced
- 4 cups cooked rice, chilled

**Cooking Steps:**
1. Heat oil in a large nonstick skillet over medium heat.
2. Add sliced onion to pan; reduce heat to medium-low.
3. Add rice; cook 4 minutes or until heated, stirring frequently.
''';

const modifiedFriedRice = '''
**🍽️ Easy And Simple Fried Rice (Modified)**

A lighter version with less oil and onion.

**🔥 Nutrition (Per Serving):**
- Calories: 98.0 cal
- Protein: 2.68 g
- Carbohydrates: 18.41 g
- Fat: 2.10 g

**🥗 Ingredients (Servings: 3):**
- 1 teaspoon oil
- 3 tablespoons fresh ginger, chopped
- 1 cup onions, thinly sliced
- 4 cups cooked rice, chilled

**👨‍🍳 Cooking Steps:**
1. Heat oil in a large nonstick skillet over medium heat.
2. Add sliced onion to pan; reduce heat to medium-low.
3. Add rice; cook 4 minutes or until heated, stirring frequently.
''';

const secondModifiedFriedRice = '''
**🍽️ Easy And Simple Fried Rice (Modified)**

A lighter version with less oil and onion.

**🔥 Nutrition (Per Serving):**
- Calories: 90.0 cal
- Protein: 2.68 g
- Carbohydrates: 18.41 g
- Fat: 1.80 g

**🥗 Ingredients (Servings: 2):**
- 1 teaspoon oil
- 3 tablespoons fresh ginger, chopped
- 1 cup onions, thinly sliced
- 3 cups cooked rice, chilled

**👨‍🍳 Cooking Steps:**
1. Heat oil in a large nonstick skillet over medium heat.
2. Add sliced onion to pan; reduce heat to medium-low.
3. Add rice; cook 4 minutes or until heated, stirring frequently.
''';

const unrelatedRecipe = '''
**Spaghetti Carbonara**

**Ingredients (Servings: 2):**
- 200g spaghetti
- 2 eggs

**Cooking Steps:**
1. Boil pasta.
2. Toss with eggs.
''';

Widget _wrap(Widget child, {String lang = 'en'}) {
  return MaterialApp(
    home: LangScope(
      lang: lang,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

const scaledOriginal = '''
Easy And Simple Fried Rice

NUTRITION (Per Serving)

Calories: 345.6 kcal
Protein: 8.04 g
Carbs: 55.22 g
Fat: 10.37 g
Ingredients (Servings: 3)

1 tablespoon oil
3 tablespoons fresh ginger, chopped
2 tablespoons garlic, minced
2 cups onions, thinly sliced
1/4 teaspoon salt
4 cups cooked rice, chilled
2 large eggs, lightly beaten
1/4 cup green onion, chopped
2 tablespoons soy sauce
2 teaspoons sesame oil
COOKING STEPS

Heat oil in a large nonstick skillet over medium heat.
''';

const scaledModified = '''
🍽️ Easy And Simple Fried Rice (Modified)

Thanks for the update! We've adjusted the recipe to reflect the new ingredient quantities.

🔥 Nutrition (Per Serving):

Calories (kcal): 345.6
Protein (g): 8.04
Fat (g): 10.37
Carbohydrates (g): 55.22
🥗 Ingredients (Servings: 6):

1 1/3 tablespoon oil
6 tablespoons fresh ginger, chopped
2 3/4 tablespoons garlic, minced
4 cups onions, thinly sliced
1/2 teaspoon salt
8 cups cooked rice, chilled
4 large eggs, lightly beaten
1/2 cup green onion, chopped
2 3/4 tablespoons soy sauce
2 3/4 teaspoons sesame oil
👨‍🍳 Cooking Steps:

Heat 1 1/3 tablespoon oil in a large nonstick skillet over medium heat.
''';

const duplicatedModified = '''
🍽️ Easy And Simple Fried Rice (Modified)

Thanks for the update! We've adjusted the recipe to reflect the new ingredient quantities.

🔥 Nutrition (Per Serving):

Calories (kcal): 345.6
🥗 Ingredients (Servings: 6):


1 tablespoon oil

3 tablespoons fresh ginger, chopped

2 tablespoons garlic, minced

2 cups onions, thinly sliced

1/4 teaspoon salt

4 cups cooked rice, chilled

2 large eggs, lightly beaten

1/4 cup green onion, chopped

2 tablespoons soy sauce

1 1/3 tablespoon oil

6 tablespoons fresh ginger, chopped

2 3/4 tablespoons garlic, minced

4 cups onions, thinly sliced

1/2 teaspoon salt

8 cups cooked rice, chilled

4 large eggs, lightly beaten

1/2 cup green onion, chopped

2 3/4 tablespoons soy sauce

2 3/4 teaspoons sesame oil
👨‍🍳 Cooking Steps:

Heat 1 1/3 tablespoon oil in a large nonstick skillet over medium heat.
''';

const swappedIngredient = '''
🍽️ Easy And Simple Fried Rice (Modified)

🥗 Ingredients (Servings: 3):
1 teaspoon oil
3 tablespoons fresh ginger, chopped
2 tablespoons garlic, minced
2 cups onions, thinly sliced
1/4 teaspoon salt
4 cups cooked rice, chilled
2 large eggs, lightly beaten
1/4 cup green onion, chopped
2 tablespoons soy sauce
1/4 cup cilantro, chopped
👨‍🍳 Cooking Steps:
1. Heat oil.
''';

void main() {
  group('parseModifiedRecipeTitle', () {
    test('reads English modified first line', () {
      expect(
        parseModifiedRecipeTitle(modifiedFriedRice),
        'Easy And Simple Fried Rice',
      );
    });

    test('reads Vietnamese modified first line', () {
      const vi =
          '**🍽️ Phở Bò (Đã chỉnh sửa)**\n\n**🥗 Nguyên liệu:**\n- xương';
      expect(parseModifiedRecipeTitle(vi), 'Phở Bò');
    });

    test('does not treat the original chat card as modified', () {
      expect(parseModifiedRecipeTitle(originalFriedRice), isNull);
      expect(isModifiedRecipeMarkdown(originalFriedRice), isFalse);
    });
  });

  group('isDetailRecipeMarkdown', () {
    test('matches the original screenshot-style recipe card', () {
      expect(isDetailRecipeMarkdown(originalFriedRice), isTrue);
    });

    test('matches a modified recipe body', () {
      expect(isDetailRecipeMarkdown(modifiedFriedRice), isTrue);
    });
  });

  group('findPreviousRecipeMarkdown', () {
    test('compares the latest modified recipe with the original card', () {
      final messages = <({bool isUser, String text})>[
        (isUser: false, text: originalFriedRice),
        (isUser: true, text: 'Make it lighter'),
        (isUser: false, text: modifiedFriedRice),
      ];

      expect(
        findPreviousRecipeMarkdown(messages: messages, currentIndex: 2),
        originalFriedRice,
      );
    });

    test('prefers the previous modified version over the original', () {
      final messages = <({bool isUser, String text})>[
        (isUser: false, text: originalFriedRice),
        (isUser: false, text: modifiedFriedRice),
        (isUser: false, text: secondModifiedFriedRice),
      ];

      expect(
        findPreviousRecipeMarkdown(messages: messages, currentIndex: 2),
        modifiedFriedRice,
      );
    });

    test('skips unrelated recipes and user messages', () {
      final messages = <({bool isUser, String text})>[
        (isUser: false, text: originalFriedRice),
        (isUser: false, text: unrelatedRecipe),
        (isUser: true, text: '**🍽️ Easy And Simple Fried Rice (Modified)**'),
        (isUser: false, text: modifiedFriedRice),
      ];

      expect(
        findPreviousRecipeMarkdown(messages: messages, currentIndex: 3),
        originalFriedRice,
      );
    });

    test('returns null when the current message is not a modified recipe', () {
      final messages = <({bool isUser, String text})>[
        (isUser: false, text: originalFriedRice),
      ];
      expect(
        findPreviousRecipeMarkdown(messages: messages, currentIndex: 0),
        isNull,
      );
    });
  });

  group('diffRecipeLines', () {
    test('does not flag emoji/suffix-only header differences', () {
      const originalHeader = '**Nutrition (Per Serving):**';
      const modifiedHeader = '**🔥 Nutrition (Per Serving):**';
      final hunks = diffRecipeLines(originalHeader, modifiedHeader);
      expect(hunks, hasLength(1));
      expect(hunks.single.op, RecipeDiffOp.equal);
    });

    test('highlights only changed ingredient lines, not nutrition', () {
      final hunks = diffRecipeLines(originalFriedRice, modifiedFriedRice);
      final changed = hunks.where((h) => h.op == RecipeDiffOp.changed).toList();
      expect(
        hunks.any((h) => h.isHighlight && h.text.contains('cal')),
        isFalse,
      );
      expect(
        hunks.any((h) => h.isHighlight && h.text.contains('Heat oil')),
        isFalse,
      );
      expect(changed.any((h) => h.text.contains('1 teaspoon oil')), isTrue);
      expect(changed.any((h) => h.text.contains('1 cup onions')), isTrue);
      expect(
        changed.any(
          (h) =>
              stripRecipeDecor(h.previous ?? '').contains('1 tablespoon oil'),
        ),
        isTrue,
      );
    });

    test(
      'latest modified diffs ingredients against the previous modified, not original',
      () {
        final vsOriginal = diffRecipeLines(
          originalFriedRice,
          secondModifiedFriedRice,
        );
        final vsPrevious = diffRecipeLines(
          modifiedFriedRice,
          secondModifiedFriedRice,
        );

        expect(
          vsPrevious.where((h) => h.isHighlight).length,
          lessThan(vsOriginal.where((h) => h.isHighlight).length),
        );
        expect(
          vsPrevious.any(
            (h) => h.isHighlight && h.text.contains('3 cups cooked rice'),
          ),
          isTrue,
        );
      },
    );
    test('marks every scaled ingredient as changed, not delete-then-add', () {
      final hunks = diffRecipeLines(scaledOriginal, scaledModified);
      final highlights = hunks.where((h) => h.isHighlight).toList();
      expect(highlights, hasLength(10));
      expect(highlights.every((h) => h.op == RecipeDiffOp.changed), isTrue);
      final oil = highlights.firstWhere(
        (h) => h.text.contains('1 1/3 tablespoon oil'),
      );
      expect(oil.previous, contains('1 tablespoon oil'));
      final sesame = highlights.firstWhere(
        (h) => h.text.contains('2 3/4 teaspoons sesame oil'),
      );
      expect(sesame.previous, contains('2 teaspoons sesame oil'));
      expect(
        hunks.any((h) => h.isHighlight && h.text.contains('Heat 1 1/3')),
        isFalse,
      );
    });

    test(
      'treats duplicated old amounts plus new amounts as updates of the same foods',
      () {
        final hunks = diffRecipeLines(scaledOriginal, duplicatedModified);
        final highlights = hunks.where((h) => h.isHighlight).toList();
        expect(
          highlights.any(
            (h) => h.op == RecipeDiffOp.removed || h.op == RecipeDiffOp.added,
          ),
          isFalse,
        );
        expect(highlights, hasLength(10));
        expect(
          hunks.any((h) => h.isHighlight && h.text.trim() == '1 tablespoon oil'),
          isFalse,
        );
        final oil = highlights.firstWhere(
          (h) => h.text.contains('1 1/3 tablespoon oil'),
        );
        expect(oil.previous, contains('1 tablespoon oil'));
      },
    );

    test('still reports a real added and removed ingredient', () {
      final hunks = diffRecipeLines(scaledOriginal, swappedIngredient);
      final highlights = hunks.where((h) => h.isHighlight).toList();
      expect(
        highlights.any(
          (h) => h.op == RecipeDiffOp.removed && h.text.contains('sesame oil'),
        ),
        isTrue,
      );
      expect(
        highlights.any(
          (h) => h.op == RecipeDiffOp.added && h.text.contains('cilantro'),
        ),
        isTrue,
      );
      expect(
        highlights.any(
          (h) =>
              h.op == RecipeDiffOp.changed && h.text.contains('1 teaspoon oil'),
        ),
        isTrue,
      );
    });
  });

  group('RecipeDiffBody', () {
    testWidgets('highlights a changed line and shows previous text on tap', (
      tester,
    ) async {
      final hunks = diffRecipeLines(originalFriedRice, modifiedFriedRice);
      await tester.pumpWidget(
        _wrap(RecipeDiffBody(hunks: hunks, isDarkMode: false)),
      );

      expect(
        find.text('Tap a highlighted line to see the previous text'),
        findsNothing,
      );

      await tester.ensureVisible(find.textContaining('1 teaspoon oil'));
      await tester.tap(find.textContaining('1 teaspoon oil'));
      await tester.pumpAndSettle();

      expect(find.text('Changed'), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);
      expect(find.textContaining('1 tablespoon oil'), findsWidgets);
    });

    testWidgets(
      'MarkdownReplyBody uses the previous recipe when current is modified',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            MarkdownReplyBody(
              markdown: modifiedFriedRice,
              isDarkMode: false,
              previousMarkdown: originalFriedRice,
            ),
          ),
        );

        expect(find.byType(RecipeDiffBody), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key as ValueKey<String>).value.startsWith(
                  'recipe-diff-',
                ),
          ),
          findsWidgets,
        );
      },
    );

    testWidgets('does not enter diff mode without a previous recipe', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const MarkdownReplyBody(
            markdown: modifiedFriedRice,
            isDarkMode: false,
          ),
        ),
      );

      expect(find.byType(RecipeDiffBody), findsNothing);
      expect(find.textContaining('Easy And Simple Fried Rice'), findsWidgets);
    });
  });
}
