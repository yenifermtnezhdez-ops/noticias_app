
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/news_model.dart';
import '../models/category_model.dart';

class NewsService {
  static const String baseUrl =
      'https://news.freepi.io/wp-json/wp/v2/posts';

  static const String categoriesUrl =
      'https://news.freepi.io/wp-json/wp/v2/categories';

  static const Duration requestTimeout =
      Duration(seconds: 12);

  int totalPages = 1;

  List<NewsModel> _parseNews(String responseBody) {
    final List<dynamic> data = jsonDecode(responseBody);

    return data
        .map(
          (item) => NewsModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  
  Future<List<NewsModel>> _fetchNews({
    int page = 1,
    int perPage = 10,
    String? search,
    int? categoryId,
  }) async {
    final Map<String, String> parameters = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (search != null && search.trim().isNotEmpty) {
      parameters['search'] = search.trim();
    }

    if (categoryId != null) {
      parameters['categories'] = categoryId.toString();
    }

    final uri = Uri.parse(baseUrl).replace(
      queryParameters: parameters,
    );

    final response = await http
        .get(uri)
        .timeout(requestTimeout);

    if (response.statusCode == 200) {
      totalPages = int.tryParse(
            response.headers['x-wp-totalpages'] ?? '',
          ) ??
          1;

      final news = _parseNews(response.body);

      debugPrint('Página consultada: $page');
      debugPrint('Noticias recibidas: ${news.length}');
      debugPrint('Total de páginas: $totalPages');

      return news;
    }

    throw Exception(
      'Error al obtener noticias: ${response.statusCode}',
    );
  }

  Future<List<NewsModel>> getNews({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      return await _fetchNews(
        page: page,
        perPage: perPage,
      );
    } catch (e) {
      debugPrint('Error de conexión: $e');
      rethrow;
    }
  }


  Future<List<NewsModel>> searchNews(
    String query, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final news = await _fetchNews(
        page: page,
        perPage: perPage,
        search: query,
      );

      debugPrint('Búsqueda realizada: $query');

      return news;
    } catch (e) {
      debugPrint('Error durante la búsqueda: $e');
      rethrow;
    }
  }


  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse(categoriesUrl))
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final categories = data
            .map(
              (item) => CategoryModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

        debugPrint(
          'Categorías recibidas: ${categories.length}',
        );

        return categories;
      }

      throw Exception(
        'Error al obtener categorías: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error al consultar categorías: $e');
      rethrow;
    }
  }

  Future<List<NewsModel>> getNewsByCategory(
    int categoryId, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      return await _fetchNews(
        page: page,
        perPage: perPage,
        categoryId: categoryId,
      );
    } catch (e) {
      debugPrint('Error al filtrar por categoría: $e');
      rethrow;
    }
  }

 
  Future<List<NewsModel>> getNewsByIds(List<int> ids) async {
    if (ids.isEmpty) {
      return [];
    }

    final uniqueIds = ids.toSet().toList();

    final List<NewsModel> allNews = [];

    for (var start = 0;
        start < uniqueIds.length;
        start += 100) {
      final batch = uniqueIds.skip(start).take(100).toList();

      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'include': batch.join(','),
          'per_page': batch.length.toString(),
        },
      );

      final response = await http
          .get(uri)
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        allNews.addAll(_parseNews(response.body));
      } else {
        throw Exception(
          'Error al recuperar noticias guardadas: '
          '${response.statusCode}',
        );
      }
    }

    final Map<int, NewsModel> newsById = {
      for (final news in allNews) news.id: news,
    };

    return uniqueIds
        .map((id) => newsById[id])
        .whereType<NewsModel>()
        .toList();
  }
}
