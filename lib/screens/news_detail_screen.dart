
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../models/news_model.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsModel news;

  const NewsDetailScreen({
    super.key,
    required this.news,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de la noticia'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              news.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 17,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  news.date,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Divider(),

            const SizedBox(height: 16),

            const Text(
              'Contenido de la noticia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Html(
              data: news.content,
              style: {
                "body": Style(
                  fontSize: FontSize(16),
                  lineHeight: LineHeight.number(1.6),
                  color: Colors.black87,
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
                "p": Style(
                  margin: Margins.only(bottom: 14),
                ),
                "h2": Style(
                  fontSize: FontSize(22),
                  fontWeight: FontWeight.bold,
                ),
                "h3": Style(
                  fontSize: FontSize(19),
                  fontWeight: FontWeight.bold,
                ),
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
