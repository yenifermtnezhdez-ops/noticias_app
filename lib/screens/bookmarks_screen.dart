
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/news_model.dart';
import '../providers/bookmark_provider.dart';
import '../services/news_service.dart';
import '../components/news_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final NewsService _newsService = NewsService();

  BookmarkProvider? _bookmarkProvider;

  List<int>? _requestedIds;
  Future<List<NewsModel>>? _newsFuture;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _bookmarkProvider = context.read<BookmarkProvider>();

      _bookmarkProvider!.addListener(_onBookmarksChanged);

      _syncBookmarks();
    });
  }

  @override
  void dispose() {
    _bookmarkProvider?.removeListener(_onBookmarksChanged);
    super.dispose();
  }

  // Detecta cambios en los favoritos.
  void _onBookmarksChanged() {
    _syncBookmarks();
  }

  // Recupera las noticias guardadas desde WordPress.
  void _syncBookmarks() {
    if (!mounted || _bookmarkProvider == null) return;

    if (!_bookmarkProvider!.isLoaded) return;

    final ids = _bookmarkProvider!.bookmarkedIds.toList();

    if (_sameIds(ids, _requestedIds)) return;

    setState(() {
      _requestedIds = ids;

      if (ids.isEmpty) {
        _newsFuture = Future.value([]);
      } else {
        _newsFuture = _newsService.getNewsByIds(ids);
      }
    });
  }

  // Comprueba si los identificadores cambiaron.
  bool _sameIds(List<int> current, List<int>? previous) {
    if (previous == null || current.length != previous.length) {
      return false;
    }

    for (int i = 0; i < current.length; i++) {
      if (current[i] != previous[i]) {
        return false;
      }
    }

    return true;
  }

  // Indicador de carga.
  Widget _buildLoading() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando noticias guardadas...',
            style: TextStyle(
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // Mensaje cuando no hay favoritos.
  Widget _buildEmpty() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 85,
              color: colors.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 20),
            Text(
              'Todavía no tienes noticias guardadas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Guarda las noticias que te interesen '
              'para encontrarlas aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mensaje de error al recuperar noticias.
  Widget _buildError() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 65,
              color: colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'No fue posible recuperar las noticias guardadas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _newsFuture = _newsService.getNewsByIds(
                    _requestedIds ?? [],
                  );
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      ),
    );
  }

  // Lista de noticias guardadas.
  Widget _buildNewsList(List<NewsModel> news) {
    final colors = Theme.of(context).colorScheme;

    if (news.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Las noticias guardadas ya no están disponibles.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colors.onSurface,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: news.length,
      itemBuilder: (context, index) {
        return NewsCard(
          key: ValueKey(news[index].id),
          news: news[index],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();

    Widget content;

    if (!bookmarkProvider.isLoaded || _newsFuture == null) {
      content = _buildLoading();
    } else if (bookmarkProvider.bookmarkedIds.isEmpty) {
      content = _buildEmpty();
    } else {
      content = FutureBuilder<List<NewsModel>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          if (snapshot.hasError) {
            return _buildError();
          }

          return _buildNewsList(snapshot.data ?? []);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis noticias guardadas'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey(
            bookmarkProvider.bookmarkedIds.length.toString() +
                (bookmarkProvider.isLoaded ? 'loaded' : 'loading'),
          ),
          child: content,
        ),
      ),
    );
  }
}
