import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint, kDebugMode;
import '../services/driver_ride_service.dart';
import '../models/ride_request_model.dart';

class ActiveRidesProvider extends ChangeNotifier {
  final DriverRideService _rideService = DriverRideService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<RideRequestModel> _activeRides = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<RideRequestModel> get activeRides => _activeRides;
  
  /// Get the current active ride (first active ride, if any)
  RideRequestModel? get currentActiveRide {
    if (_activeRides.isEmpty) return null;
    // Prioritize active rides over accepted rides
    final active = _activeRides.where((r) => r.status.toLowerCase() == 'active').toList();
    if (active.isNotEmpty) return active.first;
    return _activeRides.first;
  }

  /// Load active/accepted rides for the current driver
  Future<void> loadActiveRides(int driverId) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activeRides = await _rideService.getActiveRides(driverId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _activeRides = [];
      if (kDebugMode) {
      debugPrint('Error loading active rides: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start a ride (changes from Accepted to Active)
  Future<bool> startRide(int rideId) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedRide = await _rideService.startRide(rideId);
      final index = _activeRides.indexWhere((r) => r.rideId == rideId);
      if (index != -1) {
        _activeRides[index] = updatedRide;
      } else {
        _activeRides.add(updatedRide);
      }
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
      debugPrint('Error starting ride: $e');
      }
      return false;
    }
  }

  /// Complete a ride (changes from Active to Completed)
  Future<bool> completeRide(int rideId) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _rideService.completeRide(rideId);
      _activeRides.removeWhere((ride) => ride.rideId == rideId);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
      debugPrint('Error completing ride: $e');
      }
      return false;
    }
  }

  /// Refresh the active rides list
  Future<void> refresh(int driverId) async {
    await loadActiveRides(driverId);
  }

  /// Clear active rides (e.g., after logout)
  void clear() {
    _activeRides = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}

