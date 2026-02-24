class InquiryModel {
  final String id;
  final String question;
  final String category;
  final String clientName;
  final DateTime createdAt;
  final bool wantsPrice;
  final bool wantsTime;
  final bool wantsSpecialist;
  final bool wantsAppointmentTime;
  final String? attachmentUrl;
  
  // Ответ компании
  final String? companyResponse;
  final String? companyName;
  final String? price;
  final String? time;
  final String? specialistName;
  final String? specialistPhone;
  final String? appointmentDate;
  final String? appointmentTime;
  final bool? appointmentConfirmed;
  final double? companyLatitude;
  final double? companyLongitude;
  
  // Ответ клиента
  final String? clientResponse;
  final String? clientNameForAppointment;
  final String? clientPhoneForAppointment;
  final bool? clientConfirmedAppointment;
  
  // Финальный ответ компании
  final String? finalCompanyResponse;
  final bool? appointmentFinalConfirmed;

  InquiryModel({
    required this.id,
    required this.question,
    required this.category,
    required this.clientName,
    required this.createdAt,
    this.wantsPrice = false,
    this.wantsTime = false,
    this.wantsSpecialist = false,
    this.wantsAppointmentTime = false,
    this.attachmentUrl,
    this.companyResponse,
    this.companyName,
    this.price,
    this.time,
    this.specialistName,
    this.specialistPhone,
    this.appointmentDate,
    this.appointmentTime,
    this.appointmentConfirmed,
    this.companyLatitude,
    this.companyLongitude,
    this.clientResponse,
    this.clientNameForAppointment,
    this.clientPhoneForAppointment,
    this.clientConfirmedAppointment,
    this.finalCompanyResponse,
    this.appointmentFinalConfirmed,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'category': category,
      'clientName': clientName,
      'createdAt': createdAt.toIso8601String(),
      'wantsPrice': wantsPrice,
      'wantsTime': wantsTime,
      'wantsSpecialist': wantsSpecialist,
      'wantsAppointmentTime': wantsAppointmentTime,
      'attachmentUrl': attachmentUrl,
      'companyResponse': companyResponse,
      'companyName': companyName,
      'price': price,
      'time': time,
      'specialistName': specialistName,
      'specialistPhone': specialistPhone,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
      'appointmentConfirmed': appointmentConfirmed,
      'companyLatitude': companyLatitude,
      'companyLongitude': companyLongitude,
      'clientResponse': clientResponse,
      'clientNameForAppointment': clientNameForAppointment,
      'clientPhoneForAppointment': clientPhoneForAppointment,
      'clientConfirmedAppointment': clientConfirmedAppointment,
      'finalCompanyResponse': finalCompanyResponse,
      'appointmentFinalConfirmed': appointmentFinalConfirmed,
    };
  }

  factory InquiryModel.fromJson(Map<String, dynamic> json) {
    return InquiryModel(
      id: json['id'] as String,
      question: json['question'] as String,
      category: json['category'] as String,
      clientName: json['clientName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      wantsPrice: json['wantsPrice'] as bool? ?? false,
      wantsTime: json['wantsTime'] as bool? ?? false,
      wantsSpecialist: json['wantsSpecialist'] as bool? ?? false,
      wantsAppointmentTime: json['wantsAppointmentTime'] as bool? ?? false,
      attachmentUrl: json['attachmentUrl'] as String?,
      companyResponse: json['companyResponse'] as String?,
      companyName: json['companyName'] as String?,
      price: json['price'] as String?,
      time: json['time'] as String?,
      specialistName: json['specialistName'] as String?,
      specialistPhone: json['specialistPhone'] as String?,
      appointmentDate: json['appointmentDate'] as String?,
      appointmentTime: json['appointmentTime'] as String?,
      appointmentConfirmed: json['appointmentConfirmed'] as bool?,
      companyLatitude: json['companyLatitude'] != null ? (json['companyLatitude'] as num).toDouble() : null,
      companyLongitude: json['companyLongitude'] != null ? (json['companyLongitude'] as num).toDouble() : null,
      clientResponse: json['clientResponse'] as String?,
      clientNameForAppointment: json['clientNameForAppointment'] as String?,
      clientPhoneForAppointment: json['clientPhoneForAppointment'] as String?,
      clientConfirmedAppointment: json['clientConfirmedAppointment'] as bool?,
      finalCompanyResponse: json['finalCompanyResponse'] as String?,
      appointmentFinalConfirmed: json['appointmentFinalConfirmed'] as bool?,
    );
  }

  InquiryModel copyWith({
    String? id,
    String? question,
    String? category,
    String? clientName,
    DateTime? createdAt,
    bool? wantsPrice,
    bool? wantsTime,
    bool? wantsSpecialist,
    bool? wantsAppointmentTime,
    String? attachmentUrl,
    String? companyResponse,
    String? companyName,
    String? price,
    String? time,
    String? specialistName,
    String? specialistPhone,
    String? appointmentDate,
    String? appointmentTime,
    bool? appointmentConfirmed,
    double? companyLatitude,
    double? companyLongitude,
    String? clientResponse,
    String? clientNameForAppointment,
    String? clientPhoneForAppointment,
    bool? clientConfirmedAppointment,
    String? finalCompanyResponse,
    bool? appointmentFinalConfirmed,
  }) {
    return InquiryModel(
      id: id ?? this.id,
      question: question ?? this.question,
      category: category ?? this.category,
      clientName: clientName ?? this.clientName,
      createdAt: createdAt ?? this.createdAt,
      wantsPrice: wantsPrice ?? this.wantsPrice,
      wantsTime: wantsTime ?? this.wantsTime,
      wantsSpecialist: wantsSpecialist ?? this.wantsSpecialist,
      wantsAppointmentTime: wantsAppointmentTime ?? this.wantsAppointmentTime,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      companyResponse: companyResponse ?? this.companyResponse,
      companyName: companyName ?? this.companyName,
      price: price ?? this.price,
      time: time ?? this.time,
      specialistName: specialistName ?? this.specialistName,
      specialistPhone: specialistPhone ?? this.specialistPhone,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      appointmentConfirmed: appointmentConfirmed ?? this.appointmentConfirmed,
      companyLatitude: companyLatitude ?? this.companyLatitude,
      companyLongitude: companyLongitude ?? this.companyLongitude,
      clientResponse: clientResponse ?? this.clientResponse,
      clientNameForAppointment: clientNameForAppointment ?? this.clientNameForAppointment,
      clientPhoneForAppointment: clientPhoneForAppointment ?? this.clientPhoneForAppointment,
      clientConfirmedAppointment: clientConfirmedAppointment ?? this.clientConfirmedAppointment,
      finalCompanyResponse: finalCompanyResponse ?? this.finalCompanyResponse,
      appointmentFinalConfirmed: appointmentFinalConfirmed ?? this.appointmentFinalConfirmed,
    );
  }
}
