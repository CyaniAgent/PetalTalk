class User {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String slug;
  final String joinTime;
  final int discussionCount;
  final int commentCount;
  final bool canEdit;
  final bool canEditCredentials;
  final bool canEditGroups;
  final bool canDelete;
  final String? lastSeenAt;
  final bool isEmailConfirmed;
  final bool isAdmin;
  final Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.slug,
    required this.joinTime,
    required this.discussionCount,
    required this.commentCount,
    required this.canEdit,
    required this.canEditCredentials,
    required this.canEditGroups,
    required this.canDelete,
    this.lastSeenAt,
    required this.isEmailConfirmed,
    required this.isAdmin,
    required this.preferences,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['attributes']['username'],
      displayName: json['attributes']['displayName'],
      avatarUrl: json['attributes']['avatarUrl'],
      slug: json['attributes']['slug'],
      joinTime: json['attributes']['joinTime'],
      discussionCount: json['attributes']['discussionCount'],
      commentCount: json['attributes']['commentCount'],
      canEdit: json['attributes']['canEdit'],
      canEditCredentials: json['attributes']['canEditCredentials'],
      canEditGroups: json['attributes']['canEditGroups'],
      canDelete: json['attributes']['canDelete'],
      lastSeenAt: json['attributes']['lastSeenAt'],
      isEmailConfirmed: json['attributes']['isEmailConfirmed'],
      isAdmin: json['attributes']['isAdmin'],
      preferences: json['attributes']['preferences'],
    );
  }
}
