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

  // Filtering
  String? _searchQuery;
  bool? _statusFilter;

  List<PromoModel> get promoCodes => _promoCodes;
  List<PromoModel> get filteredPromoCodes => _filteredPromoCodes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAll({String? search, bool? isActive}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final promoCodesList = await _promoService.getAll(
        search: search,
        isActive: isActive,
      );
      _promoCodes = promoCodesList
          .map((json) => PromoModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      _searchQuery = search;
      _statusFilter = isActive;
      _applyFilters();
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

  void _applyFilters() {
    _filteredPromoCodes = List<PromoModel>.from(_promoCodes);

    // Apply search filter
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      _filteredPromoCodes = _filteredPromoCodes.where((promo) {
        return promo.code.toLowerCase().contains(query) ||
            (promo.description != null && promo.description!.toLowerCase().contains(query)) ||
            promo.status.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    if (_statusFilter != null) {
      _filteredPromoCodes = _filteredPromoCodes.where((promo) {
        return _statusFilter! ? promo.isActive : !promo.isActive;
      }).toList();
    }

    // Reset to first page if current page is out of bounds
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = 1;
    }
  }

  void search(String? query) {
    _searchQuery = query;
    _applyFilters();
    _currentPage = 1;
    notifyListeners();
  }

  void setStatusFilter(bool? isActive) {
    _statusFilter = isActive;
    _applyFilters();
    _currentPage = 1;
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

  Future<void> add(Map<String, dynamic> promoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _promoService.create(promoData);
      await fetchAll(search: _searchQuery, isActive: _statusFilter);
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
      await fetchAll(search: _searchQuery, isActive: _statusFilter);
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
      await fetchAll(search: _searchQuery, isActive: _statusFilter);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting promo code: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

