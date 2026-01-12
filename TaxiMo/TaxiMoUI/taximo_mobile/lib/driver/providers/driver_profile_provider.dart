import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/driver_profile_service.dart';
import '../models/driver_model.dart';
import '../../user/models/driver_dto.dart';

class DriverProfileProvider with ChangeNotifier {
  final DriverProfileService _profileService = DriverProfileService();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isChangingPassword = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;
  String? _successMessage;
  DriverModel? _driverProfile;
  DriverDto? _driverDto;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isChangingPassword => _isChangingPassword;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  DriverModel? get driverProfile => _driverProfile;
  DriverDto? get driverDto => _driverDto;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final data = await _profileService.getCurrentDriver();
      _driverProfile = DriverModel.fromJson(data);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _driverProfile = null;
      debugPrint('Error loading driver profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Get driverId from loaded profile or fetch it
      int driverId;
      if (_driverProfile != null) {
        driverId = _driverProfile!.driverId;
      } else {
        final currentDriverData = await _profileService.getCurrentDriver();
        driverId = currentDriverData['driverId'] as int;
      }

      // Build update data with driverId and fields to update
      final updateData = <String, dynamic>{
        'driverId': driverId,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
      };
      
      // Only include phone if it's not null and not empty
      if (phone != null && phone.trim().isNotEmpty) {
        updateData['phone'] = phone.trim();
      }

      final data = await _profileService.updateProfile(driverId, updateData);
      
      // Safely parse the response
      if (data != null && data is Map<String, dynamic>) {
        _driverProfile = DriverModel.fromJson(data);
        _successMessage = 'Profile updated successfully';
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _successMessage = null;
      notifyListeners();
      debugPrint('Error updating driver profile: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isChangingPassword = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Get driverId from loaded profile or fetch it
      int driverId;
      if (_driverProfile != null) {
        driverId = _driverProfile!.driverId;
      } else {
        final currentDriverData = await _profileService.getCurrentDriver();
        driverId = currentDriverData['driverId'] as int;
      }

      final success = await _profileService.changePassword(
        driverId,
        oldPassword,
        newPassword,
        confirmPassword,
      );

      if (success) {
        _successMessage = 'Password changed successfully';
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to change password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _successMessage = null;
      notifyListeners();
      debugPrint('Error changing driver password: $e');
      return false;
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void updateDriverFromAuth(DriverModel driver) {
    _driverProfile = driver;
    notifyListeners();
  }

  void setDriverDto(DriverDto dto) {
    _driverDto = dto;
    notifyListeners();
  }

  /// Upload driver profile photo
  Future<bool> uploadPhoto(File imageFile) async {
    _isUploadingPhoto = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Get driverId from loaded profile or fetch it
      int driverId;
      if (_driverProfile != null) {
        driverId = _driverProfile!.driverId;
      } else {
        final currentDriverData = await _profileService.getCurrentDriver();
        driverId = currentDriverData['driverId'] as int;
      }

      // Upload photo
      final data = await _profileService.uploadPhoto(driverId, imageFile);
      
      // Update driver profile with new photoUrl
      if (data != null && data is Map<String, dynamic>) {
        _driverProfile = DriverModel.fromJson(data);
        _successMessage = 'Photo uploaded successfully';
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _successMessage = null;
      notifyListeners();
      debugPrint('Error uploading driver photo: $e');
      return false;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }
}

