
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noticias_app/models/news_model.dart';
import 'package:noticias_app/models/category_model.dart';
import 'package:noticias_app/providers/news_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NewsProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    provider = NewsProvider();
  });

  tearDown(() {
    provider.dispose();
  });

  NewsModel createNews(int id) {
    return NewsModel(
      id: id,
      title: 'Noticia $id',
      content: 'Contenido de prueba',
      date: '2026-11-10T10:00:00',
      link: 'https://example.com/noticia-$id',
    );
  }

  group('NewsProvider - Estado de conexión', () {
    test('Inicia con conexión disponible', () {
      expect(provider.isOnline, isTrue);
      expect(provider.isOffline, isFalse);
      expect(provider.isInitialized, isFalse);
      expect(provider.connectionRevision, 0);
    });

    test('Cambia a modo offline correctamente', () {
      provider.reportOffline();

      expect(provider.isOnline, isFalse);
      expect(provider.isOffline, isTrue);
      expect(provider.connectionRevision, 1);
    });

    test('Notifica cuando pierde conexión', () {
      var notifications = 0;

      provider.addListener(() => notifications++);
      provider.reportOffline();

      expect(notifications, 1);
    });

    test('No notifica varias veces si ya está offline', () {
      var notifications = 0;

      provider.addListener(() => notifications++);
      provider.reportOffline();
      provider.reportOffline();

      expect(provider.isOffline, isTrue);
      expect(provider.connectionRevision, 1);
      expect(notifications, 1);
    });

    test('Recupera la conexión correctamente', () {
      provider.reportOffline();
      provider.reportOnline();

      expect(provider.isOnline, isTrue);
      expect(provider.isOffline, isFalse);
      expect(provider.connectionRevision, 2);
    });

    test('Notifica cuando se recupera la conexión', () {
      var notifications = 0;

      provider.addListener(() => notifications++);
      provider.reportOffline();
      provider.reportOnline();

      expect(notifications, 2);
    });
  });

  group('NewsProvider - Claves de caché', () {
    test('Usa all_news cuando no hay filtros', () {
      expect(provider.buildCacheKey(), 'all_news');
    });

    test('Genera una clave por categoría', () {
      expect(
        provider.buildCacheKey(categoryId: 28),
        'category_28',
      );
    });

    test('Normaliza las búsquedas', () {
      expect(
        provider.buildCacheKey(search: '  FUTBOL  '),
        'search_futbol',
      );
    });

    test('Codifica espacios en las búsquedas', () {
      expect(
        provider.buildCacheKey(search: 'noticias locales'),
        'search_noticias%20locales',
      );
    });

    test('La búsqueda tiene prioridad sobre la categoría', () {
      expect(
        provider.buildCacheKey(
          search: 'deportes',
          categoryId: 28,
        ),
        'search_deportes',
      );
    });
  });

  group('NewsProvider - Caché de noticias', () {
    test('Guarda y recupera noticias', () async {
      await provider.saveNews(
        news: [createNews(1), createNews(2)],
      );

      final result = await provider.getCachedNews();

      expect(result, hasLength(2));
      expect(result!.first.title, 'Noticia 1');
    });

    test('Mantiene separadas las noticias por búsqueda', () async {
      await provider.saveNews(
        news: [createNews(1)],
        search: 'deportes',
      );

      final searchResult = await provider.getCachedNews(
        search: ' DEPORTES ',
      );

      final generalResult = await provider.getCachedNews();

      expect(searchResult, hasLength(1));
      expect(generalResult, isNull);
    });

    test('Mantiene separadas las noticias por categoría', () async {
      await provider.saveNews(
        news: [createNews(1)],
        categoryId: 28,
      );

      final categoryResult = await provider.getCachedNews(
        categoryId: 28,
      );

      final generalResult = await provider.getCachedNews();

      expect(categoryResult, hasLength(1));
      expect(generalResult, isNull);
    });
  });

  group('NewsProvider - Caché de categorías', () {
    test('Guarda y recupera categorías', () async {
      const categories = [
        CategoryModel(id: 5, name: 'Comercio'),
        CategoryModel(id: 28, name: 'Deportes'),
      ];

      await provider.saveCategories(categories);

      final result = await provider.getCachedCategories();

      expect(result, hasLength(2));
      expect(result![0].name, 'Comercio');
      expect(result[1].id, 28);
    });
  });
}
