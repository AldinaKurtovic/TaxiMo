import 'package:flutter/foundation.dart';
import '../services/users_service.dart';
import '../models/user_model.dart';

class UsersProvider extends ChangeNotifier {
  final UsersService _usersService = UsersService();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int get totalPages => (_filteredUsers.length / _itemsPerPage).ceil();
  int get currentPage => _currentPage;
  List<UserModel> get currentPageUsers {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredUsers.sublist(
      startIndex,
      endIndex > _filteredUsers.length ? _filteredUsers.length : endIndex,
    );
  }

  // Sorting
  String? _sortColumn;
  bool _sortAscending = true;

  // Filtering
  String? _searchQuery;
  bool? _statusFilter;

  List<UserModel> get users => _users;
  List<UserModel> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalUsers => _filteredUsers.length;

  Future<void> loadUsers({String? search, bool? isActive}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use backend filtering with search and status
      final usersList = await _usersService.getUsers(
        search: search ?? _searchQuery,
        isActive: isActive ?? _statusFilter,
      );
      _users = usersList
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Store current filter values
      if (search != null) _searchQuery = search;
      if (isActive != null) _statusFilter = isActive;
      
      // Apply only client-side sorting (backend handles search and status)
      _filteredUsers = List<UserModel>.from(_users);
      
      if (_sortColumn != null) {
        _filteredUsers.sort((a, b) {
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

      // Reset to first page if current page is out of bounds
      if (_currentPage > totalPages && totalPages > 0) {
        _currentPage = 1;
      }
      
      _currentPage = 1;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _users = [];
      _filteredUsers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    // Reload from backend with new search
    loadUsers(search: query, isActive: _statusFilter);
  }

  void setStatusFilter(bool? isActive) {
    _statusFilter = isActive;
    // Reload from backend with new status filter
    loadUsers(search: _searchQuery, isActive: isActive);
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
      _filteredUsers.sort((a, b) {
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

  Future<void> createUser(Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _usersService.createUser(userData);
      await loadUsers(search: _searchQuery, isActive: _statusFilter);
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
      await loadUsers(search: _searchQuery, isActive: _statusFilter);
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
      await loadUsers(search: _searchQuery, isActive: _statusFilter);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
