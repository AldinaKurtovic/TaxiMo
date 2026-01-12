import 'package:flutter/foundation.dart';
import '../services/promo_service.dart';
import '../models/promo_model.dart';

class PromoProvider extends ChangeNotifier {
  final PromoService _promoService = PromoService();
  List<PromoModel> _promoCodes = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Pagination (backend-driven)
  int _currentPage = 1;
  final int _itemsPerPage = 7;
  int _totalPages = 1;
  int _totalItems = 0;

  // Sorting
  String? _sortColumn;
  bool _sortAscending = true;

  // Filtering
  String? _searchQuery;
  bool? _statusFilter;

  List<PromoModel> get promoCodes => _promoCodes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalPromoCodes => _totalItems;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  List<PromoModel> get currentPagePromoCodes => _promoCodes; // Backend returns only current page data

  Future<void> fetchAll({
    int? page,
    String? search,
    bool? isActive,
    String? sortBy,
    String? sortOrder,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use page parameter or current page, reset to 1 if filters change
      final pageToLoad = page ?? _currentPage;
      
      // Use sortBy/sortOrder from parameters or stored values
      final sortByToUse = sortBy ?? _sortColumn;
      final sortOrderToUse = sortOrder ?? (_sortAscending ? 'asc' : 'desc');
      
      // Get paginated data from backend
      final response = await _promoService.getAll(
        page: pageToLoad,
        limit: _itemsPerPage,
        search: search ?? _searchQuery,
        isActive: isActive ?? _statusFilter,
        sortBy: sortByToUse,
        sortOrder: sortOrderToUse,
      );
      
      // Extract data and pagination info
      final data = response['data'] as List<dynamic>;
      final pagination = response['pagination'] as Map<String, dynamic>;
      
      _promoCodes = data
          .map((json) => PromoModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Update pagination info
      _currentPage = pagination['currentPage'] as int;
      _totalPages = pagination['totalPages'] as int;
      _totalItems = pagination['totalItems'] as int;
      
      // Store current filter and sort values
      if (search != null) _searchQuery = search;
      if (isActive != null) _statusFilter = isActive;
      if (sortBy != null) _sortColumn = sortBy;
      if (sortOrder != null) _sortAscending = sortOrder.toLowerCase() == 'asc';

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _promoCodes = [];
      _totalPages = 1;
      _totalItems = 0;
      debugPrint('Error fetching promo codes: $e');
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
      isActive: _statusFilter,
      sortBy: _sortColumn,
      sortOrder: _sortAscending ? 'asc' : 'desc',
      page: 1,
    );
  }

  void setStatusFilter(bool? isActive) {
    _statusFilter = isActive;
    // Reset to page 1 when filter changes
    fetchAll(
      search: _searchQuery,
      isActive: isActive,
      sortBy: _sortColumn,
      sortOrder: _sortAscending ? 'asc' : 'desc',
      page: 1,
    );
  }

  void sort(String column) {
    // Only allow sorting by code and discount
    if (column != 'code' && column != 'discount') return;
    
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = true;
    }
    
    // Reload from backend with new sort
    fetchAll(
      search: _searchQuery,
      isActive: _statusFilter,
      sortBy: _sortColumn,
      sortOrder: _sortAscending ? 'asc' : 'desc',
      page: _currentPage, // Keep current page when sorting
    );
  }

  void goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      fetchAll(
        page: page,
        search: _searchQuery,
        isActive: _statusFilter,
        sortBy: _sortColumn,
        sortOrder: _sortAscending ? 'asc' : 'desc',
      );
    }
  }

  void nextPage() {
    if (_currentPage < _totalPages) {
      fetchAll(
        page: _currentPage + 1,
        search: _searchQuery,
        isActive: _statusFilter,
        sortBy: _sortColumn,
        sortOrder: _sortAscending ? 'asc' : 'desc',
      );
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      fetchAll(
        page: _currentPage - 1,
        search: _searchQuery,
        isActive: _statusFilter,
        sortBy: _sortColumn,
        sortOrder: _sortAscending ? 'asc' : 'desc',
      );
    }
  }

  Future<void> add(Map<String, dynamic> promoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _promoService.create(promoData);
      // Reload current page after create
      await fetchAll(
        page: _currentPage,
        search: _searchQuery,
        isActive: _statusFilter,
        sortBy: _sortColumn,
        sortOrder: _sortAscending ? 'asc' : 'desc',
      );
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error adding promo code: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> update(int id, Map<String, dynamic> promoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _promoService.update(id, promoData);
      // Reload current page after update
      await fetchAll(
        page: _currentPage,
        search: _searchQuery,
        isActive: _statusFilter,
        sortBy: _sortColumn,
        sortOrder: _sortAscending ? 'asc' : 'desc',
      );
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating promo code: $e');
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
      await _promoService.delete(id);
      // Reload current page after delete, or go to previous page if current page is empty
      var pageToLoad = _currentPage;
      if (_promoCodes.length <= 1 && _currentPage > 1) {
        pageToLoad = _currentPage - 1;
      }
      await fetchAll(
        page: pageToLoad,
        search: _searchQuery,
        isActive: _statusFilter,
        sortBy: _sortColumn,
        sortOrder: _sortAscending ? 'asc' : 'desc',
      );
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting promo code: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
