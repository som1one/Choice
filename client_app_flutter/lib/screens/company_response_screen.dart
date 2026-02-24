// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import 'company_inquiries_screen.dart';
import 'company_settings_screen.dart';

class CompanyResponseScreen extends StatefulWidget {
  const CompanyResponseScreen({super.key});

  @override
  State<CompanyResponseScreen> createState() => _CompanyResponseScreenState();
}

class _CompanyResponseScreenState extends State<CompanyResponseScreen> {
  InquiryModel? _inquiry;
  bool _isLoading = true;
  
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _specialistNameController = TextEditingController();
  final TextEditingController _specialistPhoneController = TextEditingController();
  final TextEditingController _appointmentDateController = TextEditingController();
  final TextEditingController _appointmentTimeController = TextEditingController();
  final TextEditingController _responseController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _prepaymentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInquiry();
  }


  Future<void> _loadInquiry() async {
    final inquiry = await InquiryService.getCurrentInquiry();
    setState(() {
      _inquiry = inquiry;
      _isLoading = false;
    });
  }

  Future<void> _saveResponse() async {
    if (_inquiry == null) return;

    final prefs = await SharedPreferences.getInstance();
    final companySettingsRaw = prefs.getString('company_settings');
    String companyName = 'Компания';
    if (companySettingsRaw != null) {
      try {
        final data = jsonDecode(companySettingsRaw) as Map<String, dynamic>;
        final configured = (data['f_Название'] as String?)?.trim();
        if (configured != null && configured.isNotEmpty) {
          companyName = configured;
        }
      } catch (_) {}
    }

    final computedCoords = _computeStableCoordinates(_inquiry!.id);

    final updatedInquiry = _inquiry!.copyWith(
      companyResponse: _responseController.text.isNotEmpty ? _responseController.text : null,
      companyName: companyName,
      price: _priceController.text.isNotEmpty ? _priceController.text : null,
      time: _timeController.text.isNotEmpty ? _timeController.text : null,
      specialistName: _specialistNameController.text.isNotEmpty ? _specialistNameController.text : null,
      specialistPhone: _specialistPhoneController.text.isNotEmpty ? _specialistPhoneController.text : null,
      appointmentDate: _appointmentDateController.text.isNotEmpty ? _appointmentDateController.text : null,
      appointmentTime: _appointmentTimeController.text.isNotEmpty ? _appointmentTimeController.text : null,
      companyLatitude: _inquiry!.companyLatitude ?? computedCoords.$1,
      companyLongitude: _inquiry!.companyLongitude ?? computedCoords.$2,
    );

    await InquiryService.updateCurrentInquiry(updatedInquiry);
    
    setState(() {
      _inquiry = updatedInquiry;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ответ сохранен')),
    );
  }

  Future<void> _confirmAppointment() async {
    if (_inquiry == null) return;

    final updatedInquiry = _inquiry!.copyWith(
      appointmentConfirmed: true,
    );

    await InquiryService.updateCurrentInquiry(updatedInquiry);
    
    setState(() {
      _inquiry = updatedInquiry;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Запись подтверждена')),
    );
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CompanyInquiriesScreen()),
      (route) => false,
    );
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
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_inquiry == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Ошибка')),
        body: Center(child: Text('Запрос не найден')),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black,
                width: 2.5,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Icon(
                Icons.favorite,
                color: Colors.lightBlue[300],
                size: 28,
              ),
            ),
            title: const Text(
              'Омск',
              style: TextStyle(
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CompanySettingsScreen()),
                    );
                  },
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
                        const Icon(Icons.local_car_wash, color: Colors.red, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Реактор 157 a',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('www. Reaktor.ru'),
                    const Text('Mail reak@bk.ru'),
                    const Text('Тел городей линии 88000000'),
                    const SizedBox(height: 8),
                    const Text('Рейтинг'),
                    const Icon(Icons.star, color: Colors.amber, size: 24),
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
                const Text(
                  'Записаться на',
                  style: TextStyle(fontSize: 16),
                ),
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
                  onPressed: _confirmAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Подтвердить запись'),
                ),
              ],

              const Divider(height: 32),

              const Text(
                'ОТВЕТ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _responseController,
                decoration: InputDecoration(
                  hintText: 'Построить рейтинг',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _prepaymentController,
                decoration: InputDecoration(
                  hintText: 'Предоплата обязательна',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(5, (index) => const Icon(Icons.star_border, color: Colors.grey)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _saveResponse();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ответ отправлен, возвращаемся к заявкам')),
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const CompanyInquiriesScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Отправить ответ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonIcon() {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _PersonIconPainter(),
    );
  }

  (double, double) _computeStableCoordinates(String seed) {
    const centerLat = 54.9885;
    const centerLon = 73.3686;
    final hash = seed.codeUnits.fold<int>(0, (acc, v) => (acc * 31 + v) & 0x7fffffff);
    final latShift = ((hash % 2001) - 1000) / 10000.0;
    final lonShift = ((((hash ~/ 2001) % 2001) - 1000)) / 10000.0;
    return (centerLat + latShift, centerLon + lonShift);
  }
}

class _PersonIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final headRadius = size.width * 0.25;
    canvas.drawCircle(
      Offset(size.width / 2, headRadius),
      headRadius,
      paint,
    );

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
