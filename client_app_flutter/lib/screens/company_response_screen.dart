// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import 'company_inquiries_screen.dart';
import '../utils/auth_guard.dart';
import '../services/auth_service.dart';
import '../services/remote_company_service.dart';
import '../services/remote_ordering_service.dart';
import '../widgets/choice_logo_icon.dart';
import '../widgets/profile_corner_icon.dart';

class CompanyResponseScreen extends StatefulWidget {
  const CompanyResponseScreen({super.key});

  @override
  State<CompanyResponseScreen> createState() => _CompanyResponseScreenState();
}

class _CompanyResponseScreenState extends State<CompanyResponseScreen> {
  InquiryModel? _inquiry;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _city; // Загружается из API
  final RemoteCompanyService _companyService = RemoteCompanyService();
  final RemoteOrderingService _orderingService = RemoteOrderingService();
  Map<String, dynamic>? _companyProfile;
  Map<String, dynamic>? _existingOrder;

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _specialistNameController =
      TextEditingController();
  final TextEditingController _specialistPhoneController =
      TextEditingController();
  final TextEditingController _appointmentDateController =
      TextEditingController();
  final TextEditingController _appointmentTimeController =
      TextEditingController();
  final TextEditingController _responseController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _prepaymentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCompanyProfile();
    await _loadInquiry();
  }

  Future<void> _loadCompanyProfile() async {
    final userType = await AuthService.getUserType();
    if (userType == UserType.company) {
      try {
        final companyProfile = await _companyService.getCompanyProfile();
        if (companyProfile != null && mounted) {
          _companyProfile = companyProfile;
          final address = companyProfile['address'];
          String? city;
          if (address is Map<String, dynamic>) {
            city = address['city']?.toString();
          } else {
            city = companyProfile['city']?.toString();
          }
          if (city != null && city.isNotEmpty) {
            setState(() {
              _city = city;
            });
          }
        }
      } catch (e) {
        // Ошибка загрузки города
      }
    }
  }

  Future<void> _loadInquiry() async {
    final inquiry = await InquiryService.getCurrentInquiry();
    if (inquiry == null) {
      setState(() {
        _inquiry = null;
        _isLoading = false;
      });
      return;
    }

    InquiryModel hydratedInquiry = inquiry;
    final orderRequestId = int.tryParse(inquiry.id);
    if (orderRequestId != null) {
      final orders = await _orderingService.getOrders(orderRequestId: orderRequestId);
      if (orders != null && orders.isNotEmpty) {
        final existingOrder = orders.first;
        _existingOrder = existingOrder;
        hydratedInquiry = inquiry.copyWith(
          companyResponse: (existingOrder['response_text'] ??
                  existingOrder['responseText'] ??
                  inquiry.companyResponse)
              ?.toString(),
          price: (existingOrder['price'] ?? inquiry.price)?.toString(),
          prepayment:
              (existingOrder['prepayment'] ?? inquiry.prepayment)?.toString(),
          time: (existingOrder['deadline'] ?? inquiry.time)?.toString(),
          specialistName:
              (existingOrder['specialist_name'] ??
                      existingOrder['specialistName'] ??
                      inquiry.specialistName)
                  ?.toString(),
          specialistPhone:
              (existingOrder['specialist_phone'] ??
                      existingOrder['specialistPhone'] ??
                      inquiry.specialistPhone)
                  ?.toString(),
          appointmentDate: _formatOrderDate(
            existingOrder['enrollment_date'] ?? existingOrder['enrollmentDate'],
            inquiry.appointmentDate,
          ),
          appointmentTime: _formatOrderTime(
            existingOrder['enrollment_date'] ?? existingOrder['enrollmentDate'],
            inquiry.appointmentTime,
          ),
        );
      }
    }

    _fillControllers(hydratedInquiry);

    setState(() {
      _inquiry = hydratedInquiry;
      _isLoading = false;
    });
  }

  void _fillControllers(InquiryModel inquiry) {
    _responseController.text = inquiry.companyResponse ?? '';
    _priceController.text = inquiry.price ?? '';
    _prepaymentController.text = inquiry.prepayment ?? '';
    _timeController.text = inquiry.time ?? '';
    _specialistNameController.text = inquiry.specialistName ?? '';
    _specialistPhoneController.text = inquiry.specialistPhone ?? '';
    _appointmentDateController.text = inquiry.appointmentDate ?? '';
    _appointmentTimeController.text = inquiry.appointmentTime ?? '';
  }

  Future<void> _saveResponse({bool closeAfterSave = false}) async {
    if (_inquiry == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final companyName =
        (_companyProfile?['title'] ?? _inquiry!.companyName ?? 'Компания')
            .toString();

    final updatedInquiry = _inquiry!.copyWith(
      companyResponse: _responseController.text.isNotEmpty
          ? _responseController.text
          : null,
      companyName: companyName,
      price: _priceController.text.isNotEmpty ? _priceController.text : null,
      prepayment: _prepaymentController.text.isNotEmpty
          ? _prepaymentController.text
          : null,
      time: _timeController.text.isNotEmpty ? _timeController.text : null,
      specialistName: _specialistNameController.text.isNotEmpty
          ? _specialistNameController.text
          : null,
      specialistPhone: _specialistPhoneController.text.isNotEmpty
          ? _specialistPhoneController.text
          : null,
      appointmentDate: _appointmentDateController.text.isNotEmpty
          ? _appointmentDateController.text
          : null,
      appointmentTime: _appointmentTimeController.text.isNotEmpty
          ? _appointmentTimeController.text
          : null,
      // Координаты компании больше не вычисляем из ID.
      // Здесь должны использоваться только реальные координаты, если они когда-либо будут заданы.
      companyLatitude: _inquiry!.companyLatitude,
      companyLongitude: _inquiry!.companyLongitude,
    );

    try {
      await InquiryService.updateCurrentInquiry(updatedInquiry);

      setState(() {
        _inquiry = updatedInquiry;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ответ сохранен и отправлен')));
      if (closeAfterSave) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CompanyInquiriesScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при отправке ответа: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _confirmAppointment() async {
    await _saveResponse();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _timeController.dispose();
    _specialistNameController.dispose();
    _specialistPhoneController.dispose();
    _appointmentDateController.dispose();
    _appointmentTimeController.dispose();
    _responseController.dispose();
    _ratingController.dispose();
    _prepaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_inquiry == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Ошибка')),
        body: Center(child: Text('Запрос не найден')),
      );
    }

    final companyName =
        (_companyProfile?['title'] ?? _inquiry!.companyName ?? 'Компания')
            .toString();
    final website =
        (_companyProfile?['site_url'] ?? _companyProfile?['siteUrl'] ?? '')
            .toString();
    final email = (_companyProfile?['email'] ?? '').toString();
    final phone =
        (_companyProfile?['phone_number'] ?? _companyProfile?['phone'] ?? '')
            .toString();
    final companyRatingRaw =
        _companyProfile?['average_grade'] ?? _companyProfile?['averageGrade'];
    final companyRating = companyRatingRaw is num
        ? companyRatingRaw.toDouble()
        : double.tryParse(companyRatingRaw?.toString() ?? '') ?? 0.0;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black, width: 2.5)),
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: const ChoiceLogoIcon(size: 30),
            ),
            title: Text(
              _city ?? 'Загрузка...',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: _buildPersonIcon(),
                  onPressed: () => AuthGuard.openCompanySettings(context),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Карточка компании
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_car_wash,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          companyName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (website.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('www. $website'),
                    ],
                    if (email.isNotEmpty) Text('Mail $email'),
                    if (phone.isNotEmpty) Text('Тел горячей линии $phone'),
                    const SizedBox(height: 8),
                    const Text('Рейтинг'),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < companyRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.thumb_up, color: Colors.blue),
                        const SizedBox(width: 16),
                        const Icon(Icons.camera_alt, color: Colors.grey),
                        const SizedBox(width: 16),
                        const Icon(Icons.share, color: Colors.pink),
                        const SizedBox(width: 16),
                        const Icon(Icons.message, color: Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'ОТВЕТ КОМПАНИИ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_inquiry!.wantsPrice) ...[
                TextField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Цена',
                    hintText: _inquiry!.price ?? 'Введите цену',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (_inquiry!.wantsTime) ...[
                TextField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: 'Срок',
                    hintText: _inquiry!.time ?? 'Введите срок',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (_inquiry!.wantsSpecialist) ...[
                TextField(
                  controller: _specialistNameController,
                  decoration: InputDecoration(
                    labelText: 'Имя специалиста',
                    hintText: _inquiry!.specialistName ?? 'Введите имя',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _specialistPhoneController,
                  decoration: InputDecoration(
                    labelText: 'Телефон мастера',
                    hintText: _inquiry!.specialistPhone ?? 'Введите телефон',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              if (_inquiry!.wantsAppointmentTime) ...[
                const Divider(height: 32),
                const Text('Записаться на', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _appointmentDateController,
                  decoration: InputDecoration(
                    labelText: 'Дата',
                    hintText: _inquiry!.appointmentDate ?? '22.11.2021',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _appointmentTimeController,
                  decoration: InputDecoration(
                    labelText: 'Время',
                    hintText: _inquiry!.appointmentTime ?? '10:30',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _confirmAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Сохранить дату записи'),
                ),
              ],

              const Divider(height: 32),

                const Text(
                  'Комментарий компании',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _responseController,
                  decoration: InputDecoration(
                  hintText: 'Добавьте комментарий для клиента',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _prepaymentController,
                decoration: InputDecoration(
                  labelText: 'Предоплата',
                  hintText: _inquiry!.prepayment ?? 'Например: 500',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _saveResponse(closeAfterSave: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _existingOrder == null ? 'Отправить ответ' : 'Обновить ответ',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonIcon() {
    return const ProfileCornerIcon(userType: UserType.company, size: 28);
  }

  String? _formatOrderDate(dynamic rawDate, String? fallback) {
    if (rawDate == null) return fallback;
    try {
      final date = DateTime.parse(rawDate.toString());
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return fallback;
    }
  }

  String? _formatOrderTime(dynamic rawDate, String? fallback) {
    if (rawDate == null) return fallback;
    try {
      final date = DateTime.parse(rawDate.toString());
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fallback;
    }
  }
}

class _PersonIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final headRadius = size.width * 0.25;
    canvas.drawCircle(Offset(size.width / 2, headRadius), headRadius, paint);

    final bodyWidth = size.width * 0.7;
    final bodyHeight = size.height * 0.5;
    final bodyTop = headRadius * 2.1;
    final bodyLeft = (size.width - bodyWidth) / 2;
    final bodyBottom = bodyTop + bodyHeight;
    final indentWidth = bodyWidth * 0.25;
    final indentDepth = bodyHeight * 0.15;

    final path = Path()
      ..moveTo(bodyLeft, bodyTop)
      ..lineTo(bodyLeft + bodyWidth, bodyTop)
      ..lineTo(bodyLeft + bodyWidth, bodyBottom - indentDepth)
      ..lineTo(bodyLeft + bodyWidth - indentWidth, bodyBottom - indentDepth)
      ..lineTo(bodyLeft + bodyWidth - indentWidth, bodyBottom)
      ..lineTo(bodyLeft + indentWidth, bodyBottom)
      ..lineTo(bodyLeft + indentWidth, bodyBottom - indentDepth)
      ..lineTo(bodyLeft, bodyBottom - indentDepth)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
