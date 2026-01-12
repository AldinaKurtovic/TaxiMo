class DriverNotificationDto {
  final int notificationId;
  final int recipientDriverId;
  final String title;
  final String? body;
  final String type;
  final bool isRead;
  final DateTime sentAt;

  DriverNotificationDto({
    required this.notificationId,
    required this.recipientDriverId,
    required this.title,
    this.body,
    required this.type,
    required this.isRead,
    required this.sentAt,
  });

  factory DriverNotificationDto.fromJson(Map<String, dynamic> json) {
    return DriverNotificationDto(
      notificationId: json['notificationId'] as int,
      recipientDriverId: json['recipientDriverId'] as int,
      title: json['title'] as String,
      body: json['body'] as String?,
      type: json['type'] as String,
      isRead: json['isRead'] as bool,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'recipientDriverId': recipientDriverId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'sentAt': sentAt.toIso8601String(),
    };
  }

  String get formattedSentAt {
    final now = DateTime.now();
    final difference = now.difference(sentAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${sentAt.day}.${sentAt.month}.${sentAt.year}';
    }
  }
}

