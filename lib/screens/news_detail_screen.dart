
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import '../models/news_model.dart';
import '../providers/bookmark_provider.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsModel news;

  const NewsDetailScreen({
    super.key,
    required this.news,
  });

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final isBookmarked = bookmarkProvider.isBookmarked(news.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de la noticia'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: bookmarkProvider.isLoading
                ? null
                : () async {
                    try {
                      await context
                          .read<BookmarkProvider>()
                          .toggleBookmark(news.id);

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isBookmarked
                                ? 'Noticia eliminada de favoritos.'
                                : 'Noticia guardada en favoritos.',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } catch (_) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No fue posible actualizar el favorito.',
                          ),
                        ),
                      );
                    }
                  },
            tooltip: isBookmarked
                ? 'Quitar de favoritos'
                : 'Guardar en favoritos',
            icon: Icon(
              isBookmarked
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: Colors.white,
            ),
          ),
        ],
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
