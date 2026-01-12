import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint, kDebugMode;
import 'dart:async';
import '../services/notification_service.dart';
import '../models/notification_dto.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  Timer? _pollingTimer;

  bool _isLoading = false;
  String? _errorMessage;
  List<UserNotificationDto> _notifications = [];
  int _unreadCount = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserNotificationDto> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> loadNotifications(int userId) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.getUserNotifications(userId);
      await loadUnreadCount(userId);
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

  Future<void> loadUnreadCount(int userId) async {
    try {
      _unreadCount = await _notificationService.getUnreadCount(userId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading unread count: $e');
      }
    }
  }

  Future<bool> markAsRead(int notificationId, int userId) async {
    try {
      final result = await _notificationService.markAsRead(notificationId);
      if (result) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
        if (index != -1) {
          final notification = _notifications[index];
          _notifications[index] = UserNotificationDto(
            notificationId: notification.notificationId,
            recipientUserId: notification.recipientUserId,
            title: notification.title,
            body: notification.body,
            type: notification.type,
            isRead: true,
            sentAt: notification.sentAt,
          );
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          notifyListeners();
        }
        // Reload unread count to ensure sync
        await loadUnreadCount(userId);
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

  void startPolling(int userId, {Duration interval = const Duration(seconds: 45)}) {
    stopPolling();
    _pollingTimer = Timer.periodic(interval, (_) {
      loadNotifications(userId);
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

