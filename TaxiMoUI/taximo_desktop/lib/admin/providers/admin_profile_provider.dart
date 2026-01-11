import 'package:flutter/foundation.dart';
import '../services/admin_profile_service.dart';
// Note: Service file still named admin_profile_service.dart but class is UserProfileService
import '../models/user_model.dart';

class UserProfileProvider with ChangeNotifier {
  final UserProfileService _profileService = UserProfileService();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isChangingPassword = false;
  String? _errorMessage;
  String? _successMessage;
  UserModel? _userProfile;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isChangingPassword => _isChangingPassword;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  UserModel? get userProfile => _userProfile;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final data = await _profileService.getCurrentUser();
      _userProfile = UserModel.fromJson(data);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _userProfile = null;
      debugPrint('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    String? phone,
  }) async {
    if (_userProfile == null) {
      _errorMessage = 'No profile loaded';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Build update data, excluding null/empty values
      final updateData = <String, dynamic>{
        'userId': _userProfile!.userId,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'username': username.trim(),
        'changePassword': false,
      };
      
      // Only include phone if it's not null and not empty
      if (phone != null && phone.trim().isNotEmpty) {
        updateData['phone'] = phone.trim();
      }

      final data = await _profileService.updateProfile(updateData);
      
      // Safely parse the response
      if (data != null && data is Map<String, dynamic>) {
        _userProfile = UserModel.fromJson(data);
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
      debugPrint('Error updating profile: $e');
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
    if (_userProfile == null) {
      _errorMessage = 'No profile loaded';
      notifyListeners();
      return false;
    }

    _isChangingPassword = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _profileService.changePassword(
        _userProfile!.userId,
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
      debugPrint('Error changing password: $e');
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
}

