class EnvironmentalReport {
  final int? id;
  final String clientUuid;
  final String? userId;
  final String category;
  final String description;
  final String? imagePath;
  final String area;
  final double? latitude;
  final double? longitude;
  final String status; // 'Draft', 'Submitted', 'Under Review', 'Resolved', 'Rejected'
  final DateTime createdAt;
  final String syncStatus; // 'synced', 'pending'

  EnvironmentalReport({
    this.id,
    required this.clientUuid,
    this.userId,
    required this.category,
    required this.description,
    this.imagePath,
    required this.area,
    this.latitude,
    this.longitude,
    this.status = 'Submitted',
    DateTime? createdAt,
    this.syncStatus = 'pending',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'client_uuid': clientUuid,
      'user_id': userId,
      'category': category,
      'description': description,
      'image_path': imagePath,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  factory EnvironmentalReport.fromMap(Map<String, dynamic> map) {
    return EnvironmentalReport(
      id: map['id'] as int?,
      clientUuid: map['client_uuid'] as String? ?? '',
      userId: map['user_id'] as String?,
      category: map['category'] as String? ?? 'General Waste',
      description: map['description'] as String? ?? '',
      imagePath: map['image_path'] as String?,
      area: map['area'] as String? ?? 'Campus / Local Area',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      status: map['status'] as String? ?? 'Submitted',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}
