import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint, kDebugMode;
import '../services/driver_ride_service.dart';
import '../models/ride_request_model.dart';

class RideRequestsProvider extends ChangeNotifier {
  final DriverRideService _rideService = DriverRideService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<RideRequestModel> _rideRequests = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<RideRequestModel> get rideRequests => _rideRequests;

  /// Load ride requests for the current driver
  Future<void> loadRideRequests(int driverId) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rideRequests = await _rideService.getRideRequests(driverId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _rideRequests = [];
      if (kDebugMode) {
        debugPrint('Error loading ride requests: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Accept a ride request
  Future<bool> acceptRide(int rideId, int driverId) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _rideService.acceptRide(rideId, driverId);
      _rideRequests.removeWhere((ride) => ride.rideId == rideId);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('Error accepting ride: $e');
      }
      return false;
    }
  }

  /// Reject a ride request
  Future<bool> rejectRide(int rideId, int driverId) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _rideService.rejectRide(rideId, driverId);
      _rideRequests.removeWhere((ride) => ride.rideId == rideId);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('Error rejecting ride: $e');
      }
      return false;
    }
  }

  /// Refresh the ride requests list
  Future<void> refresh(int driverId) async {
    await loadRideRequests(driverId);
  }
}

