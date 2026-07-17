enum FriendshipStatus {
  pending,
  accepted;

  static FriendshipStatus fromValue(String? value) {
    return value == 'pending'
        ? FriendshipStatus.pending
        : FriendshipStatus.accepted;
  }
}

class Friendship {
  final String id;
  final String requesterId;
  final String addresseeId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime? requesterSeenAt;
  final DateTime? addresseeSeenAt;

  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.requesterSeenAt,
    this.addresseeSeenAt,
  });

  String otherProfileId(String myId) {
    return requesterId == myId ? addresseeId : requesterId;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterId': requesterId,
      'addresseeId': addresseeId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'requesterSeenAt': requesterSeenAt?.toIso8601String(),
      'addresseeSeenAt': addresseeSeenAt?.toIso8601String(),
    };
  }

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String,
      requesterId: json['requesterId'] as String,
      addresseeId: json['addresseeId'] as String,
      status: FriendshipStatus.fromValue(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      requesterSeenAt: json['requesterSeenAt'] != null
          ? DateTime.parse(json['requesterSeenAt'] as String)
          : null,
      addresseeSeenAt: json['addresseeSeenAt'] != null
          ? DateTime.parse(json['addresseeSeenAt'] as String)
          : null,
    );
  }
}

class FriendNotification {
  final Friendship friendship;
  final UserProfileSummary otherProfile;
  final bool isIncoming;
  final bool isUnread;

  const FriendNotification({
    required this.friendship,
    required this.otherProfile,
    required this.isIncoming,
    required this.isUnread,
  });

  bool get isIncomingRequest =>
      isIncoming && friendship.status == FriendshipStatus.pending;
}

class UserProfileSummary {
  final String id;
  final String name;
  final String? avatarPath;
  final int? avatarColor;

  const UserProfileSummary({
    required this.id,
    required this.name,
    this.avatarPath,
    this.avatarColor,
  });
}
