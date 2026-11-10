
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/news_model.dart';
import '../providers/bookmark_provider.dart';
import '../screens/news_detail_screen.dart';

class NewsCard extends StatelessWidget {
  final NewsModel news;

  const NewsCard({
    super.key,
    required this.news,
  });

  String _cleanContent(String content) {
    return content
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#8217;', '’')
        .replaceAll('&#8216;', '‘')
        .replaceAll('&#8220;', '“')
        .replaceAll('&#8221;', '”')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _formatDate(String rawDate) {
    final parsedDate = DateTime.tryParse(rawDate);

    if (parsedDate == null) {
      return rawDate;
    }

    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return '${parsedDate.day} '
        '${months[parsedDate.month - 1]} '
        '${parsedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final bookmarkProvider = context.watch<BookmarkProvider>();
    final isBookmarked = bookmarkProvider.isBookmarked(news.id);

    final cleanContent = _cleanContent(news.content);

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: colors.outline..withValues(alpha: 0.55),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(
                news: news,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.newspaper_rounded,
                      color: colors.primary,
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NOTICIAS',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Actualidad',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isBookmarked
                          ? colors.primaryContainer
                          : colors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.55),
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: bookmarkProvider.isLoading
                          ? null
                          : () async {
                              try {
                                await context
                                    .read<BookmarkProvider>()
                                    .toggleBookmark(news.id);
                              } catch (_) {
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context)
                                  .showSnackBar(
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
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          key: ValueKey(isBookmarked),
                          color: isBookmarked
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 19),

            
              Text(
                news.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 12),

            
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _formatDate(news.date),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

           
              if (cleanContent.isNotEmpty) ...[
                const SizedBox(height: 13),
                Text(
                  cleanContent,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 17),

              Divider(
                height: 1,
                color: colors.outline.withValues(alpha: 0.45),
              ),

              const SizedBox(height: 13),

            
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Leer noticia',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: colors.primary,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
