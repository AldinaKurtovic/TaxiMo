import 'package:flutter/foundation.dart';
import '../services/reviews_service.dart';
import '../models/review_model.dart';

class ReviewsProvider extends ChangeNotifier {
  final ReviewsService _reviewsService = ReviewsService();
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Pagination (backend-driven)
  int _currentPage = 1;
  final int _itemsPerPage = 7;
  int _totalPages = 1;
  int _totalItems = 0;

  // Sorting (client-side only for now)
  String? _sortColumn;
  bool _sortAscending = true;

  // Filtering
  String? _searchQuery;
  double? _minRatingFilter;
  String? _driverNameFilter; // Client-side filter

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalReviews => _totalItems;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  
  // Apply client-side driver name filter to backend data
  List<ReviewModel> get currentPageReviews {
    if (_driverNameFilter != null && _driverNameFilter!.isNotEmpty) {
      return _reviews.where((review) => review.driverName == _driverNameFilter).toList();
    }
    return _reviews; // Backend returns only current page data
  }

  Future<void> fetchAll({
    int? page,
    String? search,
    double? minRating,
    String? driverName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use page parameter or current page, reset to 1 if filters change
      final pageToLoad = page ?? _currentPage;
      
      // Get paginated data from backend
      final response = await _reviewsService.getAll(
        page: pageToLoad,
        limit: _itemsPerPage,
        search: search ?? _searchQuery,
        minRating: minRating ?? _minRatingFilter,
      );
      
      // Extract data and pagination info
      final data = response['data'] as List<dynamic>;
      final pagination = response['pagination'] as Map<String, dynamic>;
      
      _reviews = data
          .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Update pagination info
      _currentPage = pagination['currentPage'] as int;
      _totalPages = pagination['totalPages'] as int;
      _totalItems = pagination['totalItems'] as int;
      
      // Store current filter values
      if (search != null) _searchQuery = search;
      if (minRating != null) _minRatingFilter = minRating;
      if (driverName != null) {
        _driverNameFilter = driverName == 'All' ? null : driverName;
      }
      
      // Apply client-side sorting if needed
      if (_sortColumn != null) {
        _reviews.sort((a, b) {
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

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _reviews = [];
      _totalPages = 1;
      _totalItems = 0;
      debugPrint('Error fetching reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String? query) {
    _searchQuery = query;
    // Reset to page 1 when search changes
    fetchAll(
      search: query,
      minRating: _minRatingFilter,
      driverName: _driverNameFilter != null ? _driverNameFilter : 'All',
      page: 1,
    );
  }

  void setMinRatingFilter(double? minRating) {
    _minRatingFilter = minRating;
    // Reset to page 1 when filter changes
    fetchAll(
      search: _searchQuery,
      minRating: minRating,
      driverName: _driverNameFilter != null ? _driverNameFilter : 'All',
      page: 1,
    );
  }

  void setDriverNameFilter(String? driverName) {
    _driverNameFilter = driverName == 'All' ? null : driverName;
    // Driver name filter is client-side only, no need to reload from backend
    _currentPage = 1;
    notifyListeners();
  }

  // Note: This needs to fetch all reviews to get driver names, or use a separate endpoint
  // For now, using reviews from current page
  List<String> get availableDriverNames {
    final driverNames = _reviews.map((review) => review.driverName).toSet().toList();
    driverNames.sort();
    return driverNames;
  }

  String? get driverNameFilter => _driverNameFilter;

  void sort(String column) {
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = true;
    }
    
    // Apply client-side sorting only (backend data is already paginated)
    if (_sortColumn != null) {
      _reviews.sort((a, b) {
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
    if (page >= 1 && page <= _totalPages) {
      fetchAll(
        page: page,
        search: _searchQuery,
        minRating: _minRatingFilter,
        driverName: _driverNameFilter != null ? _driverNameFilter : 'All',
      );
    }
  }

  void nextPage() {
    if (_currentPage < _totalPages) {
      fetchAll(
        page: _currentPage + 1,
        search: _searchQuery,
        minRating: _minRatingFilter,
        driverName: _driverNameFilter != null ? _driverNameFilter : 'All',
      );
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      fetchAll(
        page: _currentPage - 1,
        search: _searchQuery,
        minRating: _minRatingFilter,
        driverName: _driverNameFilter != null ? _driverNameFilter : 'All',
      );
    }
  }

  Future<void> update(int id, Map<String, dynamic> reviewData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reviewsService.update(id, reviewData);
      // Reload current page after update
      await fetchAll(
        page: _currentPage,
        search: _searchQuery,
        minRating: _minRatingFilter,
        driverName: _driverNameFilter != null ? _driverNameFilter : 'All',
      );
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
      // Reload current page after delete, or go to previous page if current page is empty
      var pageToLoad = _currentPage;
      if (_reviews.length <= 1 && _currentPage > 1) {
        pageToLoad = _currentPage - 1;
      }
      await fetchAll(
        page: pageToLoad,
        search: _searchQuery,
        minRating: _minRatingFilter,
        driverName: _driverNameFilter != null ? _driverNameFilter : 'All',
      );
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting review: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
