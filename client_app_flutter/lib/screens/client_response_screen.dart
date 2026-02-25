// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import 'map_search_screen.dart';
import '../utils/auth_guard.dart';

class ClientResponseScreen extends StatefulWidget {
  const ClientResponseScreen({super.key});

  @override
  State<ClientResponseScreen> createState() => _ClientResponseScreenState();
}

class _ClientResponseScreenState extends State<ClientResponseScreen> {
  InquiryModel? _inquiry;
  bool _isLoading = true;
  
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _finalResponseController = TextEditingController();

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

  Future<void> _saveClientResponse() async {
    if (_inquiry == null) return;

    final updatedInquiry = _inquiry!.copyWith(
      clientResponse: 'Клиент записался без предоплаты на ${_inquiry!.appointmentDate ?? ""} ${_inquiry!.appointmentTime ?? ""}',
      clientNameForAppointment: _clientNameController.text.isNotEmpty ? _clientNameController.text : null,
      clientPhoneForAppointment: _clientPhoneController.text.isNotEmpty ? _clientPhoneController.text : null,
      clientConfirmedAppointment: true,
    );

    await InquiryService.updateCurrentInquiry(updatedInquiry);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ответ сохранен')),
    );
    
    setState(() {
      _inquiry = updatedInquiry;
    });
  }

  Future<void> _saveFinalResponse() async {
    if (_inquiry == null) return;

    final updatedInquiry = _inquiry!.copyWith(
      finalCompanyResponse: _finalResponseController.text.isNotEmpty ? _finalResponseController.text : 'Запись подтверждена',
      appointmentFinalConfirmed: true,
    );

    await InquiryService.updateCurrentInquiry(updatedInquiry);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Финальный ответ сохранен')),
    );
    
    setState(() {
      _inquiry = updatedInquiry;
    });
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _finalResponseController.dispose();
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
                  onPressed: () => AuthGuard.openClientCabinet(context),
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
                        Text(
                          _inquiry!.companyName ?? 'Реактор 157 a',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        const SizedBox(width: 16),
                        const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Ответ компании
              if (_inquiry!.companyResponse != null || _inquiry!.price != null) ...[
                const Text(
                  'ОТВЕТ КОМПАНИИ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_inquiry!.price != null)
                  Text('Цена: ${_inquiry!.price}'),
                if (_inquiry!.time != null) ...[
                  const SizedBox(height: 8),
                  Text('Срок: ${_inquiry!.time}'),
                ],
                if (_inquiry!.specialistName != null) ...[
                  const SizedBox(height: 8),
                  Text('Имя специалиста: ${_inquiry!.specialistName}'),
                ],
                if (_inquiry!.specialistPhone != null) ...[
                  const SizedBox(height: 8),
                  Text('Телефон мастера: ${_inquiry!.specialistPhone}'),
                ],
                if (_inquiry!.appointmentDate != null && _inquiry!.appointmentTime != null) ...[
                  const SizedBox(height: 8),
                  Text('Запись на: ${_inquiry!.appointmentDate} ${_inquiry!.appointmentTime}'),
                ],
                if (_inquiry!.companyResponse != null) ...[
                  const SizedBox(height: 8),
                  Text(_inquiry!.companyResponse!),
                ],
                const SizedBox(height: 24),
              ],

              // Ответ клиента
              if (_inquiry!.clientResponse != null) ...[
                const Text(
                  'ОТВЕТ КЛИЕНТА',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_inquiry!.clientResponse!),
                const SizedBox(height: 16),
                if (_inquiry!.clientNameForAppointment != null)
                  Text('Имя клиента: ${_inquiry!.clientNameForAppointment}'),
                if (_inquiry!.clientPhoneForAppointment != null) ...[
                  const SizedBox(height: 8),
                  Text('Телефон клиента: ${_inquiry!.clientPhoneForAppointment}'),
                ],
                const Divider(height: 32),
              ],

              // Форма для ответа клиента (если еще не ответил)
              if (_inquiry!.clientResponse == null && _inquiry!.appointmentConfirmed == true) ...[
                const Text(
                  'ОТВЕТИТЬ КОМПАНИИ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _clientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя клиента',
                    hintText: 'Иван Игорь',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _clientPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Телефон клиента',
                    hintText: '89009009000',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveClientResponse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Подтвердить запись'),
                ),
                const Divider(height: 32),
              ],

              // Финальный ответ компании
              if (_inquiry!.clientConfirmedAppointment == true && _inquiry!.finalCompanyResponse == null) ...[
                const Text(
                  'ОТВЕТИТЬ КЛИЕНТУ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Подтвердите запись',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _finalResponseController,
                  decoration: const InputDecoration(
                    hintText: 'Введите ответ',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveFinalResponse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Подтвердить'),
                ),
                const Divider(height: 32),
              ],

              // Финальный ответ
              if (_inquiry!.finalCompanyResponse != null) ...[
                const Text(
                  'ОТВЕТ КОМПАНИИ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(_inquiry!.finalCompanyResponse!),
                const Divider(height: 32),
              ],

              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Связь с клиентом')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Связаться с клиентом'),
              ),
              const SizedBox(height: 16),
              // Кнопка для просмотра компании на карте
              if (_inquiry!.companyLatitude != null && _inquiry!.companyLongitude != null)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MapSearchScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Посмотреть на карте'),
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
