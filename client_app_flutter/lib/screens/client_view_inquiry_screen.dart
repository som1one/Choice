import 'package:flutter/material.dart';
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import 'client_admin_cabinet_screen.dart';

class ClientViewInquiryScreen extends StatefulWidget {
  const ClientViewInquiryScreen({super.key});

  @override
  State<ClientViewInquiryScreen> createState() => _ClientViewInquiryScreenState();
}

class _ClientViewInquiryScreenState extends State<ClientViewInquiryScreen> {
  InquiryModel? _inquiry;
  bool _isLoading = true;

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
                      MaterialPageRoute(
                        builder: (context) => ClientAdminCabinetScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Фоновая карта
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/images/world_map.jpg'),
                fit: BoxFit.cover,
                opacity: 0.25,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'выбор клиента - ${_inquiry!.category}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  if (_inquiry!.attachmentUrl != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('клиент прикрепил фото', style: TextStyle(fontSize: 15)),
                        const SizedBox(width: 8),
                        const Icon(Icons.attach_file, color: Colors.blue),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('рейтинг клиента', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 12),
                      const Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 28),
                          Icon(Icons.star, color: Colors.amber, size: 28),
                          Icon(Icons.star_border, color: Colors.amber, size: 28),
                          Icon(Icons.star_border, color: Colors.amber, size: 28),
                          Icon(Icons.star_border, color: Colors.amber, size: 28),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Вопрос клиента
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Вопрос от клиента:',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _inquiry!.question,
                          style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (_inquiry!.wantsPrice)
                    _buildRequestRow('Клиент хочет узнать стоимость'),
                  if (_inquiry!.wantsTime)
                    _buildRequestRow('Клиент хочет узнать время выполнения работ'),
                  if (_inquiry!.wantsSpecialist)
                    _buildRequestRow('Клиент хочет узнать имя специалиста'),
                  if (_inquiry!.wantsAppointmentTime)
                    _buildRequestRow('Клиент хочет узнать время записи'),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Text('Фото', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      const Icon(Icons.attach_file, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Ответ голосом', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      const Icon(Icons.mic, color: Colors.grey),
                    ],
                  ),

                  // Показываем статус запроса
                  if (_inquiry!.companyResponse != null) ...[
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Статус:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('Ваш запрос отправлен. Ожидайте ответа от компании.'),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Статус:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('Ваш запрос отправлен. Ожидайте ответа от компании.'),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, color: Colors.blue, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          const Text('__________', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
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
