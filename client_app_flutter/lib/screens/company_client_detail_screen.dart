import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/remote_client_service.dart';
import '../services/remote_ordering_service.dart';
import '../services/remote_chat_service.dart';
import '../services/remote_review_service.dart';
import '../utils/auth_guard.dart';
import 'chats_screen.dart';

class CompanyClientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic>? client;

  const CompanyClientDetailScreen({
    super.key,
    required this.order,
    this.client,
  });

  @override
  State<CompanyClientDetailScreen> createState() => _CompanyClientDetailScreenState();
}

class _CompanyClientDetailScreenState extends State<CompanyClientDetailScreen> {
  final TextEditingController _responseController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _clientData;
  List<Map<String, dynamic>> _clientReviews = [];
  double _clientRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadClientData();
    _loadClientReviews();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _loadClientData() async {
    final clientId = widget.order['client_id'] ?? widget.order['clientId'];
    if (clientId == null) return;

    try {
      // Используем новый API для получения клиента по GUID
      final clientService = RemoteClientService();
      final client = await clientService.getClientByGuid(clientId.toString());
      
      if (client != null) {
        setState(() {
          _clientData = client;
        });
      } else if (widget.client != null) {
        // Если API не вернул данные, используем переданные данные
        setState(() {
          _clientData = widget.client;
        });
      }
    } catch (e) {
      // Если ошибка, используем переданные данные
      if (widget.client != null) {
        setState(() {
          _clientData = widget.client;
        });
      }
    }
  }

  Future<void> _loadClientReviews() async {
    final clientId = widget.order['client_id'] ?? widget.order['clientId'];
    if (clientId == null) return;

    try {
      // Используем правильный API для получения отзывов о клиенте
      final reviewService = RemoteReviewService();
      final clientReviews = await reviewService.getClientReviews(clientId.toString());
      
      if (clientReviews == null) return;

      // Вычисляем средний рейтинг
      double totalRating = 0.0;
      int count = 0;
      for (final review in clientReviews) {
        // В ответе бэкенда используется 'grade', а не 'rating'
        final grade = (review['grade'] as num?)?.toDouble();
        if (grade != null) {
          totalRating += grade;
          count++;
        }
      }
      final avgRating = count > 0 ? totalRating / count : 0.0;

      setState(() {
        _clientReviews = clientReviews;
        _clientRating = avgRating;
      });
    } catch (e) {
      // Игнорируем ошибки загрузки отзывов
    }
  }

  Future<void> _contactClient() async {
    final clientId = widget.order['client_id'] ?? widget.order['clientId'];
    if (clientId == null) return;

    // Открываем чат с клиентом
    // TODO: Реализовать открытие чата с конкретным клиентом по ID
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatsScreen(),
      ),
    );
  }

  Future<void> _callClient() async {
    final phone = _clientData?['phone'] ?? _clientData?['phone_number'];
    if (phone == null) return;

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final clientId = order['client_id'] ?? order['clientId'];
    final enrollmentDate = order['enrollment_date'];
    final isDateConfirmed = order['is_date_confirmed'] ?? false;
    final isEnrolled = order['is_enrolled'] ?? false;
    final prepayment = order['prepayment'] ?? 0;
    final hasPrepayment = prepayment > 0;

    // Парсим дату записи
    String enrollmentDateStr = '';
    if (enrollmentDate != null) {
      try {
        final date = DateTime.parse(enrollmentDate.toString());
        enrollmentDateStr = '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        enrollmentDateStr = enrollmentDate.toString();
      }
    }

    // Имя клиента может быть в разных полях
    final clientName = _clientData?['name'] ?? 
                      _clientData?['full_name'] ?? 
                      (_clientData?['surname'] != null && _clientData?['name'] != null
                        ? '${_clientData!['name']} ${_clientData!['surname']}'
                        : null) ??
                      order['client_name'] ?? 
                      'Клиент';
    final clientPhone = _clientData?['phone_number'] ?? 
                       _clientData?['phone'] ?? 
                       order['client_phone'] ?? 
                       '';

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
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ОМСК',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.black),
              ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о клиенте (голубая карточка)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.lightBlue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        clientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (clientPhone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Телефон клиента ', style: TextStyle(fontSize: 14)),
                        Text(clientPhone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.phone, size: 18),
                          onPressed: _callClient,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Рейтинг клиента ', style: TextStyle(fontSize: 14)),
                      ...List.generate(5, (index) {
                        return Icon(
                          index < _clientRating.round() ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                      if (_clientReviews.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showClientReviews,
                          child: Row(
                            children: [
                              const Icon(Icons.thumb_up, size: 16),
                              const SizedBox(width: 4),
                              Text('${_clientReviews.length}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ОТВЕТ КЛИЕНТА
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ОТВЕТ КЛИЕНТА',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Информация о записи
                  Text(
                    'Клиент записался ${hasPrepayment ? 'с предоплатой' : 'без предоплаты'} на $enrollmentDateStr',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (clientName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Имя клиента $clientName', style: const TextStyle(fontSize: 14)),
                  ],
                  if (clientPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Телефон клиента $clientPhone', style: const TextStyle(fontSize: 14)),
                  ],
                ],
              ),
            ),

            // ОТВЕТИТЬ КЛИЕНТУ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ОТВЕТИТЬ КЛИЕНТУ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _responseController,
                    decoration: const InputDecoration(
                      hintText: 'Напишите ответ клиенту',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Подтверждение записи
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Подтвердите запись',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  if (isDateConfirmed || isEnrolled) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Запись подтверждена',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Ожидается подтверждение от клиента',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Кнопка "Связаться с клиентом"
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _contactClient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Связаться с клиентом',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80), // Отступ для FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Реализовать редактирование
        },
        backgroundColor: Colors.purple[200],
        child: Icon(Icons.edit, color: Colors.purple[800]),
      ),
    );
  }

  void _showClientReviews() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отзывы о клиенте'),
        content: SizedBox(
          width: double.maxFinite,
          child: _clientReviews.isEmpty
              ? const Text('Отзывов пока нет')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _clientReviews.length,
                  itemBuilder: (context, index) {
                    final review = _clientReviews[index];
                    // В ответе бэкенда используется 'grade', а не 'rating'
                    final grade = (review['grade'] as num?)?.toInt() ?? 0;
                    final text = review['text'] ?? review['comment'] ?? '';
                    // sender_id - это ID компании, которая оставила отзыв
                    final senderId = review['sender_id'] ?? '';
                    final companyName = 'Компания $senderId'; // TODO: Загрузить название компании

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              companyName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < grade ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                            ),
                            if (text.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(text),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
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
