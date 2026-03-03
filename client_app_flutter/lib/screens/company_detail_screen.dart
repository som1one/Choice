import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/remote_company_service.dart';
import '../services/remote_ordering_service.dart';
import '../services/remote_chat_service.dart';
import '../services/remote_review_service.dart';
import '../utils/auth_guard.dart';
import 'chats_screen.dart';

class CompanyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> company;
  final Map<String, dynamic> order;
  final int searchRadiusKm;

  const CompanyDetailScreen({
    super.key,
    required this.company,
    required this.order,
    this.searchRadiusKm = 20,
  });

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  final TextEditingController _clientResponseController = TextEditingController();
  DateTime? _selectedEnrollmentDate;
  String? _selectedEnrollmentTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _clientResponseController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    if (_selectedEnrollmentDate == null || _selectedEnrollmentTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату и время записи')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final orderId = widget.order['id'] ?? widget.order['orderId'];
      if (orderId != null) {
        // Подтверждаем запись
        final orderingService = RemoteOrderingService();
        await orderingService.confirmEnrollmentDate(orderId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Запись подтверждена')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startChat() async {
    final companyId = widget.company['guid'] ?? widget.company['id'];
    if (companyId == null) return;

    // Открываем чат с компанией
    // TODO: Реализовать открытие чата с конкретной компанией по ID
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.company;
    final order = widget.order;
    
    final companyName = company['title'] ?? company['name'] ?? 'Компания';
    // Адрес может быть объектом или строкой
    final addressObj = company['address'];
    final address = addressObj is Map
        ? '${addressObj['street'] ?? ''}, ${addressObj['city'] ?? ''}'
        : (addressObj?.toString() ?? company['street'] ?? '');
    final website = company['site_url'] ?? company['website'] ?? '';
    final email = company['email'] ?? '';
    final phone = company['phone_number'] ?? company['phone'] ?? '';
    final rating = (company['average_grade'] ?? company['rating'] as num?)?.toDouble() ?? 0.0;
    // Услуги нужно получать из API, пока используем пустой список
    final services = <String>[]; // TODO: Загрузить из /api/company-services
    
    final price = order['price'] ?? 0;
    final deadline = order['deadline'] ?? 0;
    final specialistName = order['specialist_name'] ?? '';
    final specialistPhone = order['specialist_phone'] ?? '';
    final enrollmentDate = order['enrollment_date'];
    final prepayment = order['prepayment'] ?? 0;
    final requiresPrepayment = prepayment > 0;

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
                  onPressed: () => AuthGuard.openClientCabinet(context),
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
            // Текст "Ответили в радиусе X км"
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Ответили в радиусе ${widget.searchRadiusKm} км',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Карточка компании (цвет из card_color)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _parseColor(company['card_color'] ?? '#2196F3'),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Левая колонка - информация о компании
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.directions_car, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              companyName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(address, style: const TextStyle(fontSize: 14)),
                        ],
                        if (website.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('www. $website', style: const TextStyle(fontSize: 14)),
                        ],
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Mail $email', style: const TextStyle(fontSize: 14)),
                        ],
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Тел горячей линии $phone', style: const TextStyle(fontSize: 14)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Рейтинг ', style: TextStyle(fontSize: 14)),
                            ...List.generate(5, (index) {
                              return Icon(
                                index < rating.round() ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showReviews,
                          child: Row(
                            children: [
                              const Icon(Icons.thumb_up, size: 16),
                              const SizedBox(width: 4),
                              const Text('Отзывы', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Правая колонка - услуги
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Услуги:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...services.take(5).map((service) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $service', style: const TextStyle(fontSize: 12)),
                        )),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.camera_alt, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Icon(Icons.camera_alt, color: Colors.pink, size: 20),
                            const SizedBox(width: 8),
                            Icon(Icons.send, color: Colors.blue, size: 20),
                          ],
                        ),
                        // Соцсети
                        if (_hasSocialNetworks(company)) ...[
                          const SizedBox(height: 12),
                          _buildSocialNetworks(company),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Ответ компании
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ОТВЕТ КОМПАНИИ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Цена $price', style: const TextStyle(fontSize: 14)),
                  Text('Срок $deadline ${_getDeadlineUnit(deadline)}', style: const TextStyle(fontSize: 14)),
                  if (specialistName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Имя специалиста $specialistName', style: const TextStyle(fontSize: 14)),
                  ],
                  if (specialistPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Телефон мастера $specialistPhone', style: const TextStyle(fontSize: 14)),
                  ],
                ],
              ),
            ),

            // Записаться
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Записаться на',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildEnrollmentDates(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Поле "ОТВЕТ" для пожеланий клиента
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ОТВЕТ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _clientResponseController,
                    decoration: const InputDecoration(
                      hintText: 'Напишите ваши пожелания к записи',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Рейтинг (неактивен до завершения диалога)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Поставить рейтинг',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        Icons.star_border,
                        color: Colors.grey,
                        size: 24,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '(Рейтинг можно поставить после завершения диалога)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Предоплата
            if (requiresPrepayment) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Предоплата обязательна',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Реализовать оплату предоплаты
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Оплата предоплаты')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Сделать предоплату',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Кнопка "Начать чат"
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Начать чат с компанией',
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

  void _selectEnrollmentDate(String dateTime) {
    setState(() {
      _selectedEnrollmentTime = dateTime;
    });
  }

  String _getDeadlineUnit(int deadline) {
    if (deadline < 24) return 'часов';
    if (deadline < 168) return 'дней';
    return 'недель';
  }

  Color _parseColor(String colorString) {
    try {
      // Убираем # если есть
      String hex = colorString.replaceAll('#', '');
      // Добавляем FF для альфа-канала если его нет
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.lightBlue[100]!;
    }
  }

  bool _hasSocialNetworks(Map<String, dynamic> company) {
    final socialMedias = company['social_medias'] ?? company['socialMedias'];
    if (socialMedias is List) {
      return socialMedias.isNotEmpty;
    }
    // Fallback для старых полей
    final vk = company['vk'] ?? company['vk_url'];
    final instagram = company['instagram'] ?? company['instagram_url'];
    final telegram = company['telegram'] ?? company['telegram_url'];
    return (vk != null && vk.toString().isNotEmpty) ||
           (instagram != null && instagram.toString().isNotEmpty) ||
           (telegram != null && telegram.toString().isNotEmpty);
  }

  Widget _buildSocialNetworks(Map<String, dynamic> company) {
    final socialMedias = company['social_medias'] ?? company['socialMedias'];
    List<String> socialUrls = [];
    
    if (socialMedias is List) {
      socialUrls = socialMedias.map((e) => e.toString()).where((url) => url.isNotEmpty).toList();
    } else {
      // Fallback для старых полей
      final vk = company['vk'] ?? company['vk_url'];
      final instagram = company['instagram'] ?? company['instagram_url'];
      final telegram = company['telegram'] ?? company['telegram_url'];
      if (vk != null && vk.toString().isNotEmpty) socialUrls.add(vk.toString());
      if (instagram != null && instagram.toString().isNotEmpty) socialUrls.add(instagram.toString());
      if (telegram != null && telegram.toString().isNotEmpty) socialUrls.add(telegram.toString());
    }

    return Wrap(
      spacing: 8,
      children: socialUrls.map((url) {
        // Определяем тип соцсети по URL
        String label = 'Соцсеть';
        Color bgColor = Colors.blue[400]!;
        if (url.toLowerCase().contains('vk.com') || url.toLowerCase().contains('vkontakte')) {
          label = 'VK';
          bgColor = Colors.blue[700]!;
        } else if (url.toLowerCase().contains('instagram.com')) {
          label = 'Instagram';
          bgColor = Colors.pink;
        } else if (url.toLowerCase().contains('t.me') || url.toLowerCase().contains('telegram')) {
          label = 'Telegram';
          bgColor = Colors.blue[400]!;
        }
        
        return GestureDetector(
          onTap: () => _launchUrl(url),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: label == 'Instagram' 
                ? null 
                : bgColor,
              gradient: label == 'Instagram'
                ? const LinearGradient(
                    colors: [Color(0xFFE1306C), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                  )
                : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showReviews() async {
    final companyId = widget.company['guid'] ?? widget.company['id'];
    if (companyId == null) return;

    try {
      // Используем правильный API для получения отзывов компании
      final reviewService = RemoteReviewService();
      final companyReviews = await reviewService.getReviews(companyId.toString());
      
      if (companyReviews == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось загрузить отзывы')),
          );
        }
        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Отзывы'),
          content: SizedBox(
            width: double.maxFinite,
            child: companyReviews.isEmpty
                ? const Text('Отзывов пока нет')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: companyReviews.length,
                  itemBuilder: (context, index) {
                    final review = companyReviews[index];
                    // В ответе бэкенда используется 'grade', а не 'rating'
                    final grade = (review['grade'] as num?)?.toInt() ?? 0;
                    final text = review['text'] ?? review['comment'] ?? '';
                    // sender_id - это ID клиента, который оставил отзыв
                    final senderId = review['sender_id'] ?? '';
                    final clientName = 'Клиент $senderId'; // TODO: Загрузить имя клиента

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clientName,
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки отзывов: $e')),
        );
      }
    }
  }

  Widget _buildEnrollmentDates() {
    // Пытаемся получить даты из заказа
    final enrollmentDateStr = widget.order['enrollment_date'];
    List<String> availableDates = [];
    
    if (enrollmentDateStr != null) {
      try {
        final date = DateTime.parse(enrollmentDateStr);
        // Генерируем несколько вариантов времени
        availableDates = [
          '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
        ];
      } catch (_) {
        // Если не удалось распарсить, используем дефолтные значения
        availableDates = ['22.11.2021 10-30', '22.11.2021 14-00'];
      }
    } else {
      // Дефолтные значения
      availableDates = ['22.11.2021 10-30', '22.11.2021 14-00'];
    }

    return Row(
      children: [
        ...availableDates.map((dateTime) {
          final isSelected = _selectedEnrollmentTime == dateTime;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _selectEnrollmentDate(dateTime),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
                  ),
                  child: Text(
                    dateTime,
                    style: TextStyle(
                      color: isSelected ? Colors.blue : Colors.black,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Подтвердить запись',
              style: TextStyle(fontSize: 12, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
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
