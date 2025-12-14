import 'package:flutter/foundation.dart';
import '../services/drivers_service.dart';
import '../models/driver_model.dart';

class DriversProvider extends ChangeNotifier {
  final DriversService _driversService = DriversService();
  List<DriverModel> _drivers = [];
  List<DriverModel> _filteredDrivers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int get totalPages => (_filteredDrivers.length / _itemsPerPage).ceil();
  int get currentPage => _currentPage;
  List<DriverModel> get currentPageDrivers {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredDrivers.sublist(
      startIndex,
      endIndex > _filteredDrivers.length ? _filteredDrivers.length : endIndex,
    );
  }

  // Sorting
  String? _sortColumn;
  bool _sortAscending = true;

  // Filtering
  String? _searchQuery;
  bool? _statusFilter;

  List<DriverModel> get drivers => _drivers;
  List<DriverModel> get filteredDrivers => _filteredDrivers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalDrivers => _filteredDrivers.length;

  Future<void> loadDrivers({String? search, bool? isActive}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use backend filtering with search and status
      final driversList = await _driversService.getDrivers(
        search: search ?? _searchQuery,
        isActive: isActive ?? _statusFilter,
      );
      _drivers = driversList
          .map((json) => DriverModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Store current filter values
      if (search != null) _searchQuery = search;
      if (isActive != null) _statusFilter = isActive;
      
      // Apply only client-side sorting (backend handles search and status)
      _filteredDrivers = List<DriverModel>.from(_drivers);
      
      if (_sortColumn != null) {
        _filteredDrivers.sort((a, b) {
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

      // Reset to first page if current page is out of bounds
      if (_currentPage > totalPages && totalPages > 0) {
        _currentPage = 1;
      }
      
      _currentPage = 1;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _drivers = [];
      _filteredDrivers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    // Reload from backend with new search
    loadDrivers(search: query, isActive: _statusFilter);
  }

  void setStatusFilter(bool? isActive) {
    _statusFilter = isActive;
    // Reload from backend with new status filter
    loadDrivers(search: _searchQuery, isActive: isActive);
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
    
    // Apply client-side sorting only
    if (_sortColumn != null) {
      _filteredDrivers.sort((a, b) {
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

  Future<void> createDriver(Map<String, dynamic> driverData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _driversService.createDriver(driverData);
      await loadDrivers(search: _searchQuery, isActive: _statusFilter);
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
      await loadDrivers(search: _searchQuery, isActive: _statusFilter);
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
      await loadDrivers(search: _searchQuery, isActive: _statusFilter);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

