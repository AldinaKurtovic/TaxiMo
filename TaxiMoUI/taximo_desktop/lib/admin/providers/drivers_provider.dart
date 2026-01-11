import 'package:flutter/foundation.dart';
import '../services/drivers_service.dart';
import '../models/driver_model.dart';

class DriversProvider extends ChangeNotifier {
  final DriversService _driversService = DriversService();
  List<DriverModel> _drivers = [];
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

  List<DriverModel> get drivers => _drivers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalDrivers => _totalItems;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  List<DriverModel> get currentPageDrivers => _drivers; // Backend returns only current page data

  Future<void> loadDrivers({
    int? page,
    String? search,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use page parameter or current page, reset to 1 if filters change
      final pageToLoad = page ?? _currentPage;
      
      // Get paginated data from backend
      final response = await _driversService.getDrivers(
        page: pageToLoad,
        limit: _itemsPerPage,
        search: search ?? _searchQuery,
        isActive: isActive ?? _statusFilter,
      );
      
      // Extract data and pagination info
      final data = response['data'] as List<dynamic>;
      final pagination = response['pagination'] as Map<String, dynamic>;
      
      _drivers = data
          .map((json) => DriverModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Update pagination info
      _currentPage = pagination['currentPage'] as int;
      _totalPages = pagination['totalPages'] as int;
      _totalItems = pagination['totalItems'] as int;
      
      // Store current filter values
      if (search != null) _searchQuery = search;
      if (isActive != null) _statusFilter = isActive;
      
      // Apply client-side sorting if needed
      if (_sortColumn != null) {
        _drivers.sort((a, b) {
          int comparison = 0;
          switch (_sortColumn) {
            case 'name':
              comparison = a.fullName.compareTo(b.fullName);
              break;
            case 'email':
              comparison = a.email.compareTo(b.email);
              break;
          }
          return _sortAscending ? comparison : -comparison;
        });
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _drivers = [];
      _totalPages = 1;
      _totalItems = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    // Reset to page 1 when search changes
    loadDrivers(search: query, isActive: _statusFilter, page: 1);
  }

  void setStatusFilter(bool? isActive) {
    _statusFilter = isActive;
    // Reset to page 1 when filter changes
    loadDrivers(search: _searchQuery, isActive: isActive, page: 1);
  }

  void sort(String column) {
    // Don't allow sorting by status
    if (column == 'status') return;
    
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = true;
    }
    
    // Apply client-side sorting only (backend data is already paginated)
    if (_sortColumn != null) {
      _drivers.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn) {
          case 'name':
            comparison = a.fullName.compareTo(b.fullName);
            break;
          case 'email':
            comparison = a.email.compareTo(b.email);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }
    
    notifyListeners();
  }

  void goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      loadDrivers(page: page, search: _searchQuery, isActive: _statusFilter);
    }
  }

  void nextPage() {
    if (_currentPage < _totalPages) {
      loadDrivers(page: _currentPage + 1, search: _searchQuery, isActive: _statusFilter);
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      loadDrivers(page: _currentPage - 1, search: _searchQuery, isActive: _statusFilter);
    }
  }

  Future<void> createDriver(Map<String, dynamic> driverData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _driversService.createDriver(driverData);
      // Reload current page after create
      await loadDrivers(page: _currentPage, search: _searchQuery, isActive: _statusFilter);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDriver(int id, Map<String, dynamic> driverData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _driversService.updateDriver(id, driverData);
      // Reload current page after update
      await loadDrivers(page: _currentPage, search: _searchQuery, isActive: _statusFilter);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDriver(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _driversService.deleteDriver(id);
      // Reload current page after delete, or go to previous page if current page is empty
      var pageToLoad = _currentPage;
      if (_drivers.length <= 1 && _currentPage > 1) {
        pageToLoad = _currentPage - 1;
      }
      await loadDrivers(page: pageToLoad, search: _searchQuery, isActive: _statusFilter);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
