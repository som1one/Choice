import 'package:flutter/material.dart';
import '../services/inquiry_service.dart';
import '../services/remote_inquiry_service.dart';
import '../models/inquiry_model.dart';
import '../models/order_request_model.dart';
import 'service_query_screen.dart';
import 'order_request_screen.dart';
import '../constants/categories.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<InquiryModel> _orderRequests = [];
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await InquiryService.getAllInquiries();
      if (mounted) {
        setState(() {
          _orderRequests = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadOrders();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Активен';
      case 2:
        return 'Завершен';
      default:
        return 'Отменен';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return const Color(0xFF6DC876);
      case 2:
        return const Color(0xFF2D81E0);
      default:
        return const Color(0xFFAEAEB2);
    }
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
            const Icon(
              Icons.sentiment_dissatisfied,
              size: 60,
              color: Color(0xFF3F8AE0),
            ),
            const SizedBox(height: 30),
            const Text(
              'Пока нет заказов',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Давайте исправим это',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF818C99),
              ),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceQueryScreen(
                        category: kSystemCategories.isNotEmpty ? kSystemCategories[0] : 'Услуги',
                      ),
                    ),
                  ).then((_) => _loadOrders());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D81E0),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Создать заказ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
        const Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: Text(
            'Заказы',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 20),
            itemCount: _orderRequests.length,
            itemBuilder: (context, index) {
              final order = _orderRequests[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: _buildOrderCard(order),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openOrderRequest(InquiryModel inquiry) async {
    // Получаем полные данные заявки с бэкенда
    final remoteService = RemoteInquiryService();
    final orderData = await remoteService.getOrderRequest(int.tryParse(inquiry.id) ?? 0);
    
    if (orderData != null && mounted) {
      final orderRequest = OrderRequestModel.fromJson(orderData);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderRequestScreen(orderRequest: orderRequest),
        ),
      ).then((_) => _loadOrders()); // Обновляем список после возврата
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить заявку')),
      );
    }
  }

  Widget _buildOrderCard(InquiryModel order) {
    // Определяем статус (по умолчанию активен, если нет ответа компании)
    final status = order.companyResponse == null ? 1 : 2;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: () => _openOrderRequest(order),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Заказ №${order.id}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(order.createdAt),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6D7885),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                order.category,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                order.question,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
