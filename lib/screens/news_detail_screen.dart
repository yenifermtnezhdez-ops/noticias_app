
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import '../models/news_model.dart';
import '../providers/auth_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/comment_provider.dart';
import '../components/comment_card.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsModel news;

  const NewsDetailScreen({
    super.key,
    required this.news,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CommentProvider>(
      create: (_) => CommentProvider(newsId: news.id),
      child: _NewsDetailContent(news: news),
    );
  }
}

class _NewsDetailContent extends StatelessWidget {
  final NewsModel news;

  const _NewsDetailContent({
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
            Divider(color: colors.outlineVariant),
            const SizedBox(height: 20),
            const _CommentsSection(),
          ],
        ),
      ),
    );
  }
}

class _CommentsSection extends StatefulWidget {
  const _CommentsSection();

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final TextEditingController _commentController =
      TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final user = context.read<AuthProvider>().user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes iniciar sesión para publicar comentarios.',
          ),
        ),
      );
      return;
    }

    final content = _commentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un comentario antes de publicarlo.'),
        ),
      );
      return;
    }

    final success = await context.read<CommentProvider>().addComment(
          content: content,
          userName: user.displayName ??
              user.email ??
              'Usuario',
        );

    if (!mounted) return;

    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comentario publicado correctamente.'),
        ),
      );
    } else {
      final message = context.read<CommentProvider>().errorMessage;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message ?? 'No fue posible publicar el comentario.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;
    final commentProvider = context.watch<CommentProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.forum_outlined,
              color: colors.primary,
              size: 25,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Comentarios',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${commentProvider.commentCount}',
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        if (currentUser != null) ...[
          Text(
            'Escribe tu comentario',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _commentController,
            enabled: !commentProvider.isWriting,
            minLines: 2,
            maxLines: 4,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Comparte tu opinión sobre esta noticia...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: commentProvider.isWriting
                  ? null
                  : _sendComment,
              icon: commentProvider.isWriting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                commentProvider.isWriting
                    ? 'Publicando...'
                    : 'Publicar comentario',
              ),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Inicia sesión para poder publicar comentarios.',
            ),
          ),
        ],

        const SizedBox(height: 24),

        if (commentProvider.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              commentProvider.errorMessage!,
              style: TextStyle(
                color: colors.error,
                fontSize: 13,
              ),
            ),
          ),

        if (commentProvider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (commentProvider.comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 42,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Todavía no hay comentarios.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¡Sé el primero en compartir tu opinión!',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: commentProvider.comments.map((comment) {
              return CommentCard(
                key: ValueKey(comment.id),
                comment: comment,
              );
            }).toList(),
          ),
      ],
    );
  }
}
