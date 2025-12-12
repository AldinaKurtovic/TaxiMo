import 'package:flutter/foundation.dart';
import '../services/rides_service.dart';
import '../models/ride_model.dart';
import '../models/driver_model.dart';

enum RideFilter { all, completed, cancelled, freeDrivers }

class RidesProvider with ChangeNotifier {
  final RidesService _ridesService = RidesService();

  bool _isLoading = false;
  String? _errorMessage;
  List<RideModel> _rides = [];
  List<DriverModel> _freeDrivers = [];
  RideFilter _currentFilter = RideFilter.all;
  String? _searchQuery;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<RideModel> get rides => _rides;
  List<DriverModel> get freeDrivers => _freeDrivers;
  RideFilter get currentFilter => _currentFilter;
  String? get searchQuery => _searchQuery;

  List<RideModel> get filteredRides {
    if (_currentFilter == RideFilter.freeDrivers) {
      return [];
    }

    var filtered = List<RideModel>.from(_rides);

    // Apply status filter
    if (_currentFilter == RideFilter.completed) {
      filtered = filtered.where((r) => r.status.toLowerCase() == 'completed').toList();
    } else if (_currentFilter == RideFilter.cancelled) {
      filtered = filtered.where((r) => r.status.toLowerCase() == 'cancelled').toList();
    }

    // Apply search filter
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((ride) {
        return ride.driverName.toLowerCase().contains(query) ||
            ride.riderName.toLowerCase().contains(query) ||
            ride.vehicleCode.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  Future<void> fetchRides({String? search, String? status}) async {
    if (_currentFilter == RideFilter.freeDrivers) {
      return; // Don't fetch rides when showing free drivers
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ridesList = await _ridesService.getAll(search: search, status: status);
      _rides = ridesList
          .map((json) => RideModel.fromJson(json as Map<String, dynamic>))
          .toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _rides = [];
      debugPrint('Error fetching rides: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFreeDrivers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final driversList = await _ridesService.getFreeDrivers();
      _freeDrivers = driversList
          .map((json) => DriverModel.fromJson(json as Map<String, dynamic>))
          .toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _freeDrivers = [];
      debugPrint('Error fetching free drivers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(RideFilter filter) {
    _currentFilter = filter;
    if (filter == RideFilter.freeDrivers) {
      fetchFreeDrivers();
    } else {
      String? status;
      if (filter == RideFilter.completed) {
        status = 'completed';
      } else if (filter == RideFilter.cancelled) {
        status = 'cancelled';
      }
      fetchRides(status: status);
    }
    notifyListeners();
  }

  void search(String? query) {
    _searchQuery = query;
    if (_currentFilter != RideFilter.freeDrivers) {
      fetchRides(search: query);
    }
    notifyListeners();
  }

  void refresh() {
    if (_currentFilter == RideFilter.freeDrivers) {
      fetchFreeDrivers();
    } else {
      String? status;
      if (_currentFilter == RideFilter.completed) {
        status = 'completed';
      } else if (_currentFilter == RideFilter.cancelled) {
        status = 'cancelled';
      }
      fetchRides(search: _searchQuery, status: status);
    }
  }
}

