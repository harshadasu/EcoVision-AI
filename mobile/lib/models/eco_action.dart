class EcoAction {
  final int? id;
  final String? userId;
  final String actionType;
  final int points;
  final String verificationStatus; // 'Verified', 'Pending', 'Rejected'
  final DateTime createdAt;

  EcoAction({
    this.id,
    this.userId,
    required this.actionType,
    required this.points,
    this.verificationStatus = 'Verified',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'action_type': actionType,
      'points': points,
      'verification_status': verificationStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EcoAction.fromMap(Map<String, dynamic> map) {
    return EcoAction(
      id: map['id'] as int?,
      userId: map['user_id'] as String?,
      actionType: map['action_type'] as String? ?? '',
      points: map['points'] as int? ?? 0,
      verificationStatus: map['verification_status'] as String? ?? 'Verified',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class RewardItem {
  final int id;
  final String name;
  final String description;
  final int pointsRequired;
  final String icon;
  final bool active;

  RewardItem({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsRequired,
    required this.icon,
    this.active = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'points_required': pointsRequired,
      'icon': icon,
      'active': active ? 1 : 0,
    };
  }

  factory RewardItem.fromMap(Map<String, dynamic> map) {
    return RewardItem(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      pointsRequired: map['points_required'] as int? ?? 100,
      icon: map['icon'] as String? ?? 'award',
      active: (map['active'] as int? ?? 1) == 1,
    );
  }
}
