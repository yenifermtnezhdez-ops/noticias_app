
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

  String _formatDate(String rawDate) {
    final date = DateTime.tryParse(rawDate);

    if (date == null) return rawDate;

    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${date.day} de ${months[date.month - 1]} '
        'de ${date.year}';
  }

  Future<void> _toggleBookmark(
    BuildContext context,
    bool isBookmarked,
  ) async {
    final colors = Theme.of(context).colorScheme;

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
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final bookmarkProvider =
        context.watch<BookmarkProvider>();

    final isBookmarked =
        bookmarkProvider.isBookmarked(news.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de noticia'),
        actions: [
          IconButton(
            onPressed: bookmarkProvider.isLoading
                ? null
                : () => _toggleBookmark(
                      context,
                      isBookmarked,
                    ),
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
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          35,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
 
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.newspaper_rounded,
                        color: colors.primary,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ARTÍCULO',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'ID ${news.id}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                news.title,
                key: ValueKey(news.id),
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  height: 1.28,
                  letterSpacing: -0.8,
                ),
              ),
            ),

            const SizedBox(height: 18),

       
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: colors.primary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Publicado',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDate(news.date),
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Divider(
              color: colors.outline.withValues(alpha: 0.4),
            ),

            const SizedBox(height: 20),

         
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Text(
                  'Contenido de la noticia',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                17,
                12,
                17,
                17,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.outline.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
              child: Html(
                data: news.content,
                style: {
                  'body': Style(
                    fontSize: FontSize(15),
                    lineHeight: LineHeight.number(1.7),
                    color: colors.onSurface,
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                  'p': Style(
                    color: colors.onSurface,
                    margin: Margins.only(bottom: 15),
                    lineHeight: LineHeight.number(1.7),
                  ),
                  'h1': Style(
                    fontSize: FontSize(23),
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                    margin: Margins.only(
                      top: 15,
                      bottom: 12,
                    ),
                  ),
                  'h2': Style(
                    fontSize: FontSize(21),
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                    margin: Margins.only(
                      top: 16,
                      bottom: 10,
                    ),
                  ),
                  'h3': Style(
                    fontSize: FontSize(18),
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                    margin: Margins.only(
                      top: 14,
                      bottom: 8,
                    ),
                  ),
                  'a': Style(
                    color: colors.primary,
                    textDecoration: TextDecoration.underline,
                  ),
                  'strong': Style(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                  'blockquote': Style(
                    color: colors.primary,
                    fontStyle: FontStyle.italic,
                    padding: HtmlPaddings.only(left: 12),
                    margin: Margins.only(
                      top: 12,
                      bottom: 12,
                    ),
                    border: Border(
                      left: BorderSide(
                        color: colors.primary,
                        width: 3,
                      ),
                    ),
                  ),
                  'li': Style(
                    color: colors.onSurface,
                    margin: Margins.only(bottom: 6),
                  ),
                },
              ),
            ),

            const SizedBox(height: 30),

           
            Divider(
              color: colors.outline.withValues(alpha: 0.4),
            ),

            const SizedBox(height: 23),

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
  State<_CommentsSection> createState() =>
      _CommentsSectionState();
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
          content: Text(
            'Escribe un comentario antes de publicarlo.',
          ),
        ),
      );
      return;
    }

    final commentProvider =
        context.read<CommentProvider>();

    if (commentProvider.isWriting) return;

    final success = await commentProvider.addComment(
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
          content: Text(
            'Comentario publicado correctamente.',
          ),
        ),
      );
    } else {
      final message =
          commentProvider.errorMessage;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message ??
                'No fue posible publicar el comentario.',
          ),
        ),
      );
    }
  }

  Widget _buildCommentForm(
    BuildContext context,
    bool isWriting,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparte tu opinión',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            enabled: !isWriting,
            minLines: 3,
            maxLines: 5,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText:
                  '¿Qué opinas sobre esta noticia?',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 43),
                child: Icon(Icons.edit_note_rounded),
              ),
              filled: true,
              fillColor: colors.surfaceContainerHighest
                  .withValues(alpha: 0.45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: colors.outline.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: colors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isWriting ? null : _sendComment,
              icon: isWriting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                isWriting
                    ? 'Publicando comentario...'
                    : 'Publicar comentario',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginNotice(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: colors.onPrimaryContainer,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Inicia sesión para compartir tu opinión '
              'sobre esta noticia.',
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final currentUser =
        context.watch<AuthProvider>().user;

    final commentProvider =
        context.watch<CommentProvider>();

    return Column(
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
                Icons.forum_rounded,
                color: colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conversación',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Comparte tus ideas con la comunidad',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${commentProvider.commentCount}',
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 19),

        // FORMULARIO O AVISO DE SESIÓN
        if (currentUser != null)
          _buildCommentForm(
            context,
            commentProvider.isWriting,
          )
        else
          _buildLoginNotice(context),

        const SizedBox(height: 23),

        // LISTADO DE COMENTARIOS
        Row(
          children: [
            Text(
              'Comentarios publicados',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              '${commentProvider.comments.length}',
              style: TextStyle(
                color: colors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 13),

        if (commentProvider.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              commentProvider.errorMessage!,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontSize: 12,
              ),
            ),
          ),

        if (commentProvider.isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: CircularProgressIndicator(
                color: colors.primary,
              ),
            ),
          )
        else if (commentProvider.comments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: colors.outline.withValues(
                  alpha: 0.4,
                ),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 38,
                  color: colors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Todavía no hay comentarios',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '¡Sé la primera persona en compartir '
                  'su opinión!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
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
