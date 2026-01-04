class Notification {
  final String id;
  final String type;
  final bool isRead;
  final String createdAt;
  final Map<String, dynamic>? data;

  Notification({
    required this.id,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      type: json['attributes']['type'],
      isRead: json['attributes']['isRead'],
      createdAt: json['attributes']['createdAt'],
      data: json['attributes']['data'],
    );
  }
}
