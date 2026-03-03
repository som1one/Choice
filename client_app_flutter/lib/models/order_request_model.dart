class OrderRequestModel {
  final int id;
  final int categoryId;
  final String description;
  final int searchRadius; // в метрах
  final bool toKnowPrice;
  final bool toKnowDeadline;
  final bool toKnowEnrollmentDate;
  final List<String> photoUris; // максимум 3
  final int status; // 0 - Active, 1 - Draft, 2 - Finished, 3 - Canceled
  final DateTime? creationDate;

  OrderRequestModel({
    required this.id,
    required this.categoryId,
    required this.description,
    required this.searchRadius,
    this.toKnowPrice = false,
    this.toKnowDeadline = false,
    this.toKnowEnrollmentDate = false,
    this.photoUris = const [],
    this.status = 0,
    this.creationDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'description': description,
      'search_radius': searchRadius,
      'to_know_price': toKnowPrice,
      'to_know_deadline': toKnowDeadline,
      'to_know_enrollment_date': toKnowEnrollmentDate,
      'photo_uris': photoUris,
    };
  }

  factory OrderRequestModel.fromJson(Map<String, dynamic> json) {
    final photoUrisJson = json['photo_uris'];
    List<String> photoUris = [];
    
    if (photoUrisJson != null) {
      if (photoUrisJson is String) {
        // Если это JSON строка, парсим её
        try {
          final decoded = (photoUrisJson as String).replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',');
          photoUris = decoded.where((s) => s.trim().isNotEmpty).map((s) => s.trim()).toList();
        } catch (_) {
          photoUris = [];
        }
      } else if (photoUrisJson is List) {
        photoUris = (photoUrisJson as List).map((e) => e.toString()).toList();
      }
    }
    
    // Обеспечиваем максимум 3 фото
    if (photoUris.length > 3) {
      photoUris = photoUris.sublist(0, 3);
    }
    while (photoUris.length < 3) {
      photoUris.add('');
    }

    final toKnowPriceStr = json['to_know_price']?.toString() ?? 'false';
    final toKnowDeadlineStr = json['to_know_deadline']?.toString() ?? 'false';
    final toKnowEnrollStr = json['to_know_enrollment_date']?.toString() ?? 'false';

    return OrderRequestModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      categoryId: (json['category_id'] as num?)?.toInt() ?? (json['categoryId'] as num?)?.toInt() ?? 1,
      description: json['description'] as String? ?? '',
      searchRadius: (json['search_radius'] as num?)?.toInt() ?? (json['searchRadius'] as num?)?.toInt() ?? 0,
      toKnowPrice: toKnowPriceStr == 'true',
      toKnowDeadline: toKnowDeadlineStr == 'true',
      toKnowEnrollmentDate: toKnowEnrollStr == 'true',
      photoUris: photoUris,
      status: (json['status'] as num?)?.toInt() ?? 0,
      creationDate: json['creation_date'] != null 
          ? DateTime.tryParse(json['creation_date'].toString())
          : json['creationDate'] != null
              ? DateTime.tryParse(json['creationDate'].toString())
              : null,
    );
  }

  OrderRequestModel copyWith({
    int? id,
    int? categoryId,
    String? description,
    int? searchRadius,
    bool? toKnowPrice,
    bool? toKnowDeadline,
    bool? toKnowEnrollmentDate,
    List<String>? photoUris,
    int? status,
    DateTime? creationDate,
  }) {
    return OrderRequestModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      searchRadius: searchRadius ?? this.searchRadius,
      toKnowPrice: toKnowPrice ?? this.toKnowPrice,
      toKnowDeadline: toKnowDeadline ?? this.toKnowDeadline,
      toKnowEnrollmentDate: toKnowEnrollmentDate ?? this.toKnowEnrollmentDate,
      photoUris: photoUris ?? this.photoUris,
      status: status ?? this.status,
      creationDate: creationDate ?? this.creationDate,
    );
  }

  bool get isActive => status == 0 || status == 1;
}
