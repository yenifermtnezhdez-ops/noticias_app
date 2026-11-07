import 'package:flutter/foundation.dart';

import '../services/bookmark_service.dart';

class BookmarkProvider extends ChangeNotifier {
  final BookmarkService _bookmarkService;

  Set<int> _bookmarkedIds = {};

  bool _isLoading = true;
  bool _isLoaded = false;

  BookmarkProvider({
    BookmarkService? bookmarkService,
  }) : _bookmarkService =
            bookmarkService ?? BookmarkService();

  Set<int> get bookmarkedIds => Set.unmodifiable(_bookmarkedIds);

  bool get isLoading => _isLoading;

  bool get isLoaded => _isLoaded;
  bool isBookmarked(int newsId) {
    return _bookmarkedIds.contains(newsId);
  }

  Future<void> loadBookmarks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final ids = await _bookmarkService.getBookmarkedIds();

      _bookmarkedIds = ids.toSet();
    } finally {
      _isLoading = false;
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(int newsId) async {
    final wasBookmarked = _bookmarkedIds.contains(newsId);

    if (wasBookmarked) {
      _bookmarkedIds.remove(newsId);
    } else {
      _bookmarkedIds.add(newsId);
    }

    notifyListeners();

    try {
      if (wasBookmarked) {
        await _bookmarkService.removeBookmark(newsId);
      } else {
        await _bookmarkService.addBookmark(newsId);
      }
    } catch (_) {
      if (wasBookmarked) {
        _bookmarkedIds.add(newsId);
      } else {
        _bookmarkedIds.remove(newsId);
      }

      notifyListeners();
      rethrow;
    }
  }
}