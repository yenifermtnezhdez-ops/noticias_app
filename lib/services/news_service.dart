
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/news_model.dart';

class NewsService {
  static const String baseUrl =
      'https://news.freepi.io/wp-json/wp/v2/posts';
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
  Future<List<NewsModel>> getNews() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
      );

      if (response.statusCode == 200) {
        final news = _parseNews(response.body);

        print('Conexión exitosa con WordPress');
        print('Noticias recibidas: ${news.length}');

        return news;
      } else {
        throw Exception(
          'Error al obtener noticias: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error de conexión: $e');
      rethrow;
    }
  }
  Future<List<NewsModel>> searchNews(String query) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'search': query.trim(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final news = _parseNews(response.body);

        print('Búsqueda realizada: $query');
        print('Resultados encontrados: ${news.length}');

        return news;
      } else {
        throw Exception(
          'Error al buscar noticias: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error durante la búsqueda: $e');
      rethrow;
    }
  }
}
