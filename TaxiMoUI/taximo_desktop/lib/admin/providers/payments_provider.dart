import 'package:flutter/foundation.dart';
import '../services/payments_service.dart';
import '../models/payment_model.dart';

class PaymentsProvider extends ChangeNotifier {
  final PaymentsService _paymentsService = PaymentsService();
  List<PaymentModel> _payments = [];
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

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalPayments => _totalItems;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  
  // Backend returns only current page data
  List<PaymentModel> get currentPagePayments {
    // Apply client-side sorting if needed
    var sortedPayments = List<PaymentModel>.from(_payments);
    if (_sortColumn != null) {
      sortedPayments.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn) {
          case 'paymentId':
            comparison = a.paymentId.compareTo(b.paymentId);
            break;
          case 'rideId':
            comparison = a.rideId.compareTo(b.rideId);
            break;
          case 'userId':
            comparison = a.userId.compareTo(b.userId);
            break;
          case 'amount':
            comparison = a.amount.compareTo(b.amount);
            break;
          case 'currency':
            comparison = a.currency.compareTo(b.currency);
            break;
          case 'method':
            comparison = a.method.compareTo(b.method);
            break;
          case 'status':
            comparison = a.status.compareTo(b.status);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }
    return sortedPayments;
  }

  Future<void> fetchAll({
    int? page,
    String? search,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use page parameter or current page, reset to 1 if filters change
      final pageToLoad = page ?? _currentPage;
      
      // Get paginated data from backend
      final response = await _paymentsService.getAll(
        page: pageToLoad,
        limit: _itemsPerPage,
        search: search ?? _searchQuery,
      );
      
      // Extract data and pagination info
      final data = response['data'] as List<dynamic>;
      final pagination = response['pagination'] as Map<String, dynamic>;
      
      _payments = data
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Update pagination info
      _currentPage = pagination['currentPage'] as int;
      _totalPages = pagination['totalPages'] as int;
      _totalItems = pagination['totalItems'] as int;
      
      // Store current filter values
      if (search != null) _searchQuery = search;
      
      // Apply client-side sorting if needed
      if (_sortColumn != null) {
        _payments.sort((a, b) {
          int comparison = 0;
          switch (_sortColumn) {
            case 'paymentId':
              comparison = a.paymentId.compareTo(b.paymentId);
              break;
            case 'rideId':
              comparison = a.rideId.compareTo(b.rideId);
              break;
            case 'userId':
              comparison = a.userId.compareTo(b.userId);
              break;
            case 'amount':
              comparison = a.amount.compareTo(b.amount);
              break;
            case 'currency':
              comparison = a.currency.compareTo(b.currency);
              break;
            case 'method':
              comparison = a.method.compareTo(b.method);
              break;
            case 'status':
              comparison = a.status.compareTo(b.status);
              break;
          }
          return _sortAscending ? comparison : -comparison;
        });
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _payments = [];
      _totalPages = 1;
      _totalItems = 0;
      debugPrint('Error fetching payments: $e');
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
      page: 1,
    );
  }

  void sort(String column) {
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = true;
    }
    
    // Apply client-side sorting only (backend data is already paginated)
    if (_sortColumn != null) {
      _payments.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn) {
          case 'paymentId':
            comparison = a.paymentId.compareTo(b.paymentId);
            break;
          case 'rideId':
            comparison = a.rideId.compareTo(b.rideId);
            break;
          case 'userId':
            comparison = a.userId.compareTo(b.userId);
            break;
          case 'amount':
            comparison = a.amount.compareTo(b.amount);
            break;
          case 'currency':
            comparison = a.currency.compareTo(b.currency);
            break;
          case 'method':
            comparison = a.method.compareTo(b.method);
            break;
          case 'status':
            comparison = a.status.compareTo(b.status);
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
      );
    }
  }

  void nextPage() {
    if (_currentPage < _totalPages) {
      fetchAll(
        page: _currentPage + 1,
        search: _searchQuery,
      );
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      fetchAll(
        page: _currentPage - 1,
        search: _searchQuery,
      );
    }
  }

  void refresh() {
    fetchAll(
      page: _currentPage,
      search: _searchQuery,
    );
  }
}

