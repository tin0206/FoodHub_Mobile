import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';

/// Pumps a minimal tree and captures [S.of] for the given [lang].
/// Passing `null` omits the [LangScope] ancestor entirely, to exercise the
/// "en" fallback.
Future<S> stringsFor(WidgetTester tester, String? lang) async {
  late S captured;
  final probe = Builder(
    builder: (context) {
      captured = S.of(context);
      return const SizedBox.shrink();
    },
  );
  await tester.pumpWidget(
    MaterialApp(
      home: lang == null ? probe : LangScope(lang: lang, child: probe),
    ),
  );
  return captured;
}

void main() {
  group('LangScope', () {
    testWidgets('LangScope.of falls back to "en" with no ancestor', (tester) async {
      late String lang;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              lang = LangScope.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(lang, 'en');
    });

    testWidgets('LangScope.of reads the nearest ancestor value', (tester) async {
      late String lang;
      await tester.pumpWidget(
        MaterialApp(
          home: LangScope(
            lang: 'vi',
            child: Builder(
              builder: (context) {
                lang = LangScope.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(lang, 'vi');
    });

    test('updateShouldNotify is true only when the language actually changes', () {
      const scopeVi = LangScope(lang: 'vi', child: SizedBox.shrink());
      const scopeViAgain = LangScope(lang: 'vi', child: SizedBox.shrink());
      const scopeEn = LangScope(lang: 'en', child: SizedBox.shrink());

      expect(scopeVi.updateShouldNotify(scopeViAgain), isFalse);
      expect(scopeVi.updateShouldNotify(scopeEn), isTrue);
    });
  });

  group('S — plain getters', () {
    testWidgets('returns Vietnamese strings when lang=vi', (tester) async {
      final s = await stringsFor(tester, 'vi');
      expect(s.navHome, 'Trang chủ');
      expect(s.cancel, 'Hủy');
      expect(s.save, 'Lưu');
      expect(s.retry, 'Thử lại');
      expect(s.goodMorning, 'Chào buổi sáng 🌅');
      expect(s.myRecipes, 'Công thức của tôi');
      expect(s.themeLabel, 'Chủ đề');
      expect(s.darkMode, 'Chế độ tối');
      expect(s.logOut, 'Đăng xuất');
      expect(s.passwordsDoNotMatch, 'Mật khẩu không khớp');
    });

    testWidgets('returns English strings when lang=en', (tester) async {
      final s = await stringsFor(tester, 'en');
      expect(s.navHome, 'Home');
      expect(s.cancel, 'Cancel');
      expect(s.save, 'Save');
      expect(s.retry, 'Retry');
      expect(s.goodMorning, 'Good morning 🌅');
      expect(s.myRecipes, 'My Recipes');
      expect(s.themeLabel, 'Theme');
      expect(s.darkMode, 'Dark mode');
      expect(s.logOut, 'Log out');
      expect(s.passwordsDoNotMatch, 'Passwords do not match');
    });

    testWidgets('defaults to English when there is no LangScope ancestor', (tester) async {
      final s = await stringsFor(tester, null);
      expect(s.navHome, 'Home');
    });

    testWidgets('language-agnostic getters never change with lang', (tester) async {
      final vi = await stringsFor(tester, 'vi');
      final en = await stringsFor(tester, 'en');

      expect(vi.emailLabel, 'Email');
      expect(en.emailLabel, 'Email');
      expect(vi.langVietnamese, 'Tiếng Việt');
      expect(en.langVietnamese, 'Tiếng Việt');
      expect(vi.langEnglish, 'English');
      expect(en.langEnglish, 'English');
    });
  });

  group('S — parameterized strings', () {
    testWidgets('recipeCount pluralizes in English, stays invariant in Vietnamese', (tester) async {
      final en = await stringsFor(tester, 'en');
      expect(en.recipeCount(0), '0 recipes');
      expect(en.recipeCount(1), '1 recipe');
      expect(en.recipeCount(2), '2 recipes');

      final vi = await stringsFor(tester, 'vi');
      expect(vi.recipeCount(1), '1 công thức');
      expect(vi.recipeCount(5), '5 công thức');
    });

    testWidgets('resultCount pluralizes in English', (tester) async {
      final en = await stringsFor(tester, 'en');
      expect(en.resultCount(1), '1 result');
      expect(en.resultCount(3), '3 results');

      final vi = await stringsFor(tester, 'vi');
      expect(vi.resultCount(3), '3 kết quả');
    });

    testWidgets('ingredientsToPrepare pluralizes in English', (tester) async {
      final en = await stringsFor(tester, 'en');
      expect(en.ingredientsToPrepare(1), '1 ingredient to prepare');
      expect(en.ingredientsToPrepare(4), '4 ingredients to prepare');

      final vi = await stringsFor(tester, 'vi');
      expect(vi.ingredientsToPrepare(4), '4 nguyên liệu cần chuẩn bị');
    });

    testWidgets('stepOf / stepLabel / ofTotal interpolate their numbers', (tester) async {
      final en = await stringsFor(tester, 'en');
      expect(en.stepOf(2, 5), 'Step 2 of 5');
      expect(en.stepLabel(3), 'Step 3');
      expect(en.ofTotal(5), 'of 5');

      final vi = await stringsFor(tester, 'vi');
      expect(vi.stepOf(2, 5), 'Bước 2 / 5');
      expect(vi.stepLabel(3), 'Bước 3');
      expect(vi.ofTotal(5), '/ 5');
    });

    testWidgets('doneWithCount / phaseLabel / cookingMinutesDisplay interpolate correctly', (tester) async {
      final en = await stringsFor(tester, 'en');
      expect(en.doneWithCount(3), 'Done (3)');
      expect(en.phaseLabel('gather'), 'Phase: gather');
      expect(en.cookingMinutesDisplay(20), '20 min');

      final vi = await stringsFor(tester, 'vi');
      expect(vi.doneWithCount(3), 'Xong (3)');
      expect(vi.phaseLabel('gather'), 'Giai đoạn: gather');
      expect(vi.cookingMinutesDisplay(20), '20 phút');
    });

    testWidgets('removeConfirm / unableToOpenRecipe embed the given name', (tester) async {
      final en = await stringsFor(tester, 'en');
      expect(
        en.removeConfirm('Pho Bo'),
        'Do you want to remove "Pho Bo" from your saved recipes?',
      );
      expect(en.unableToOpenRecipe('Pho Bo'), 'Could not open details for "Pho Bo".');

      final vi = await stringsFor(tester, 'vi');
      expect(vi.removeConfirm('Phở Bò'), 'Bạn có muốn xóa "Phở Bò" khỏi danh sách đã lưu?');
    });

    testWidgets('ingredientsDetectedList / dishDetectedName embed the given text', (tester) async {
      final en = await stringsFor(tester, 'en');
      expect(en.ingredientsDetectedList('egg, salt'), 'Ingredients detected: egg, salt');
      expect(en.dishDetectedName('Pho'), 'Dishes detected: Pho');

      final vi = await stringsFor(tester, 'vi');
      expect(vi.ingredientsDetectedList('trứng, muối'), 'Nguyên liệu phát hiện: trứng, muối');
      expect(vi.dishDetectedName('Phở'), 'Món ăn phát hiện: Phở');
    });
  });

  group('S — label/category display maps', () {
    testWidgets('categoryDisplay only translates known values, only in Vietnamese', (tester) async {
      final vi = await stringsFor(tester, 'vi');
      expect(vi.categoryDisplay('Breakfast'), 'Bữa sáng');
      expect(vi.categoryDisplay('Vegan'), 'Thuần chay');
      expect(vi.categoryDisplay('Not In Map'), 'Not In Map');

      final en = await stringsFor(tester, 'en');
      expect(en.categoryDisplay('Breakfast'), 'Breakfast');
    });

    testWidgets('goalDisplay only translates known values, only in Vietnamese', (tester) async {
      final vi = await stringsFor(tester, 'vi');
      expect(vi.goalDisplay('Weight Loss'), 'Giảm cân');
      expect(vi.goalDisplay('Unknown Goal'), 'Unknown Goal');

      final en = await stringsFor(tester, 'en');
      expect(en.goalDisplay('Weight Loss'), 'Weight Loss');
    });

    testWidgets('dietaryTagDisplay only translates known tags, only in Vietnamese', (tester) async {
      final vi = await stringsFor(tester, 'vi');
      expect(vi.dietaryTagDisplay('Vegan'), 'Thuần chay');
      expect(vi.dietaryTagDisplay('Gluten Free'), 'Không gluten');
      expect(vi.dietaryTagDisplay('Keto'), 'Keto'); // maps to itself in the table
      expect(vi.dietaryTagDisplay('Not A Real Tag'), 'Not A Real Tag');

      final en = await stringsFor(tester, 'en');
      expect(en.dietaryTagDisplay('Vegan'), 'Vegan');
    });
  });
}
