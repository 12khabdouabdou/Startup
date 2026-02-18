class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? route;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.route,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'body': body,
      'route': route,
      'is_read': isRead,
      // created_at is handled by DB default
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      route: map['route'] as String?,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
