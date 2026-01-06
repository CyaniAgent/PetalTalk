class Notification {
  final String id;
  final String contentType;
  final Map<String, dynamic> content;
  final String createdAt;
  final bool isRead;
  final String fromUserId;
  final String subjectId;
  final String subjectType;
  
  // 关联数据
  final Map<String, dynamic>? fromUser;
  final Map<String, dynamic>? subject;

  Notification({
    required this.id,
    required this.contentType,
    required this.content,
    required this.createdAt,
    required this.isRead,
    required this.fromUserId,
    required this.subjectId,
    required this.subjectType,
    this.fromUser,
    this.subject,
  });

  factory Notification.fromJson(Map<String, dynamic> json, Map<String, Map<String, dynamic>> includedData) {
    final fromUserId = json['relationships']['fromUser']?['data']?['id'];
    final subjectId = json['relationships']['subject']?['data']?['id'];
    final subjectType = json['relationships']['subject']?['data']?['type'];
    
    // 从included数据中获取用户和主题信息
    final fromUser = fromUserId != null ? includedData['users_$fromUserId'] : null;
    final subject = subjectId != null && subjectType != null ? includedData['${subjectType}_$subjectId'] : null;
    
    return Notification(
      id: json['id'],
      contentType: json['attributes']['contentType'],
      content: json['attributes']['content'],
      createdAt: json['attributes']['createdAt'],
      isRead: json['attributes']['isRead'],
      fromUserId: fromUserId ?? 'unknown',
      subjectId: subjectId ?? 'unknown',
      subjectType: subjectType ?? 'discussions',
      fromUser: fromUser,
      subject: subject,
    );
  }
}
