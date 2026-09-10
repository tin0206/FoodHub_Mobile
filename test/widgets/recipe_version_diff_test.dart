import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/widgets/recs/markdown_reply.dart';
import 'package:foodhub_mobile/widgets/recs/recipe_version_diff.dart';

const originalFriedRice = '''
Easy And Simple Fried Rice
A quick and flavorful dish that combines cooked rice with a savory mix of vegetables and seasonings.

**Nutrition (Per Serving):**
- Calories: 115.2 kcal
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
- Calories: 98.0 kcal
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
- Calories: 90.0 kcal
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

void main() {
  group('parseModifiedRecipeTitle', () {
    test('reads English modified first line', () {
      expect(
        parseModifiedRecipeTitle(modifiedFriedRice),
        'Easy And Simple Fried Rice',
      );
    });

    test('reads Vietnamese modified first line', () {
      const vi = '**🍽️ Phở Bò (Đã chỉnh sửa)**\n\n**🥗 Nguyên liệu:**\n- xương';
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
        hunks.any((h) => h.isHighlight && h.text.contains('kcal')),
        isFalse,
      );
      expect(
        hunks.any((h) => h.isHighlight && h.text.contains('Heat oil')),
        isFalse,
      );
      expect(
        changed.any((h) => h.text.contains('1 teaspoon oil')),
        isTrue,
      );
      expect(
        changed.any((h) => h.text.contains('1 cup onions')),
        isTrue,
      );
      expect(
        changed.any((h) => stripRecipeDecor(h.previous ?? '').contains('1 tablespoon oil')),
        isTrue,
      );
    });

    test('latest modified diffs ingredients against the previous modified, not original', () {
      final vsOriginal = diffRecipeLines(originalFriedRice, secondModifiedFriedRice);
      final vsPrevious = diffRecipeLines(modifiedFriedRice, secondModifiedFriedRice);

      expect(
        vsPrevious.where((h) => h.isHighlight).length,
        lessThan(vsOriginal.where((h) => h.isHighlight).length),
      );
      expect(
        vsPrevious.any((h) => h.isHighlight && h.text.contains('3 cups cooked rice')),
        isTrue,
      );
    });
  });

  group('RecipeDiffBody', () {
    testWidgets('highlights a changed line and shows previous text on tap', (
      tester,
    ) async {
      final hunks = diffRecipeLines(originalFriedRice, modifiedFriedRice);
      await tester.pumpWidget(_wrap(RecipeDiffBody(hunks: hunks, isDarkMode: false)));

      expect(find.text('Tap a highlighted line to see the previous text'), findsNothing);

      await tester.ensureVisible(find.textContaining('1 teaspoon oil'));
      await tester.tap(find.textContaining('1 teaspoon oil'));
      await tester.pumpAndSettle();

      expect(find.text('Changed'), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);
      expect(find.textContaining('1 tablespoon oil'), findsWidgets);
    });

    testWidgets('MarkdownReplyBody uses the previous recipe when current is modified', (
      tester,
    ) async {
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
              (widget.key as ValueKey<String>).value.startsWith('recipe-diff-'),
        ),
        findsWidgets,
      );
    });

    testWidgets('does not enter diff mode without a previous recipe', (tester) async {
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
