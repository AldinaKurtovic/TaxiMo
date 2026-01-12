import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint, kDebugMode;
import 'dart:async';
import '../services/notification_service.dart';
import '../models/notification_dto.dart';

class DriverNotificationProvider with ChangeNotifier {
  final DriverNotificationService _notificationService = DriverNotificationService();
  Timer? _pollingTimer;

  bool _isLoading = false;
  String? _errorMessage;
  List<DriverNotificationDto> _notifications = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<DriverNotificationDto> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications(int driverId) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.getDriverNotifications(driverId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _notifications = [];
      if (kDebugMode) {
        debugPrint('Error loading notifications: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final result = await _notificationService.markAsRead(notificationId);
      if (result) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
        if (index != -1) {
          final notification = _notifications[index];
          _notifications[index] = DriverNotificationDto(
            notificationId: notification.notificationId,
            recipientDriverId: notification.recipientDriverId,
            title: notification.title,
            body: notification.body,
            type: notification.type,
            isRead: true,
            sentAt: notification.sentAt,
          );
          notifyListeners();
        }
      }
      return result;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (kDebugMode) {
        debugPrint('Error marking notification as read: $e');
      }
      return false;
    }
  }

  void startPolling(int driverId, {Duration interval = const Duration(seconds: 45)}) {
    stopPolling();
    _pollingTimer = Timer.periodic(interval, (_) {
      loadNotifications(driverId);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

