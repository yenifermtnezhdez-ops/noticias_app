
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/news_model.dart';
import '../models/category_model.dart';

class CacheService {
  static const String _newsPrefix = 'offline_news_';
  static const String _categoriesKey = 'offline_categories_v1';

  static const int _maxCachedNews = 30;


  Future<List<NewsModel>?> getNews(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      final jsonString = prefs.getString(
        '$_newsPrefix$cacheKey',
      );

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final List<dynamic> decoded = jsonDecode(jsonString);

      final news = decoded.map((item) {
        return NewsModel.fromCacheJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();

      return news;
    } catch (e) {
      debugPrint('Error al recuperar noticias de caché: $e');
      return null;
    }
  }


  Future<void> saveNews({
    required String cacheKey,
    required List<NewsModel> news,
    bool append = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      final Map<int, NewsModel> uniqueNews = {};

      if (append) {
        final previousNews = await getNews(cacheKey) ?? [];

        for (final item in previousNews) {
          uniqueNews[item.id] = item;
        }
      }

      for (final item in news) {
        uniqueNews[item.id] = item;
      }

      final limitedNews = uniqueNews.values
          .take(_maxCachedNews)
          .toList();

      final jsonString = jsonEncode(
        limitedNews.map((item) {
          return item.toCacheJson();
        }).toList(),
      );

      final success = await prefs.setString(
        '$_newsPrefix$cacheKey',
        jsonString,
      );

      if (!success) {
        throw Exception(
          'No fue posible guardar las noticias en caché.',
        );
      }

      debugPrint(
        'CACHÉ: ${limitedNews.length} noticias guardadas '
        'para $cacheKey',
      );
    } catch (e) {
      debugPrint('Error al guardar noticias en caché: $e');
      rethrow;
    }
  }

  Future<void> saveCategories(
    List<CategoryModel> categories,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final jsonString = jsonEncode(
        categories.map((category) {
          return {
            'id': category.id,
            'name': category.name,
          };
        }).toList(),
      );

      final success = await prefs.setString(
        _categoriesKey,
        jsonString,
      );

      if (!success) {
        throw Exception(
          'No fue posible guardar las categorías.',
        );
      }

      debugPrint(
        'CACHÉ: ${categories.length} categorías guardadas.',
      );
    } catch (e) {
      debugPrint('Error al guardar categorías: $e');
      rethrow;
    }
  }


  Future<List<CategoryModel>?> getCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      final jsonString = prefs.getString(_categoriesKey);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final List<dynamic> decoded = jsonDecode(jsonString);

      return decoded.map((item) {
        final data = Map<String, dynamic>.from(item as Map);

        return CategoryModel(
          id: (data['id'] as num).toInt(),
          name: data['name'] as String,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error al recuperar categorías: $e');
      return null;
    }
  }


  Future<void> removeNewsCache(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('$_newsPrefix$cacheKey');
  }

 
  Future<void> removeCategoriesCache() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_categoriesKey);
  }
}
