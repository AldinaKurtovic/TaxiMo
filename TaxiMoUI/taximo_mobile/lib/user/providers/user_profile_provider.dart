import 'package:flutter/foundation.dart';
import '../services/user_profile_service.dart';
import '../../auth/models/user_model.dart';

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
    String? phone,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Get userId from loaded profile or fetch it
      int userId;
      if (_userProfile != null) {
        userId = _userProfile!.userId;
      } else {
        final currentUserData = await _profileService.getCurrentUser();
        userId = currentUserData['userId'] as int;
      }

      // Build update data with userId and fields to update
      final updateData = <String, dynamic>{
        'userId': userId,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
      };
      
      // Only include phone if it's not null and not empty
      if (phone != null && phone.trim().isNotEmpty) {
        updateData['phone'] = phone.trim();
      }

      final data = await _profileService.updateProfile(userId, updateData);
      
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
    _isChangingPassword = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Get userId from loaded profile or fetch it
      int userId;
      if (_userProfile != null) {
        userId = _userProfile!.userId;
      } else {
        final currentUserData = await _profileService.getCurrentUser();
        userId = currentUserData['userId'] as int;
      }

      final success = await _profileService.changePassword(
        userId,
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

  void updateUserFromAuth(UserModel user) {
    _userProfile = user;
    notifyListeners();
  }
}

