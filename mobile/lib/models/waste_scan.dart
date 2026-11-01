class WasteScan {
  final int? id;
  final String? userId;
  final String imagePath;
  final String predictedClass;
  final double confidence;
  final String? confirmedClass;
  final DateTime createdAt;
  final String syncStatus; // 'synced', 'pending', 'local'
  final String? disposalGuidance;

  WasteScan({
    this.id,
    this.userId,
    required this.imagePath,
    required this.predictedClass,
    required this.confidence,
    this.confirmedClass,
    DateTime? createdAt,
    this.syncStatus = 'pending',
    this.disposalGuidance,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'image_path': imagePath,
      'predicted_class': predictedClass,
      'confidence': confidence,
      'confirmed_class': confirmedClass ?? predictedClass,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus,
      'disposal_guidance': disposalGuidance,
    };
  }

  factory WasteScan.fromMap(Map<String, dynamic> map) {
    return WasteScan(
      id: map['id'] as int?,
      userId: map['user_id'] as String?,
      imagePath: map['image_path'] as String? ?? '',
      predictedClass: map['predicted_class'] as String? ?? 'General Waste',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      confirmedClass: map['confirmed_class'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      syncStatus: map['sync_status'] as String? ?? 'pending',
      disposalGuidance: map['disposal_guidance'] as String?,
    );
  }
}
