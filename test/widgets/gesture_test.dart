import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodhub_mobile/widgets/recipe_detail_view.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget _refreshableList({required VoidCallback onRefresh}) {
  return RefreshIndicator(
    onRefresh: () async => onRefresh(),
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: List.generate(
        3,
        (i) => SizedBox(height: 200, child: Text('Item $i')),
      ),
    ),
  );
}

void main() {
  // ── Pull-to-refresh gesture ────────────────────────────────────────────────

  group('Pull-to-refresh gesture', () {
    testWidgets('drag down triggers onRefresh callback', (tester) async {
      bool refreshed = false;

      await tester.pumpWidget(
        _app(_refreshableList(onRefresh: () => refreshed = true)),
      );

      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(refreshed, isTrue);
    });

    testWidgets('AlwaysScrollableScrollPhysics allows overscroll on short list',
        (tester) async {
      bool refreshed = false;

      await tester.pumpWidget(
        _app(
          RefreshIndicator(
            onRefresh: () async => refreshed = true,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox(height: 50, child: Text('One item'))],
            ),
          ),
        ),
      );

      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(refreshed, isTrue);
    });
  });

  // ── Swipe-left-to-go-back (RecipeDetailView) ──────────────────────────────

  group('RecipeDetailView swipe-left gesture', () {
    const recipe = RecipeDetailData(
      id: 1,
      name: 'Test Recipe',
      cookingMinutes: 30,
      ingredients: 'Eggs\nSalt',
      steps: 'Step 1\nStep 2',
      labels: [],
    );

    testWidgets('swipe left >= 60px calls onBack', (tester) async {
      bool wentBack = false;

      await tester.pumpWidget(
        _app(
          RecipeDetailView(
            recipe: recipe,
            cardColor: Colors.green,
            onBack: () => wentBack = true,
          ),
        ),
      );
      await tester.pump();

      final center = tester.getCenter(find.byType(RecipeDetailView));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(-80, 0));
      await gesture.up();
      await tester.pump();

      expect(wentBack, isTrue);
    });

    testWidgets('vertical scroll does NOT trigger onBack', (tester) async {
      bool wentBack = false;

      await tester.pumpWidget(
        _app(
          RecipeDetailView(
            recipe: recipe,
            cardColor: Colors.green,
            onBack: () => wentBack = true,
          ),
        ),
      );
      await tester.pump();

      final center = tester.getCenter(find.byType(RecipeDetailView));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(-10, 150));
      await gesture.up();
      await tester.pump();

      expect(wentBack, isFalse);
    });

    testWidgets('short swipe < 60px does NOT trigger onBack', (tester) async {
      bool wentBack = false;

      await tester.pumpWidget(
        _app(
          RecipeDetailView(
            recipe: recipe,
            cardColor: Colors.green,
            onBack: () => wentBack = true,
          ),
        ),
      );
      await tester.pump();

      final center = tester.getCenter(find.byType(RecipeDetailView));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(-40, 0));
      await gesture.up();
      await tester.pump();

      expect(wentBack, isFalse);
    });
  });
}
