import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/remote_client_service.dart';
import '../services/remote_review_service.dart';
import '../services/remote_ordering_service.dart';
import '../services/api_config.dart';
import '../utils/auth_guard.dart';
import 'chat_screen.dart';

class CompanyClientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic>? client;

  const CompanyClientDetailScreen({
    super.key,
    required this.order,
    this.client,
  });

  @override
  State<CompanyClientDetailScreen> createState() =>
      _CompanyClientDetailScreenState();
}

class _CompanyClientDetailScreenState extends State<CompanyClientDetailScreen> {
  final TextEditingController _responseController = TextEditingController();
  final RemoteOrderingService _orderingService = RemoteOrderingService();
  bool _isFinishingOrder = false;
  bool _isSubmittingReview = false;
  bool _canLeaveReview = false;
  Map<String, dynamic>? _clientData;
  List<Map<String, dynamic>> _clientReviews = [];
  double _clientRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadClientData();
    _loadClientReviews();
    _checkCanLeaveReview();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  String? _resolveClientId([Map<String, dynamic>? source]) {
    final localGuid = _clientData?['guid']?.toString().trim();
    if (localGuid != null && localGuid.isNotEmpty) {
      return localGuid;
    }

    final data = source ?? widget.order;
    final id =
        data['client_guid'] ??
        data['clientGuid'] ??
        data['client_id'] ??
        data['clientId'];
    final normalized = id?.toString().trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  String? _resolveClientIconUri() {
    final icon = _clientData?['icon_uri'] ?? _clientData?['iconUri'];
    if (icon == null) return null;
    final raw = icon.toString();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    return '${ApiConfig.fileBaseUrl}/api/objects/$raw';
  }

  Future<void> _loadClientData() async {
    final clientId = _resolveClientId();
    if (clientId == null) return;

    try {
      // Используем новый API для получения клиента по GUID
      final clientService = RemoteClientService();
      final client = await clientService.getClientByGuid(clientId.toString());

      if (client != null) {
        setState(() {
          _clientData = client;
        });
        await _loadClientReviews();
        await _checkCanLeaveReview();
      } else if (widget.client != null) {
        // Если API не вернул данные, используем переданные данные
        setState(() {
          _clientData = widget.client;
        });
        await _loadClientReviews();
        await _checkCanLeaveReview();
      }
    } catch (e) {
      // Если ошибка, используем переданные данные
      if (widget.client != null) {
        setState(() {
          _clientData = widget.client;
        });
        await _loadClientReviews();
        await _checkCanLeaveReview();
      }
    }
  }

  Future<void> _loadClientReviews() async {
    final clientId = _resolveClientId();
    if (clientId == null) return;

    try {
      // Используем правильный API для получения отзывов о клиенте
      final reviewService = RemoteReviewService();
      final clientReviews = await reviewService.getClientReviews(
        clientId.toString(),
      );

      if (clientReviews == null) return;

      // Вычисляем средний рейтинг
      double totalRating = 0.0;
      int count = 0;
      for (final review in clientReviews) {
        final gradeRaw = review['grade'];
        final grade = gradeRaw is num
            ? gradeRaw.toDouble()
            : double.tryParse(gradeRaw?.toString() ?? '');
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

  Future<void> _checkCanLeaveReview() async {
    final clientId = _resolveClientId();
    if (clientId == null) return;

    try {
      final reviewService = RemoteReviewService();
      final canLeave = await reviewService.canSendReview(clientId.toString());
      if (!mounted) return;
      setState(() {
        _canLeaveReview = canLeave;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _canLeaveReview = false;
      });
    }
  }

  Future<void> _sendClientReview({required int grade, String? text}) async {
    final clientId = _resolveClientId();
    if (clientId == null || _isSubmittingReview) return;

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      final reviewService = RemoteReviewService();
      final result = await reviewService.sendReview(
        guid: clientId.toString(),
        grade: grade,
        text: text,
      );

      if (!mounted) return;
      if (result != null && result['error'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отзыв о клиенте успешно отправлен')),
        );
        await _loadClientReviews();
        await _checkCanLeaveReview();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result?['error']?.toString() ?? 'Невозможно оставить отзыв',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ошибка отправки отзыва')));
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
          title: const Text('Оценить клиента'),
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
                  hintText: 'Текст отзыва (необязательно)',
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
              onPressed: _isSubmittingReview
                  ? null
                  : () {
                      Navigator.pop(context);
                      _sendClientReview(
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

  Future<void> _contactClient() async {
    final clientId = _resolveClientId();
    if (clientId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось определить клиента для чата')),
      );
      return;
    }

    final clientName =
        _clientData?['name'] ??
        (_clientData?['surname'] != null && _clientData?['name'] != null
            ? '${_clientData!['name']} ${_clientData!['surname']}'
            : null) ??
        widget.order['client_name'] ??
        'Клиент';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          userId: clientId,
          userName: clientName.toString(),
          userIconUri: _resolveClientIconUri(),
        ),
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

  Future<void> _finishOrder() async {
    if (_isFinishingOrder) return;
    final orderIdRaw = widget.order['id'] ?? widget.order['orderId'];
    final orderId = orderIdRaw is num
        ? orderIdRaw.toInt()
        : int.tryParse(orderIdRaw?.toString() ?? '');
    if (orderId == null) {
      if (!mounted) return;
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
          'После завершения заказа обе стороны смогут оставить отзыв.',
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
        widget.order['status'] = result['status'] ?? 2;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ завершен')),
        );
        await _checkCanLeaveReview();
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось завершить заказ')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка завершения: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isFinishingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final enrollmentDate = order['enrollment_date'];
    final isDateConfirmed = order['is_date_confirmed'] ?? false;
    final isEnrolled = order['is_enrolled'] ?? false;
    final status = order['status'] ?? 1;
    final isFinished = status == 2;
    final prepayment = order['prepayment'] ?? 0;
    final hasPrepayment = prepayment > 0;

    // Парсим дату записи
    String enrollmentDateStr = '';
    if (enrollmentDate != null) {
      try {
        final date = DateTime.parse(enrollmentDate.toString());
        enrollmentDateStr =
            '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        enrollmentDateStr = enrollmentDate.toString();
      }
    }

    // Имя клиента может быть в разных полях
    final clientName =
        _clientData?['name'] ??
        _clientData?['full_name'] ??
        (_clientData?['surname'] != null && _clientData?['name'] != null
            ? '${_clientData!['name']} ${_clientData!['surname']}'
            : null) ??
        order['client_name'] ??
        'Клиент';
    final clientPhone =
        _clientData?['phone_number'] ??
        _clientData?['phone'] ??
        order['client_phone'] ??
        '';

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
                        const Text(
                          'Телефон клиента ',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          clientPhone,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                      const Text(
                        'Рейтинг клиента ',
                        style: TextStyle(fontSize: 14),
                      ),
                      ...List.generate(5, (index) {
                        return Icon(
                          index < _clientRating.round()
                              ? Icons.star
                              : Icons.star_border,
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
                              Text(
                                '${_clientReviews.length}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_canLeaveReview) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: _isSubmittingReview
                          ? null
                          : _showLeaveReviewDialog,
                      icon: _isSubmittingReview
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.star, size: 18),
                      label: const Text('Оценить клиента'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Информация о записи
                  Text(
                    'Клиент записался ${hasPrepayment ? 'с предоплатой' : 'без предоплаты'} на $enrollmentDateStr',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (clientName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Имя клиента $clientName',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  if (clientPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Телефон клиента $clientPhone',
                      style: const TextStyle(fontSize: 14),
                    ),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        color: (isFinished ? Colors.blue : Colors.green)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isFinished ? Colors.blue : Colors.green,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isFinished ? Icons.task_alt : Icons.check_circle,
                            color: isFinished ? Colors.blue : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isFinished
                                ? 'Заказ завершен'
                                : 'Запись подтверждена',
                            style: TextStyle(
                              color: isFinished ? Colors.blue : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isFinished) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isFinishingOrder ? null : _finishOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            _isFinishingOrder
                                ? 'Завершение...'
                                : 'Завершить заказ',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
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
                    final gradeRaw = review['grade'];
                    final grade = gradeRaw is num
                        ? gradeRaw.toInt()
                        : int.tryParse(gradeRaw?.toString() ?? '') ?? 0;
                    final text = review['text'] ?? review['comment'] ?? '';
                    final senderId = review['sender_id'] ?? '';
                    final companyName = _formatReviewerLabel(
                      prefix: 'Компания',
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
                              companyName,
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
  }

  Widget _buildPersonIcon() {
    return CustomPaint(size: const Size(24, 24), painter: _PersonIconPainter());
  }

  String _formatReviewerLabel({required String prefix, required Object? rawId}) {
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
