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
  List<RideModel> _activeRides = []; // Separate list for active rides (for map)
  List<DriverModel> _freeDrivers = [];
  RideFilter _currentFilter = RideFilter.all;
  String? _searchQuery;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<RideModel> get rides => _rides;
  List<RideModel> get activeRides => _activeRides; // Getter for active rides (for map)
  List<DriverModel> get freeDrivers => _freeDrivers;
  RideFilter get currentFilter => _currentFilter;
  String? get searchQuery => _searchQuery;

  // All filtering is done on backend, so rides getter returns the filtered list
  List<RideModel> get filteredRides => _rides;

  Future<void> fetchRides({String? search, String? status}) async {
    if (_currentFilter == RideFilter.freeDrivers) {
      return; // Don't fetch rides when showing free drivers
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use current search query if search parameter is not provided
      final searchQuery = search ?? _searchQuery;
      final ridesList = await _ridesService.getAll(search: searchQuery, status: status);
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
      // Fetch with current search query and status filter
      fetchRides(search: _searchQuery, status: status).then((_) {
        // Also fetch free drivers when filter is "all" to show them first
        if (filter == RideFilter.all) {
          _fetchFreeDriversSilent();
        }
      });
    }
    // Always refresh active rides for the map regardless of filter
    fetchActiveRides();
    notifyListeners();
  }

  // Fetch free drivers without affecting loading state (for use when combining with rides)
  Future<void> _fetchFreeDriversSilent() async {
    try {
      final driversList = await _ridesService.getFreeDrivers();
      _freeDrivers = driversList
          .map((json) => DriverModel.fromJson(json as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching free drivers silently: $e');
      _freeDrivers = [];
      notifyListeners();
    }
  }

  void search(String? query) {
    _searchQuery = query;
    if (_currentFilter != RideFilter.freeDrivers) {
      // Determine status based on current filter
      String? status;
      if (_currentFilter == RideFilter.completed) {
        status = 'completed';
      } else if (_currentFilter == RideFilter.cancelled) {
        status = 'cancelled';
      }
      // Fetch from backend with search and status
      fetchRides(search: query, status: status);
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
      fetchRides(search: _searchQuery, status: status).then((_) {
        // Also refresh free drivers when filter is "all"
        if (_currentFilter == RideFilter.all) {
          _fetchFreeDriversSilent();
        }
      });
    }
    // Always refresh active rides for the map
    fetchActiveRides();
  }

  // Fetch active rides separately for the map (always shows active rides regardless of filter)
  // Fetches all rides and filters client-side for active/accepted/requested status
  Future<void> fetchActiveRides() async {
    try {
      // Fetch all rides (no status filter) to get active rides
      final ridesList = await _ridesService.getAll();
      _activeRides = ridesList
          .map((json) => RideModel.fromJson(json as Map<String, dynamic>))
          .where((ride) {
            final statusLower = ride.status.toLowerCase();
            return statusLower == 'active' || statusLower == 'accepted' || statusLower == 'requested';
          })
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching active rides: $e');
      _activeRides = [];
    }
  }

  // Initial load method
  Future<void> loadRides() async {
    await fetchRides();
    await _fetchFreeDriversSilent(); // Also fetch free drivers for "all" filter (silent to not interfere with loading state)
    await fetchActiveRides(); // Also fetch active rides for the map
  }

  // Assign driver to ride
  Future<void> assignDriver(int rideId, int driverId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _ridesService.assignDriver(rideId, driverId);
      _errorMessage = null;
      
      // Refresh rides and free drivers
      await fetchRides(search: _searchQuery, status: _currentFilter == RideFilter.completed ? 'completed' : _currentFilter == RideFilter.cancelled ? 'cancelled' : null);
      await fetchFreeDrivers();
      await fetchActiveRides();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error assigning driver: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

