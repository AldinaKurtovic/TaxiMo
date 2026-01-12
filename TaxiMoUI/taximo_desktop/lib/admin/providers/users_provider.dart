import 'package:flutter/foundation.dart';
import '../services/users_service.dart';
import '../models/user_model.dart';

class UsersProvider extends ChangeNotifier {
  final UsersService _usersService = UsersService();
  List<UserModel> _users = [];
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

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalUsers => _totalItems;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  List<UserModel> get currentPageUsers => _users; // Backend returns only current page data

  Future<void> loadUsers({
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
      final response = await _usersService.getUsers(
        page: pageToLoad,
        limit: _itemsPerPage,
        search: search ?? _searchQuery,
        isActive: isActive ?? _statusFilter,
      );
      
      // Extract data and pagination info
      final data = response['data'] as List<dynamic>;
      final pagination = response['pagination'] as Map<String, dynamic>;
      
      _users = data
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
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
        _users.sort((a, b) {
          int comparison = 0;
          switch (_sortColumn) {
            case 'name':
              comparison = a.fullName.compareTo(b.fullName);
              break;
            case 'email':
              comparison = a.email.compareTo(b.email);
              break;
            case 'dateOfBirth':
              final aDate = a.dateOfBirth ?? DateTime(1900);
              final bDate = b.dateOfBirth ?? DateTime(1900);
              comparison = aDate.compareTo(bDate);
              break;
          }
          return _sortAscending ? comparison : -comparison;
        });
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _users = [];
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
    loadUsers(search: query, isActive: _statusFilter, page: 1);
  }

  void setStatusFilter(bool? isActive) {
    _statusFilter = isActive;
    // Reset to page 1 when filter changes
    loadUsers(search: _searchQuery, isActive: isActive, page: 1);
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
      _users.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn) {
          case 'name':
            comparison = a.fullName.compareTo(b.fullName);
            break;
          case 'email':
            comparison = a.email.compareTo(b.email);
            break;
          case 'dateOfBirth':
            final aDate = a.dateOfBirth ?? DateTime(1900);
            final bDate = b.dateOfBirth ?? DateTime(1900);
            comparison = aDate.compareTo(bDate);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }
    
    notifyListeners();
  }

  void goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      loadUsers(page: page, search: _searchQuery, isActive: _statusFilter);
    }
  }

  void nextPage() {
    if (_currentPage < _totalPages) {
      loadUsers(page: _currentPage + 1, search: _searchQuery, isActive: _statusFilter);
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      loadUsers(page: _currentPage - 1, search: _searchQuery, isActive: _statusFilter);
    }
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _usersService.createUser(userData);
      // Reload current page after create
      await loadUsers(page: _currentPage, search: _searchQuery, isActive: _statusFilter);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _usersService.updateUser(id, userData);
      // Reload current page after update
      await loadUsers(page: _currentPage, search: _searchQuery, isActive: _statusFilter);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _usersService.deleteUser(id);
      // Reload current page after delete, or go to previous page if current page is empty
      var pageToLoad = _currentPage;
      if (_users.length <= 1 && _currentPage > 1) {
        pageToLoad = _currentPage - 1;
      }
      await loadUsers(page: pageToLoad, search: _searchQuery, isActive: _statusFilter);
    } catch (e) {
      // Don't set errorMessage - error will be shown via SnackBar in the dialog
      // Always reload users list to display all users even if delete failed
      await loadUsers(page: _currentPage, search: _searchQuery, isActive: _statusFilter);
      // Re-throw exception so it can be caught in the dialog and shown as SnackBar
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
