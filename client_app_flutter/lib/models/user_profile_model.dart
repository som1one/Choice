class UserProfileModel {
  final String? fullName;
  final String? address;
  final String? email;
  final String? phone;
  final String? rating;
  final String? photoUrl;
  final bool isBlocked;
  final bool askPrice;
  final bool askSpecialist;
  final bool askAppointmentTime;
  final bool askAvailability;
  final bool askWorkTime;
  final int searchRadiusKm;

  UserProfileModel({
    this.fullName,
    this.address,
    this.email,
    this.phone,
    this.rating,
    this.photoUrl,
    this.isBlocked = false,
    this.askPrice = true,
    this.askSpecialist = true,
    this.askAppointmentTime = true,
    this.askAvailability = true,
    this.askWorkTime = true,
    this.searchRadiusKm = 20,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'address': address,
      'email': email,
      'phone': phone,
      'rating': rating,
      'photoUrl': photoUrl,
      'isBlocked': isBlocked,
      'askPrice': askPrice,
      'askSpecialist': askSpecialist,
      'askAppointmentTime': askAppointmentTime,
      'askAvailability': askAvailability,
      'askWorkTime': askWorkTime,
      'searchRadiusKm': searchRadiusKm,
    };
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      fullName: json['fullName'] as String?,
      address: json['address'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      rating: json['rating'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isBlocked: json['isBlocked'] as bool? ?? false,
      askPrice: json['askPrice'] as bool? ?? true,
      askSpecialist: json['askSpecialist'] as bool? ?? true,
      askAppointmentTime: json['askAppointmentTime'] as bool? ?? true,
      askAvailability: json['askAvailability'] as bool? ?? true,
      askWorkTime: json['askWorkTime'] as bool? ?? true,
      searchRadiusKm: json['searchRadiusKm'] as int? ?? 20,
    );
  }

  UserProfileModel copyWith({
    String? fullName,
    String? address,
    String? email,
    String? phone,
    String? rating,
    String? photoUrl,
    bool? isBlocked,
    bool? askPrice,
    bool? askSpecialist,
    bool? askAppointmentTime,
    bool? askAvailability,
    bool? askWorkTime,
    int? searchRadiusKm,
  }) {
    return UserProfileModel(
      fullName: fullName ?? this.fullName,
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      photoUrl: photoUrl ?? this.photoUrl,
      isBlocked: isBlocked ?? this.isBlocked,
      askPrice: askPrice ?? this.askPrice,
      askSpecialist: askSpecialist ?? this.askSpecialist,
      askAppointmentTime: askAppointmentTime ?? this.askAppointmentTime,
      askAvailability: askAvailability ?? this.askAvailability,
      askWorkTime: askWorkTime ?? this.askWorkTime,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
    );
  }
}
