import 'package:flutter/foundation.dart';
import '../services/driver_auth_service.dart';
import '../models/driver_model.dart';
import '../../user/services/driver_service.dart';
import '../../user/models/driver_dto.dart';

class DriverProvider extends ChangeNotifier {
  final DriverAuthService _authService = DriverAuthService();
  final DriverService _driverService = DriverService();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isAuthLocked = false; // RJEŠENJE 3: Lock mehanizam za payment flow
  String? _errorMessage;
  DriverModel? _currentDriver;
  DriverDto? _driverProfile;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isAuthLocked => _isAuthLocked; // RJEŠENJE 3: Public getter za lock status
  String? get errorMessage => _errorMessage;
  DriverModel? get currentDriver => _currentDriver;
  DriverDto? get driverProfile => _driverProfile;

  // RJEŠENJE 3: Lock/unlock mehanizam za payment flow
  void lockAuth() {
    if (!_isAuthLocked) {
      _isAuthLocked = true;
      // Notify listeners jer AuthWrapper Selector prati isAuthLocked promjene
      notifyListeners();
    }
  }

  void unlockAuth() {
    if (_isAuthLocked) {
      _isAuthLocked = false;
      // Notify listeners jer AuthWrapper Selector prati isAuthLocked promjene
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final driver = await _authService.login(username, password);

      if (driver != null) {
        _currentDriver = driver;
        _isAuthenticated = true;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        
        // Load driver profile after successful login (async, don't block)
        loadDriverProfile(username).catchError((e) {
          debugPrint('Failed to load driver profile: $e');
        });
        
        return true;
      } else {
        _isAuthenticated = false;
        _currentDriver = null;
        _errorMessage = "Invalid username or password";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentDriver = null;
      _errorMessage = "An error occurred. Please try again.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadDriverProfile(String username) async {
    try {
      final profile = await _driverService.getDriverByUsername(username);
      // RJEŠENJE 4: Optimizirano - notifyListeners() samo ako se vrijednost promijenila
      if (_driverProfile != profile) {
        _driverProfile = profile;
        // Safe to call notifyListeners - AuthWrapper Selector doesn't watch driverProfile
        // Only widgets that specifically need driverProfile will rebuild
      notifyListeners();
      }
    } catch (e) {
      // Log error but don't block login
      debugPrint('Failed to load driver profile: $e');
    }
  }

  void logout() {
    _isAuthenticated = false;
    _currentDriver = null;
    _driverProfile = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // RJEŠENJE 4: Optimizirano - notifyListeners() samo ako se vrijednost promijenila
  set currentDriver(DriverModel? driver) {
    // Ne mijenjaj ako je ista referenca - sprječava nepotrebne rebuildove
    if (_currentDriver == driver) return;
    
    _currentDriver = driver;
    // RJEŠENJE 2: currentDriver setter ne mijenja isAuthenticated direktno
    // AuthWrapper NE prati currentDriver direktno (samo isAuthenticated), tako da je OK
    notifyListeners();
  }
}

