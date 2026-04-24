import 'package:flutter/material.dart';
import '../services/inquiry_service.dart';
import '../services/remote_inquiry_service.dart';
import '../services/remote_ordering_service.dart';
import '../models/inquiry_model.dart';
import '../models/order_request_model.dart';
import 'service_query_screen.dart';
import 'order_request_screen.dart';
import 'client_view_inquiry_screen.dart';
import '../constants/categories.dart';
import '../utils/order_state.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<InquiryModel> _orderRequests = [];
  Map<int, List<Map<String, dynamic>>> _ordersByRequestId = {};
  bool _isLoading = false;
  final RemoteOrderingService _orderingService = RemoteOrderingService();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await InquiryService.getAllInquiries();
      final companyResponses = await _orderingService.getOrders();
      final ordersByRequestId = <int, List<Map<String, dynamic>>>{};

      for (final order in companyResponses ?? const <Map<String, dynamic>>[]) {
        final rawRequestId =
            order['order_request_id'] ?? order['orderRequestId'];
        final requestId = rawRequestId is num
            ? rawRequestId.toInt()
            : int.tryParse(rawRequestId?.toString() ?? '');
        if (requestId == null) {
          continue;
        }
        ordersByRequestId.putIfAbsent(requestId, () => []).add(order);
      }

      if (mounted) {
        setState(() {
          _orderRequests = orders;
          _ordersByRequestId = ordersByRequestId;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки заказов: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadOrders();
  }

  int _getStatus(InquiryModel inquiry) {
    final requestId = int.tryParse(inquiry.id);
    final responses = requestId == null
        ? const <Map<String, dynamic>>[]
        : _ordersByRequestId[requestId] ?? const <Map<String, dynamic>>[];

    if (responses.any(isOrderFinished)) {
      return 4;
    }

    if (responses.any(isOrderConfirmed)) {
      return 3;
    }

    if (responses.any(isOrderActive)) {
      return 2;
    }

    if (responses.any(isOrderCanceled)) {
      return 5;
    }

    return responses.isEmpty ? 1 : 2;
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Ожидает';
      case 2:
        return 'Есть отклики';
      case 3:
        return 'Запись';
      case 4:
        return 'Завершен';
      case 5:
        return 'Отменен';
      default:
        return 'Ожидает';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return const Color(0xFF6DC876);
      case 2:
        return const Color(0xFFE09A2D);
      case 3:
        return const Color(0xFF2D81E0);
      case 4:
        return const Color(0xFF2D81E0);
      case 5:
        return const Color(0xFFDF5B5B);
      default:
        return const Color(0xFFAEAEB2);
    }
  }

  int _getResponseCount(InquiryModel inquiry) {
    final requestId = int.tryParse(inquiry.id);
    if (requestId == null) return 0;
    return _ordersByRequestId[requestId]?.length ?? 0;
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _isLoading && _orderRequests.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _orderRequests.isEmpty
            ? _buildEmptyState()
            : _buildOrdersList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Анимированная иконка
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.5 + (0.5 * value),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF87CEEB).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: Color(0xFF87CEEB),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Пока нет заказов',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Создайте свою первую заявку и получите предложения от компаний',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 50),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D81E0), Color(0xFF87CEEB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D81E0).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceQueryScreen(
                          category: kSystemCategories.isNotEmpty
                              ? kSystemCategories[0]
                              : 'Услуги',
                        ),
                      ),
                    ).then((_) => _loadOrders());
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 32,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Создать заказ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return Column(
      children: [
        // Заголовок с градиентом
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFF87CEEB).withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF87CEEB).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: Color(0xFF87CEEB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Мои заказы',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Управляйте своими заявками',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6D7885),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_orderRequests.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D81E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_orderRequests.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: _orderRequests.length,
            itemBuilder: (context, index) {
              final order = _orderRequests[index];
              return _buildOrderCard(order);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openOrderRequest(InquiryModel inquiry) async {
    if (!mounted) return;

    final status = _getStatus(inquiry);
    final hasResponses = _getResponseCount(inquiry) > 0;

    if (hasResponses || status >= 3) {
      await InquiryService.setCurrentInquiry(inquiry);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ClientViewInquiryScreen(),
        ),
      );
      if (!mounted) return;
      _loadOrders();
      return;
    }

    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final orderRequestId = int.tryParse(inquiry.id);

      if (orderRequestId == null) {
        if (mounted) {
          Navigator.pop(context); // Закрываем индикатор загрузки
          await InquiryService.setCurrentInquiry(inquiry);
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ServiceQueryScreen(category: inquiry.category),
            ),
          );
          _loadOrders();
        }
        return;
      }

      // Получаем полные данные заявки с бэкенда
      final remoteService = RemoteInquiryService();
      final orderData = await remoteService.getOrderRequest(orderRequestId);

      if (!mounted) return;
      Navigator.pop(context); // Закрываем индикатор загрузки

      if (orderData != null) {
        final orderRequest = OrderRequestModel.fromJson(orderData);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OrderRequestScreen(orderRequest: orderRequest),
          ),
        );
        // Обновляем список после возврата
        _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить заявку')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Закрываем индикатор загрузки
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildOrderCard(InquiryModel order) {
    final status = _getStatus(order);
    final statusColor = _getStatusColor(status);
    final responseCount = _getResponseCount(order);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openOrderRequest(order),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок с номером заказа и статусом
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getStatusIcon(status),
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Заказ №${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 12,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(order.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor,
                              statusColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Разделитель
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.grey[300]!,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Категория
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF87CEEB,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(order.category),
                              size: 14,
                              color: const Color(0xFF87CEEB),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              order.category,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF87CEEB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Описание заявки
                  Text(
                    order.question,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Индикатор ответов (если есть)
                  if (responseCount > 0)
                    Row(
                      children: [
                        Icon(
                          switch (status) {
                            3 => Icons.event_available,
                            4 => Icons.task_alt,
                            5 => Icons.cancel_outlined,
                            _ => Icons.mark_email_read,
                          },
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          switch (status) {
                            3 => 'Запись подтверждена',
                            4 => 'Заказ завершен',
                            5 => 'Заказ отменен',
                            _ => 'Откликов от компаний: $responseCount',
                          },
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.access_time;
      case 2:
        return Icons.mark_email_read;
      case 3:
        return Icons.event_available;
      case 4:
        return Icons.task_alt;
      case 5:
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getCategoryIcon(String category) {
    // Иконки для разных категорий
    if (category.toLowerCase().contains('авто') ||
        category.toLowerCase().contains('машина')) {
      return Icons.directions_car;
    } else if (category.toLowerCase().contains('ремонт')) {
      return Icons.build;
    } else if (category.toLowerCase().contains('красота') ||
        category.toLowerCase().contains('салон')) {
      return Icons.face;
    } else if (category.toLowerCase().contains('здоров') ||
        category.toLowerCase().contains('медиц')) {
      return Icons.local_hospital;
    } else if (category.toLowerCase().contains('образован')) {
      return Icons.school;
    } else {
      return Icons.category;
    }
  }
}
