import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint, kDebugMode;
import 'package:image_picker/image_picker.dart';
import '../services/user_profile_service.dart';
import '../services/user_photo_service.dart';
import '../../auth/models/user_model.dart';

class UserProfileProvider with ChangeNotifier {
  final UserProfileService _profileService = UserProfileService();
  final UserPhotoService _photoService = UserPhotoService();

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
    // Skip if already loading to prevent duplicate calls
    if (_isLoading) return;
    
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
      if (kDebugMode) {
      debugPrint('Error loading profile: $e');
      }
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
    if (_isSaving) return false;
    
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      int userId;
      if (_userProfile != null) {
        userId = _userProfile!.userId;
      } else {
        final currentUserData = await _profileService.getCurrentUser();
        userId = currentUserData['userId'] as int;
      }

      final updateData = <String, dynamic>{
        'userId': userId,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
      };
      
      if (phone != null && phone.trim().isNotEmpty) {
        updateData['phone'] = phone.trim();
      }

      final data = await _profileService.updateProfile(userId, updateData);
      
      if (data != null && data is Map<String, dynamic>) {
        _userProfile = UserModel.fromJson(data);
        _successMessage = 'Profile updated successfully';
        _errorMessage = null;
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _successMessage = null;
      _isSaving = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('Error updating profile: $e');
      }
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_isChangingPassword) return false;
    
    _isChangingPassword = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
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

      _isChangingPassword = false;
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
      _isChangingPassword = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _successMessage = null;
      notifyListeners();
      if (kDebugMode) {
      debugPrint('Error changing password: $e');
      }
      return false;
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

  Future<bool> uploadPhoto(XFile imageFile) async {
    if (_isSaving) return false;
    
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      int userId;
      if (_userProfile != null) {
        userId = _userProfile!.userId;
      } else {
        final currentUserData = await _profileService.getCurrentUser();
        userId = currentUserData['userId'] as int;
      }

      final updatedUser = await _photoService.uploadPhoto(userId, imageFile);
      _userProfile = updatedUser;
      _successMessage = 'Photo uploaded successfully';
      _errorMessage = null;
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _successMessage = null;
      _isSaving = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('Error uploading photo: $e');
      }
      return false;
    }
  }

  Future<bool> deletePhoto() async {
    if (_isSaving) return false;
    
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      int userId;
      if (_userProfile != null) {
        userId = _userProfile!.userId;
      } else {
        final currentUserData = await _profileService.getCurrentUser();
        userId = currentUserData['userId'] as int;
      }

      final success = await _photoService.deletePhoto(userId);

      if (success) {
        await loadProfile();
        _successMessage = 'Photo deleted successfully';
        _errorMessage = null;
        // loadProfile already updates _isSaving and calls notifyListeners
        return true;
      } else {
        throw Exception('Failed to delete photo');
      }
    } catch (e) {
      _isSaving = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _successMessage = null;
      notifyListeners();
      if (kDebugMode) {
      debugPrint('Error deleting photo: $e');
      }
      return false;
    }
  }
}

