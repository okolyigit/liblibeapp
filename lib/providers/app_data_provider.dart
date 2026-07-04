import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';
import '../models/library.dart';
import '../models/user_book_progress.dart';

/// Centralized data provider that manages all app data streams.
/// Uses Firestore real-time listeners and provides cached data to the UI.
class AppDataProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Core data
  List<Library> _libraries = [];
  List<Book> _allBooks = [];
  List<UserBookProgress> _userProgress = [];

  // State
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _librariesSub;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _booksSubs = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _progressSub;
  StreamSubscription<User?>? _authSub;

  // Getters
  List<Library> get libraries => _libraries;
  List<Book> get allBooks => _allBooks;
  List<UserBookProgress> get userProgress => _userProgress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;

  // Computed: Books in a specific library
  List<Book> getLibraryBooks(String libraryId) {
    return _allBooks.where((b) => b.libraryId == libraryId).toList();
  }


  // Computed: Recently added books (across all accessible libraries)
  List<Book> get recentlyAddedBooks {
    final sorted = List<Book>.from(_allBooks)
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
    return sorted.take(10).toList();
  }

  // Computed: User stats
  Map<String, int> get userStats {
    return {'total': _allBooks.length};
  }

  // Get progress for a specific book
  UserBookProgress? getProgressForBook(String bookId) {
    try {
      return _userProgress.firstWhere((p) => p.bookId == bookId);
    } catch (_) {
      return null;
    }
  }

  /// Initialize data provider - call this after the app starts
  AppDataProvider() {
    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null && user.uid != _currentUserId) {
        _currentUserId = user.uid;
        _startListening(user.uid);
      } else if (user == null) {
        _currentUserId = null;
        _clearData();
      }
    });
  }

  void _cancelAllBooksSubs() {
    for (final s in _booksSubs) {
      s.cancel();
    }
    _booksSubs.clear();
  }

  void _clearData() {
    _librariesSub?.cancel();
    _cancelAllBooksSubs();
    _progressSub?.cancel();
    _libraries = [];
    _allBooks = [];
    _userProgress = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _startListening(String userId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Listen to libraries where user is a member
    _librariesSub?.cancel();
    _librariesSub = _firestore
        .collection('libraries')
        .where('members', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
          _libraries =
              snapshot.docs.map((d) => Library.fromFirestore(d)).toList()
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          _onDataUpdated();
          _updateBooksListener();
        }, onError: (e) => _handleError('Kütüphaneler yüklenirken hata: $e'));

    // 2. Listen to user's book_progress
    _progressSub?.cancel();
    _progressSub = _firestore
        .collection('users')
        .doc(userId)
        .collection('book_progress')
        .snapshots()
        .listen(
          (snapshot) {
            _userProgress = snapshot.docs
                .map((d) => UserBookProgress.fromFirestore(d))
                .toList();
            _onDataUpdated();
          },
          onError: (e) =>
              _handleError('Okuma ilerlemeniz yüklenirken hata: $e'),
        );
  }

  void _updateBooksListener() {
    _cancelAllBooksSubs();

    final libraryIds = _libraries.map((l) => l.id).toList();
    if (libraryIds.isEmpty) {
      _allBooks = [];
      _onDataUpdated();
      return;
    }

    // Firestore whereIn supports max 30 values per query; run one listener per chunk.
    const chunkSize = 30;
    final chunks = <List<String>>[];
    for (var i = 0; i < libraryIds.length; i += chunkSize) {
      final end = i + chunkSize > libraryIds.length
          ? libraryIds.length
          : i + chunkSize;
      chunks.add(libraryIds.sublist(i, end));
    }

    final chunkBooks = List<List<Book>>.generate(chunks.length, (_) => []);

    void mergeChunksAndNotify() {
      final byId = <String, Book>{};
      for (final list in chunkBooks) {
        for (final b in list) {
          byId[b.id] = b;
        }
      }
      _allBooks = byId.values.toList();
      _onDataUpdated();
    }

    for (var c = 0; c < chunks.length; c++) {
      final chunkIndex = c;
      final sub = _firestore
          .collection('books')
          .where('libraryId', whereIn: chunks[c])
          .snapshots()
          .listen(
            (snapshot) {
              chunkBooks[chunkIndex] =
                  snapshot.docs.map((d) => Book.fromFirestore(d)).toList();
              mergeChunksAndNotify();
            },
            onError: (e) =>
                _handleError('Kitaplar yüklenirken hata: $e'),
          );
      _booksSubs.add(sub);
    }
  }

  void _onDataUpdated() {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _handleError(String message) {
    debugPrint('AppDataProvider Error: $message');
    _isLoading = false;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _librariesSub?.cancel();
    _cancelAllBooksSubs();
    _progressSub?.cancel();
    super.dispose();
  }
}
