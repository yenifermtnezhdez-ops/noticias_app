
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
    final colors = Theme.of(context).colorScheme;

    final bookmarkProvider = context.watch<BookmarkProvider>();
    final isBookmarked = bookmarkProvider.isBookmarked(news.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de la noticia'),
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

                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
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

                      ScaffoldMessenger.of(context)
                        ..showSnackBar(
                          SnackBar(
                            content: const Text(
                              'No fue posible actualizar el favorito.',
                            ),
                            backgroundColor: colors.error,
                          ),
                        );
                    }
                  },
            tooltip: isBookmarked
                ? 'Quitar de favoritos'
                : 'Guardar en favoritos',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                isBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                key: ValueKey(isBookmarked),
                color: colors.onPrimary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                news.title,
                key: ValueKey(news.id),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: colors.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 17,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    news.date,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Divider(color: colors.outlineVariant),

            const SizedBox(height: 16),

            Text(
              'Contenido de la noticia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 12),

            Html(
              data: news.content,
              style: {
                "body": Style(
                  fontSize: FontSize(16),
                  lineHeight: LineHeight.number(1.6),
                  color: colors.onSurface,
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
                "p": Style(
                  color: colors.onSurface,
                  margin: Margins.only(bottom: 14),
                ),
                "h2": Style(
                  fontSize: FontSize(22),
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
                "h3": Style(
                  fontSize: FontSize(19),
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
                "a": Style(
                  color: colors.primary,
                ),
                "strong": Style(
                  color: colors.onSurface,
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
