import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/services/api_client.dart';
import 'package:foodhub_mobile/services/favorite_service.dart';
import 'package:foodhub_mobile/services/session_service.dart';

class MockApiClient extends Mock implements ApiClient {}

Map<String, dynamic> _favoriteJson({int id = 1}) => {
      'id': id,
      'recipe_id': 10,
      'recipe': {'id': 10, 'title': 'Pho'},
    };

void main() {
  late MockApiClient api;
  late FavoriteService favoriteService;

  setUp(() {
    api = MockApiClient();
    favoriteService = FavoriteService(apiClient: api);
    SessionService.instance.clear();
  });

  tearDown(() {
    SessionService.instance.clear();
  });

  group('listFavorites', () {
    test('uses the explicit lang over the session language', () async {
      SessionService.instance.setUser(
        const UserModel(id: 1, email: 'a@b.com', username: 'a', language: 'vi'),
      );
      when(() => api.get('/favorites', query: any(named: 'query')))
          .thenAnswer((_) async => [_favoriteJson()]);

      await favoriteService.listFavorites(lang: 'en');

      final query = verify(
        () => api.get('/favorites', query: captureAny(named: 'query')),
      ).captured.single as Map<String, String>;
      expect(query['lang'], 'en');
    });

    test('falls back to the session language when none is given', () async {
      SessionService.instance.setUser(
        const UserModel(id: 1, email: 'a@b.com', username: 'a', language: 'vi'),
      );
      when(() => api.get('/favorites', query: any(named: 'query')))
          .thenAnswer((_) async => [_favoriteJson()]);

      await favoriteService.listFavorites();

      final query = verify(
        () => api.get('/favorites', query: captureAny(named: 'query')),
      ).captured.single as Map<String, String>;
      expect(query['lang'], 'vi');
    });

    test('maps the response into FavoriteModel instances', () async {
      when(() => api.get('/favorites', query: any(named: 'query')))
          .thenAnswer((_) async => [_favoriteJson(id: 5)]);

      final favorites = await favoriteService.listFavorites();
      expect(favorites.single.id, 5);
      expect(favorites.single.recipe.title, 'Pho');
    });
  });

  group('addFavorite', () {
    test('sends recipe_id and note, then bumps the changes notifier', () async {
      when(() => api.post('/favorites', body: any(named: 'body')))
          .thenAnswer((_) async => _favoriteJson());

      final before = FavoriteService.changes.value;
      await favoriteService.addFavorite(recipeId: 10, note: 'extra spicy');

      final body = verify(
        () => api.post('/favorites', body: captureAny(named: 'body')),
      ).captured.single as Map<String, dynamic>;
      expect(body, {'recipe_id': 10, 'note': 'extra spicy'});
      expect(FavoriteService.changes.value, before + 1);
    });

    test('omits note when it is empty', () async {
      when(() => api.post('/favorites', body: any(named: 'body')))
          .thenAnswer((_) async => _favoriteJson());

      await favoriteService.addFavorite(recipeId: 10);

      final body = verify(
        () => api.post('/favorites', body: captureAny(named: 'body')),
      ).captured.single as Map<String, dynamic>;
      expect(body.containsKey('note'), isFalse);
    });
  });

  group('deleteFavorite', () {
    test('deletes by id and bumps the changes notifier', () async {
      when(() => api.delete('/favorites/3')).thenAnswer((_) async {});

      final before = FavoriteService.changes.value;
      await favoriteService.deleteFavorite(3);

      verify(() => api.delete('/favorites/3')).called(1);
      expect(FavoriteService.changes.value, before + 1);
    });
  });
}
