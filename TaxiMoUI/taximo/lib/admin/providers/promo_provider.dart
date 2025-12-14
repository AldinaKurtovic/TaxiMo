import 'package:flutter/foundation.dart';
import '../services/promo_service.dart';
import '../models/promo_model.dart';

class PromoProvider extends ChangeNotifier {
  final PromoService _promoService = PromoService();
  List<PromoModel> _promoCodes = [];
  List<PromoModel> _filteredPromoCodes = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int get totalPages => (_filteredPromoCodes.length / _itemsPerPage).ceil();
  int get currentPage => _currentPage;
  int get totalItems => _filteredPromoCodes.length;
  List<PromoModel> get currentPagePromoCodes {
    if (_filteredPromoCodes.isEmpty) return [];
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredPromoCodes.sublist(
      startIndex,
      endIndex > _filteredPromoCodes.length ? _filteredPromoCodes.length : endIndex,
    );
  }

  // Sorting
  String? _sortColumn;
  bool _sortAscending = true;

  // Filtering
  String? _searchQuery;
  bool? _statusFilter;

  List<PromoModel> get promoCodes => _promoCodes;
  List<PromoModel> get filteredPromoCodes => _filteredPromoCodes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAll({String? search, bool? isActive, String? sortBy, String? sortOrder}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use backend filtering and sorting
      final promoCodesList = await _promoService.getAll(
        search: search ?? _searchQuery,
        isActive: isActive ?? _statusFilter,
        sortBy: sortBy ?? _sortColumn,
        sortOrder: sortOrder ?? (_sortAscending ? 'asc' : 'desc'),
      );
      _promoCodes = promoCodesList
          .map((json) => PromoModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Store current filter and sort values
      if (search != null) _searchQuery = search;
      if (isActive != null) _statusFilter = isActive;
      if (sortBy != null) _sortColumn = sortBy;
      if (sortOrder != null) _sortAscending = sortOrder.toLowerCase() == 'asc';
      
      // Backend handles all filtering and sorting, so just use the results directly
      _filteredPromoCodes = List<PromoModel>.from(_promoCodes);
      
      _currentPage = 1;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _promoCodes = [];
      _filteredPromoCodes = [];
      debugPrint('Error fetching promo codes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String? query) {
    _searchQuery = query;
    // Reload from backend with new search
    fetchAll(search: query, isActive: _statusFilter, sortBy: _sortColumn, sortOrder: _sortAscending ? 'asc' : 'desc');
  }

  void setStatusFilter(bool? isActive) {
    _statusFilter = isActive;
    // Reload from backend with new status filter
    fetchAll(search: _searchQuery, isActive: isActive, sortBy: _sortColumn, sortOrder: _sortAscending ? 'asc' : 'desc');
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
    );
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

  Future<void> add(Map<String, dynamic> promoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _promoService.create(promoData);
      await fetchAll(
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
      await fetchAll(
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
      await fetchAll(
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

