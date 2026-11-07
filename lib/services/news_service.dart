import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/news_model.dart';

class NewsService {
  static const String baseUrl =
      'https://news.freepi.io/wp-json/wp/v2/posts';

  Future<List<NewsModel>> getNews() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<NewsModel> news = data
            .map(
              (item) => NewsModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

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
}