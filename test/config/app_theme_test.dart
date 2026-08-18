import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodhub_mobile/config/app_theme.dart';

void main() {
  group('AppTheme.light', () {
    final theme = AppTheme.light;

    test('uses Material 3 with a light color scheme', () {
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('sets the expected background and input field colors', () {
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF3F4F6));
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.inputDecorationTheme.fillColor, Colors.white);
    });

    test('input borders are rounded and use the brand color when focused', () {
      final border = theme.inputDecorationTheme.border as OutlineInputBorder;
      final focusedBorder =
          theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;

      expect(border.borderRadius, BorderRadius.circular(10));
      expect(border.borderSide.color, const Color(0xFFD1D5DB));
      expect(focusedBorder.borderSide.color, const Color(0xFF059669));
    });
  });

  group('AppTheme.dark', () {
    final theme = AppTheme.dark;

    test('uses Material 3 with a dark color scheme', () {
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('sets the expected background, card and divider colors', () {
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0A0A0A));
      expect(theme.cardColor, const Color(0xFF141414));
      expect(theme.dividerColor, const Color(0xFF2A2A2A));
      expect(theme.inputDecorationTheme.fillColor, const Color(0xFF1E1E1E));
    });

    test('input borders are borderless except when focused', () {
      final border = theme.inputDecorationTheme.border as OutlineInputBorder;
      final enabledBorder =
          theme.inputDecorationTheme.enabledBorder as OutlineInputBorder;
      final focusedBorder =
          theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;

      expect(border.borderSide, BorderSide.none);
      expect(enabledBorder.borderSide, BorderSide.none);
      expect(focusedBorder.borderSide.color, const Color(0xFF059669));
    });
  });

  group('AppTheme.light vs AppTheme.dark', () {
    test('the two themes are meaningfully different, not accidental copies', () {
      expect(AppTheme.light.brightness, isNot(AppTheme.dark.brightness));
      expect(
        AppTheme.light.scaffoldBackgroundColor,
        isNot(AppTheme.dark.scaffoldBackgroundColor),
      );
    });

    test('both share the same brand seed color for their focused input border', () {
      final lightFocused =
          AppTheme.light.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      final darkFocused =
          AppTheme.dark.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      expect(lightFocused.borderSide.color, darkFocused.borderSide.color);
    });
  });
}
