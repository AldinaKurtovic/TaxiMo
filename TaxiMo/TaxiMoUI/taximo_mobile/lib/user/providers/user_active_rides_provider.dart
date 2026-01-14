import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint, kDebugMode;
import '../services/ride_service.dart';
import '../models/ride_history_dto.dart';

class UserActiveRidesProvider extends ChangeNotifier {
  final RideService _rideService = RideService();
  
  bool _isLoading = false;
  bool _isCancelling = false;
  String? _errorMessage;
  List<RideHistoryDto> _activeRides = [];

  bool get isLoading => _isLoading;
  bool get isCancelling => _isCancelling;
  String? get errorMessage => _errorMessage;
  List<RideHistoryDto> get activeRides => _activeRides;
  
  /// Get the current active ride (first active ride, if any)
  RideHistoryDto? get currentActiveRide {
    if (_activeRides.isEmpty) return null;
    // Prioritize active rides over accepted rides over requested rides
    final active = _activeRides.where((r) => r.status.toLowerCase() == 'active').toList();
    if (active.isNotEmpty) return active.first;
    final accepted = _activeRides.where((r) => r.status.toLowerCase() == 'accepted').toList();
    if (accepted.isNotEmpty) return accepted.first;
    return _activeRides.first;
  }

  /// Load active rides for the current user
  Future<void> loadActiveRides(int riderId) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ridesData = await _rideService.getActiveRides(riderId);
      _activeRides = ridesData
          .map((json) => RideHistoryDto.fromJson(json))
          .toList();
      
      // Sort by requested date (most recent first)
      _activeRides.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      
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

  /// Cancel a ride
  Future<bool> cancelRide(int rideId) async {
    if (_isCancelling) return false;
    
    _isCancelling = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _rideService.cancelRide(rideId);
      
      // Remove the cancelled ride from the list
      _activeRides.removeWhere((ride) => ride.rideId == rideId);
      
      _errorMessage = null;
      _isCancelling = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isCancelling = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('Error cancelling ride: $e');
      }
      return false;
    }
  }
}

