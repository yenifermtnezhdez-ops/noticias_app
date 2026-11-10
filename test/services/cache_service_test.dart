
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noticias_app/models/news_model.dart';
import 'package:noticias_app/models/category_model.dart';
import 'package:noticias_app/services/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CacheService cacheService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cacheService = CacheService();
  });

  NewsModel createNews(int id, {String? title}) {
    return NewsModel(
      id: id,
      title: title ?? 'Noticia $id',
      content: 'Contenido de la noticia $id',
      date: '2026-11-10T10:00:00',
      link: 'https://example.com/noticia-$id',
    );
  }

  group('CacheService - Noticias', () {
    test('Devuelve null cuando no hay noticias guardadas', () async {
      expect(await cacheService.getNews('all_news'), isNull);
    });

    test('Guarda y recupera noticias correctamente', () async {
      await cacheService.saveNews(
        cacheKey: 'all_news',
        news: [createNews(1), createNews(2)],
      );

      final result = await cacheService.getNews('all_news');

      expect(result, hasLength(2));
      expect(result![0].id, 1);
      expect(result[0].title, 'Noticia 1');
      expect(result[1].id, 2);
    });

    test('Agrega noticias sin duplicar identificadores', () async {
      await cacheService.saveNews(
        cacheKey: 'all_news',
        news: [createNews(1), createNews(2)],
      );

      await cacheService.saveNews(
        cacheKey: 'all_news',
        news: [
          createNews(2, title: 'Noticia 2 actualizada'),
          createNews(3),
        ],
        append: true,
      );

      final result = await cacheService.getNews('all_news');

      expect(result, hasLength(3));
      expect(result!.map((item) => item.id).toSet(), {1, 2, 3});

      final updated = result.firstWhere((item) => item.id == 2);
      expect(updated.title, 'Noticia 2 actualizada');
    });

    test('Limita la caché a 30 noticias', () async {
      final news = List.generate(
        35,
        (index) => createNews(index + 1),
      );

      await cacheService.saveNews(
        cacheKey: 'all_news',
        news: news,
      );

      final result = await cacheService.getNews('all_news');

      expect(result, hasLength(30));
      expect(result!.first.id, 1);
      expect(result.last.id, 30);
    });

    test('Elimina la caché de noticias', () async {
      await cacheService.saveNews(
        cacheKey: 'all_news',
        news: [createNews(1)],
      );

      await cacheService.removeNewsCache('all_news');

      expect(await cacheService.getNews('all_news'), isNull);
    });
  });

  group('CacheService - Categorías', () {
    test('Devuelve null cuando no hay categorías guardadas', () async {
      expect(await cacheService.getCategories(), isNull);
    });

    test('Guarda y recupera categorías correctamente', () async {
      const categories = [
        CategoryModel(id: 5, name: 'Comercio'),
        CategoryModel(id: 28, name: 'Deportes'),
        CategoryModel(id: 9, name: 'Espectáculos'),
      ];

      await cacheService.saveCategories(categories);

      final result = await cacheService.getCategories();

      expect(result, hasLength(3));
      expect(result![0].id, 5);
      expect(result[0].name, 'Comercio');
      expect(result[1].name, 'Deportes');
      expect(result[2].id, 9);
    });

    test('Elimina la caché de categorías', () async {
      const categories = [
        CategoryModel(id: 5, name: 'Comercio'),
      ];

      await cacheService.saveCategories(categories);
      await cacheService.removeCategoriesCache();

      expect(await cacheService.getCategories(), isNull);
    });
  });
}
