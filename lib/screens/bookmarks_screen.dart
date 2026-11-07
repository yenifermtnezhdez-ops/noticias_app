
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
  void _onBookmarksChanged() {
    _syncBookmarks();
  }
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

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.deepPurple,
          ),
          SizedBox(height: 16),
          Text('Cargando noticias guardadas...'),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 85,
              color: Colors.deepPurple.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Todavía no tienes noticias guardadas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Guarda las noticias que te interesen '
              'para encontrarlas aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 65,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'No fue posible recuperar las noticias guardadas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
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

  Widget _buildNewsList(List<NewsModel> news) {
    if (news.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Las noticias guardadas ya no están disponibles.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: news.length,
      itemBuilder: (context, index) {
        return NewsCard(news: news[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();

    if (!bookmarkProvider.isLoaded || _newsFuture == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis noticias guardadas'),
        ),
        body: _buildLoading(),
      );
    }

    if (bookmarkProvider.bookmarkedIds.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis noticias guardadas'),
        ),
        body: _buildEmpty(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis noticias guardadas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<NewsModel>>(
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
      ),
    );
  }
}
