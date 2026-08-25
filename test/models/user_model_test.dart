import 'package:flutter_test/flutter_test.dart';
import 'package:foodhub_mobile/models/user.dart';

void main() {
  group('UserModel.fromJson', () {
    test('parses a full payload', () {
      final user = UserModel.fromJson({
        'id': 1,
        'email': 'a@b.com',
        'username': 'alice',
        'full_name': 'Alice Nguyen',
        'role': 'admin',
        'is_active': false,
        'age': 30,
        'weight': 55.5,
        'language': 'vi',
        'theme': 'dark',
        'calorie_target': 2000,
        'protein_target': 120,
        'carb_target': 250,
        'fat_target': 70,
        'dietary_restrictions': ['vegan', 'gluten-free'],
        'primary_goal': 'weight_loss',
      });

      expect(user.id, 1);
      expect(user.email, 'a@b.com');
      expect(user.role, 'admin');
      expect(user.isActive, isFalse);
      expect(user.age, 30);
      expect(user.weight, 55.5);
      expect(user.language, 'vi');
      expect(user.theme, 'dark');
      expect(user.calorieTarget, 2000);
      expect(user.proteinTarget, 120);
      expect(user.carbTarget, 250);
      expect(user.fatTarget, 70);
      expect(user.dietaryRestrictions, ['vegan', 'gluten-free']);
    });

    test('applies defaults when optional fields are missing', () {
      final user = UserModel.fromJson({
        'id': 2,
        'email': 'x@y.com',
        'username': 'x',
      });

      expect(user.role, 'user');
      expect(user.isActive, isTrue);
      expect(user.theme, 'light');
      expect(user.dietaryRestrictions, isEmpty);
      expect(user.calorieTarget, isNull);
      expect(user.proteinTarget, isNull);
      expect(user.carbTarget, isNull);
      expect(user.fatTarget, isNull);
    });
  });

  group('UserModel.toProfileUpdateJson', () {
    test('only includes fields that were explicitly passed', () {
      const user = UserModel(id: 1, email: 'a@b.com', username: 'a');

      final json = user.toProfileUpdateJson(
        fullName: 'New Name',
        age: 25,
        carbTarget: 220,
        fatTarget: 65,
      );

      expect(json, {
        'full_name': 'New Name',
        'age': 25,
        'carb_target': 220,
        'fat_target': 65,
      });
    });

    test('returns an empty map when nothing is passed', () {
      const user = UserModel(id: 1, email: 'a@b.com', username: 'a');
      expect(user.toProfileUpdateJson(), isEmpty);
    });
  });

  group('UserModel.copyWith', () {
    test('overrides only the given fields and keeps identity fields', () {
      const user = UserModel(
        id: 1,
        email: 'a@b.com',
        username: 'a',
        fullName: 'Old Name',
        theme: 'light',
      );

      final updated = user.copyWith(fullName: 'New Name', theme: 'dark');

      expect(updated.id, user.id);
      expect(updated.email, user.email);
      expect(updated.username, user.username);
      expect(updated.fullName, 'New Name');
      expect(updated.theme, 'dark');
    });

    test('falls back to existing values when a field is omitted', () {
      const user = UserModel(
        id: 1,
        email: 'a@b.com',
        username: 'a',
        calorieTarget: 1800,
        carbTarget: 200,
      );

      final updated = user.copyWith(proteinTarget: 100, fatTarget: 60);

      expect(updated.calorieTarget, 1800);
      expect(updated.proteinTarget, 100);
      expect(updated.carbTarget, 200);
      expect(updated.fatTarget, 60);
    });
  });

  group('AuthToken.fromJson', () {
    test('parses token and nested user', () {
      final token = AuthToken.fromJson({
        'access_token': 'abc123',
        'token_type': 'bearer',
        'user': {'id': 1, 'email': 'a@b.com', 'username': 'a'},
      });

      expect(token.accessToken, 'abc123');
      expect(token.tokenType, 'bearer');
      expect(token.user.id, 1);
    });
  });
}
