import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_config.dart';
import '../services/remote_chat_service.dart';
import '../services/remote_ordering_service.dart';
import '../services/remote_review_service.dart';
import '../utils/auth_guard.dart';
import '../utils/order_state.dart';
import 'chat_screen.dart';
import '../services/auth_service.dart';
import '../widgets/choice_logo_icon.dart';
import '../widgets/profile_corner_icon.dart';

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
  final TextEditingController _clientResponseController =
      TextEditingController();
  final RemoteOrderingService _orderingService = RemoteOrderingService();
  final RemoteReviewService _reviewService = RemoteReviewService();
  String? _selectedEnrollmentTime;
  bool _isLoading = false;
  bool _isFinishingOrder = false;
  bool _isSubmittingReview = false;
  bool _canLeaveReview = false;
  final RemoteChatService _chatService = RemoteChatService();

  @override
  void initState() {
    super.initState();
    final availableDates = _extractAvailableEnrollmentDates();
    if (availableDates.isNotEmpty) {
      _selectedEnrollmentTime = availableDates.first;
    }
    _checkCanLeaveReview();
  }

  @override
  void dispose() {
    _clientResponseController.dispose();
    super.dispose();
  }

  String? _resolveCompanyId() {
    final companyId = widget.company['guid'] ?? widget.company['id'];
    final value = companyId?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> _checkCanLeaveReview() async {
    final companyId = _resolveCompanyId();
    if (companyId == null) return;

    final canLeave = await _reviewService.canSendReview(companyId);
    if (!mounted) return;
    setState(() {
      _canLeaveReview = canLeave;
    });
  }

  Future<void> _confirmBooking() async {
    if (isOrderFinished(widget.order)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заказ уже завершен')));
      return;
    }
    if (isOrderCanceled(widget.order)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заказ отменен и не может быть подтвержден'),
        ),
      );
      return;
    }
    if (isOrderConfirmed(widget.order)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Запись уже подтверждена')));
      return;
    }

    final orderId = _resolveOrderId();
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось определить заказ')),
      );
      return;
    }

    final hasSelectableDates = _extractAvailableEnrollmentDates().isNotEmpty;
    if (hasSelectableDates && _selectedEnrollmentTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату и время записи')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _orderingService.confirmEnrollmentDate(orderId);

      final clientComment = _clientResponseController.text.trim();
      final companyId = widget.company['guid'] ?? widget.company['id'];
      if (clientComment.isNotEmpty && companyId != null) {
        await _chatService.sendMessage(
          text: clientComment,
          receiverId: companyId.toString(),
        );
      }

      if (result != null) {
        widget.order['status'] = parseOrderStatus(result);
        widget.order['is_date_confirmed'] =
            result['is_date_confirmed'] ?? result['isDateConfirmed'] ?? true;
        widget.order['is_enrolled'] =
            result['is_enrolled'] ?? result['isEnrolled'] ?? true;
        if (result['enrollment_date'] != null) {
          widget.order['enrollment_date'] = result['enrollment_date'];
        }
      } else {
        widget.order['is_date_confirmed'] = true;
        widget.order['is_enrolled'] = true;
      }

      if (mounted) {
        await _checkCanLeaveReview();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              clientComment.isEmpty
                  ? 'Запись подтверждена'
                  : 'Запись подтверждена, пожелание отправлено в чат',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _finishOrder() async {
    if (_isFinishingOrder) return;
    if (isOrderFinished(widget.order)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заказ уже завершен')));
      return;
    }
    if (isOrderCanceled(widget.order)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отмененный заказ нельзя завершить')),
      );
      return;
    }
    if (!canFinishOrder(widget.order)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала подтвердите запись по заказу')),
      );
      return;
    }

    final orderId = _resolveOrderId();
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось определить заказ')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить заказ'),
        content: const Text(
          'После завершения заказа можно будет оставить отзыв компании.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isFinishingOrder = true;
    });

    try {
      final result = await _orderingService.finish(orderId);
      if (!mounted) return;
      if (result != null) {
        widget.order['status'] = parseOrderStatus(result);
        widget.order['is_date_confirmed'] =
            result['is_date_confirmed'] ??
            result['isDateConfirmed'] ??
            widget.order['is_date_confirmed'];
        widget.order['is_enrolled'] =
            result['is_enrolled'] ??
            result['isEnrolled'] ??
            widget.order['is_enrolled'];
        await _checkCanLeaveReview();
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Заказ завершен')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось завершить заказ: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isFinishingOrder = false;
        });
      }
    }
  }

  Future<void> _sendCompanyReview({required int grade, String? text}) async {
    final companyId = _resolveCompanyId();
    if (companyId == null || _isSubmittingReview) return;

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      final result = await _reviewService.sendReview(
        guid: companyId,
        grade: grade,
        text: text,
      );
      if (!mounted) return;
      if (result != null && result['error'] == null) {
        await _checkCanLeaveReview();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отзыв о компании отправлен')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result?['error']?.toString() ?? 'Не удалось отправить отзыв',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReview = false;
        });
      }
    }
  }

  void _showLeaveReviewDialog() {
    int grade = 5;
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Оценить компанию'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Оценка: $grade'),
              Slider(
                value: grade.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: grade.toString(),
                onChanged: (value) {
                  setDialogState(() {
                    grade = value.toInt();
                  });
                },
              ),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Комментарий к отзыву',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _sendCompanyReview(
                  grade: grade,
                  text: textController.text.trim().isEmpty
                      ? null
                      : textController.text.trim(),
                );
              },
              child: const Text('Отправить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startChat() async {
    final companyId = widget.company['guid'] ?? widget.company['id'];
    if (companyId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          userId: companyId.toString(),
          userName:
              (widget.company['title'] ?? widget.company['name'] ?? 'Компания')
                  .toString(),
          userIconUri: _resolveCompanyIconUri(),
        ),
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
    final ratingRaw =
        company['average_grade'] ??
        company['averageGrade'] ??
        company['rating'];
    final rating = ratingRaw is num
        ? ratingRaw.toDouble()
        : double.tryParse(ratingRaw?.toString() ?? '') ?? 0.0;
    final services = _extractServices(company);

    final price = order['price'] ?? 0;
    final deadline = order['deadline'] ?? 0;
    final responseText = (order['response_text'] ?? order['responseText'] ?? '')
        .toString();
    final specialistName =
        (order['specialist_name'] ?? order['specialistName'] ?? '').toString();
    final specialistPhone =
        (order['specialist_phone'] ?? order['specialistPhone'] ?? '')
            .toString();
    final prepayment = order['prepayment'] ?? 0;
    final requiresPrepayment = prepayment > 0;
    final isFinished = isOrderFinished(order);
    final isCanceled = isOrderCanceled(order);
    final isConfirmed = isOrderConfirmed(order);

    return Scaffold(
      bottomNavigationBar: _buildBottomActionBar(),
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
                            Icon(
                              Icons.directions_car,
                              color: Colors.red,
                              size: 20,
                            ),
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
                          Text(
                            'www. $website',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Mail $email',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Тел горячей линии $phone',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'Рейтинг ',
                              style: TextStyle(fontSize: 14),
                            ),
                            ...List.generate(5, (index) {
                              return Icon(
                                index < rating.round()
                                    ? Icons.star
                                    : Icons.star_border,
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
                              const Text(
                                'Отзывы',
                                style: TextStyle(fontSize: 14),
                              ),
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
                        if (services.isNotEmpty) ...[
                          const Text(
                            'Услуги:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...services
                              .take(5)
                              .map(
                                (service) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• $service',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                          const SizedBox(height: 12),
                        ],
                        // Соцсети
                        if (_hasSocialNetworks(company)) ...[
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('Цена $price', style: const TextStyle(fontSize: 14)),
                  Text(
                    'Срок $deadline ${_getDeadlineUnit(deadline)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (responseText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(responseText, style: const TextStyle(fontSize: 14)),
                  ],
                  if (specialistName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Имя специалиста $specialistName',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  if (specialistPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Телефон мастера $specialistPhone',
                      style: const TextStyle(fontSize: 14),
                    ),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

            // Завершение работы и отзыв
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Завершение и отзыв',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  if (isCanceled)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: const Text(
                        'Заказ отменен. Для новой записи выберите другой отклик.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else if (isConfirmed && !isFinished)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: const Text(
                        'Заказ подтвержден. Завершить его можно кнопкой внизу экрана.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else if (!isConfirmed)
                    const Text(
                      'Кнопка завершения появится после подтверждения записи.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Text(
                        'Заказ завершен. Можно оставить отзыв компании.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (isFinished) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _canLeaveReview && !_isSubmittingReview
                            ? _showLeaveReviewDialog
                            : null,
                        icon: _isSubmittingReview
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.star_outline),
                        label: Text(
                          _canLeaveReview
                              ? 'Поставить отзыв'
                              : 'Отзыв уже оставлен',
                        ),
                      ),
                    ),
                  ],
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
                    Text(
                      'Предоплата обязательна',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Сумма предоплаты: $prepayment. Оплата внутри приложения пока не подключена, сумму нужно согласовать с компанией в чате.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
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
    );
  }

  String? _resolveCompanyIconUri() {
    final iconUri = widget.company['icon_uri'] ?? widget.company['iconUri'];
    if (iconUri == null) return null;
    final raw = iconUri.toString().trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    return '${ApiConfig.fileBaseUrl}/api/objects/$raw';
  }

  List<String> _extractServices(Map<String, dynamic> company) {
    final rawList =
        company['services'] ??
        company['company_services'] ??
        company['companyServices'];
    if (rawList is List) {
      return rawList
          .map((item) {
            if (item is Map<String, dynamic>) {
              return (item['title'] ?? item['name'] ?? '').toString().trim();
            }
            return item.toString().trim();
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final activities = company['activities']?.toString().trim();
    if (activities != null && activities.isNotEmpty) {
      return activities
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const <String>[];
  }

  int? _resolveOrderId() {
    final rawOrderId = widget.order['id'] ?? widget.order['orderId'];
    if (rawOrderId is num) {
      return rawOrderId.toInt();
    }
    return int.tryParse(rawOrderId?.toString() ?? '');
  }

  Widget? _buildBottomActionBar() {
    if (!canFinishOrder(widget.order)) {
      return null;
    }

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isFinishingOrder ? null : _finishOrder,
          icon: _isFinishingOrder
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.task_alt, color: Colors.white),
          label: Text(
            _isFinishingOrder ? 'Завершение...' : 'Завершить заказ',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D81E0),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  List<String> _extractAvailableEnrollmentDates() {
    final enrollmentDateStr =
        widget.order['enrollment_date'] ?? widget.order['enrollmentDate'];
    if (enrollmentDateStr == null) {
      return const <String>[];
    }

    try {
      final date = DateTime.parse(enrollmentDateStr.toString());
      return <String>[
        '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
      ];
    } catch (_) {
      return const <String>[];
    }
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
      socialUrls = socialMedias
          .map((e) => e.toString())
          .where((url) => url.isNotEmpty)
          .toList();
    } else {
      // Fallback для старых полей
      final vk = company['vk'] ?? company['vk_url'];
      final instagram = company['instagram'] ?? company['instagram_url'];
      final telegram = company['telegram'] ?? company['telegram_url'];
      if (vk != null && vk.toString().isNotEmpty) socialUrls.add(vk.toString());
      if (instagram != null && instagram.toString().isNotEmpty)
        socialUrls.add(instagram.toString());
      if (telegram != null && telegram.toString().isNotEmpty)
        socialUrls.add(telegram.toString());
    }

    return Wrap(
      spacing: 8,
      children: socialUrls.map((url) {
        final social = _describeSocialUrl(url);
        return GestureDetector(
          onTap: () => _launchUrl(url),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: social.gradient == null ? social.color : null,
              gradient: social.gradient,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              social.label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        );
      }).toList(),
    );
  }

  ({String label, Color color, Gradient? gradient}) _describeSocialUrl(
    String url,
  ) {
    final lower = url.toLowerCase();
    if (lower.contains('vk.com') || lower.contains('vkontakte')) {
      return (label: 'VK', color: Colors.blue[700]!, gradient: null);
    }
    if (lower.contains('instagram.com') || lower.contains('instagr.am')) {
      return (
        label: 'Instagram',
        color: Colors.transparent,
        gradient: const LinearGradient(
          colors: [Color(0xFFE1306C), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
        ),
      );
    }
    if (lower.contains('t.me') || lower.contains('telegram')) {
      return (label: 'Telegram', color: Colors.blue[400]!, gradient: null);
    }
    if (lower.contains('wa.me') ||
        lower.contains('whatsapp.com') ||
        lower.contains('whatsapp')) {
      return (label: 'WhatsApp', color: Colors.green, gradient: null);
    }
    if (lower.contains('ok.ru') || lower.contains('odnoklassniki')) {
      return (label: 'OK', color: Colors.orange, gradient: null);
    }
    if (lower.contains('facebook.com') || lower.contains('fb.com')) {
      return (label: 'Facebook', color: Colors.blue, gradient: null);
    }
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return (label: 'YouTube', color: Colors.red, gradient: null);
    }
    return (label: 'Соцсеть', color: Colors.blue[400]!, gradient: null);
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
      final companyReviews = await reviewService.getReviews(
        companyId.toString(),
      );

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
                      final gradeRaw = review['grade'];
                      final grade = gradeRaw is num
                          ? gradeRaw.toInt()
                          : int.tryParse(gradeRaw?.toString() ?? '') ?? 0;
                      final text = review['text'] ?? review['comment'] ?? '';
                      final senderId = review['sender_id'] ?? '';
                      final clientName = _formatReviewerLabel(
                        prefix: 'Клиент',
                        rawId: senderId,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки отзывов: $e')));
      }
    }
  }

  Widget _buildEnrollmentDates() {
    final availableDates = _extractAvailableEnrollmentDates();
    final isFinished = isOrderFinished(widget.order);
    final isCanceled = isOrderCanceled(widget.order);
    final isConfirmed = isOrderConfirmed(widget.order);

    if (isCanceled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Этот заказ отменен. Подтверждение записи недоступно.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (isFinished) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue),
        ),
        child: const Row(
          children: [
            Icon(Icons.task_alt, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Заказ уже завершен.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (isConfirmed) {
      return Container(
        width: double.infinity,
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
            Expanded(
              child: Text(
                'Запись уже подтверждена. Детали можно уточнить в чате.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (availableDates.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text(
              'Компания еще не предложила дату записи. Можно принять отклик и договориться о времени в чате.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || !canConfirmOrder(widget.order)
                  ? null
                  : _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Принять отклик',
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      );
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
                    color: isSelected
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.transparent,
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
        }),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading || !canConfirmOrder(widget.order)
                ? null
                : _confirmBooking,
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
    return const ProfileCornerIcon(userType: UserType.client, size: 28);
  }

  String _formatReviewerLabel({
    required String prefix,
    required Object? rawId,
  }) {
    final normalized = rawId?.toString().trim() ?? '';
    if (normalized.isEmpty) return prefix;
    if (normalized.length <= 8) return '$prefix $normalized';
    return '$prefix ${normalized.substring(0, 8)}';
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
