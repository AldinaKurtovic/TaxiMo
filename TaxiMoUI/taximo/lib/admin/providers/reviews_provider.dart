import 'package:flutter/foundation.dart';
import '../services/reviews_service.dart';
import '../models/review_model.dart';

class ReviewsProvider extends ChangeNotifier {
  final ReviewsService _reviewsService = ReviewsService();
  List<ReviewModel> _reviews = [];
  List<ReviewModel> _filteredReviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int get totalPages => (_filteredReviews.length / _itemsPerPage).ceil();
  int get currentPage => _currentPage;
  int get totalItems => _filteredReviews.length;
  List<ReviewModel> get currentPageReviews {
    if (_filteredReviews.isEmpty) return [];
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredReviews.sublist(
      startIndex,
      endIndex > _filteredReviews.length ? _filteredReviews.length : endIndex,
    );
  }

  // Sorting
  String? _sortColumn;
  bool _sortAscending = true;

  // Filtering
  String? _searchQuery;
  double? _minRatingFilter;

  List<ReviewModel> get reviews => _reviews;
  List<ReviewModel> get filteredReviews => _filteredReviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAll({String? search, double? minRating}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reviewsList = await _reviewsService.getAll(
        search: search,
        minRating: minRating,
      );
      
      // Debug: Log the response
      print('Reviews response: $reviewsList');
      
      _reviews = reviewsList
          .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      _searchQuery = search;
      _minRatingFilter = minRating;
      _applyFilters();
      
      // Apply sorting after filtering
      if (_sortColumn != null) {
        _filteredReviews.sort((a, b) {
          int comparison = 0;
          switch (_sortColumn) {
            case 'userName':
              comparison = a.userName.compareTo(b.userName);
              break;
            case 'driverName':
              comparison = a.driverName.compareTo(b.driverName);
              break;
            case 'description':
              final aDesc = a.description ?? '';
              final bDesc = b.description ?? '';
              comparison = aDesc.compareTo(bDesc);
              break;
          }
          return _sortAscending ? comparison : -comparison;
        });
      }
      
      _currentPage = 1;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _reviews = [];
      _filteredReviews = [];
      debugPrint('Error fetching reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredReviews = List<ReviewModel>.from(_reviews);

    // Apply search filter (client-side if needed)
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      _filteredReviews = _filteredReviews.where((review) {
        return review.description?.toLowerCase().contains(query) == true ||
            review.userName.toLowerCase().contains(query) ||
            review.driverName.toLowerCase().contains(query);
      }).toList();
    }

    // Apply rating filter (client-side if needed)
    if (_minRatingFilter != null) {
      _filteredReviews = _filteredReviews.where((review) {
        return review.rating >= _minRatingFilter!;
      }).toList();
    }

    // Reset to first page if current page is out of bounds
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = 1;
    }
  }

  void search(String? query) {
    _searchQuery = query;
    // Re-fetch from API with search parameter
    fetchAll(search: query, minRating: _minRatingFilter);
  }

  void setMinRatingFilter(double? minRating) {
    _minRatingFilter = minRating;
    // Re-fetch from API with rating filter
    fetchAll(search: _searchQuery, minRating: minRating);
  }

  void sort(String column) {
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = true;
    }
    
    // Apply client-side sorting
    if (_sortColumn != null) {
      _filteredReviews.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn) {
          case 'userName':
            comparison = a.userName.compareTo(b.userName);
            break;
          case 'driverName':
            comparison = a.driverName.compareTo(b.driverName);
            break;
          case 'description':
            final aDesc = a.description ?? '';
            final bDesc = b.description ?? '';
            comparison = aDesc.compareTo(bDesc);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }
    
    notifyListeners();
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void nextPage() {
    if (_currentPage < totalPages) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }

  Future<void> update(int id, Map<String, dynamic> reviewData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reviewsService.update(id, reviewData);
      await fetchAll(search: _searchQuery, minRating: _minRatingFilter);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating review: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> delete(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reviewsService.delete(id);
      await fetchAll(search: _searchQuery, minRating: _minRatingFilter);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting review: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

