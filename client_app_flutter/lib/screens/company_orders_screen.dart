import 'package:flutter/material.dart';

import '../constants/categories.dart';
import '../services/auth_service.dart';
import '../services/remote_client_service.dart';
import '../services/remote_ordering_service.dart';
import '../utils/auth_guard.dart';
import '../utils/order_state.dart';
import '../widgets/choice_logo_icon.dart';
import '../widgets/profile_corner_icon.dart';
import 'company_client_detail_screen.dart';

class CompanyOrdersScreen extends StatefulWidget {
  const CompanyOrdersScreen({super.key});

  @override
  State<CompanyOrdersScreen> createState() => _CompanyOrdersScreenState();
}

class _CompanyOrdersScreenState extends State<CompanyOrdersScreen> {
  final RemoteOrderingService _orderingService = RemoteOrderingService();
  final RemoteClientService _clientService = RemoteClientService();

  List<_CompanyOrderListItem> _orders = [];
  bool _isLoading = true;
  bool _showOnlyActive = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawOrders = await _orderingService.getOrders() ?? [];
      final items = <_CompanyOrderListItem>[];

      for (final order in rawOrders) {
        final orderRequestId = _parseInt(
          order['order_request_id'] ?? order['orderRequestId'],
        );

        Map<String, dynamic>? request;
        if (orderRequestId != null) {
          request = await _clientService.getOrderRequest(orderRequestId);
        }

        Map<String, dynamic>? client;
        final clientGuid = _extractClientGuid(order, request);
        if (clientGuid != null && clientGuid.isNotEmpty) {
          client = await _clientService.getClientByGuid(clientGuid);
        }

        items.add(
          _CompanyOrderListItem(order: order, request: request, client: client),
        );
      }

      items.sort((a, b) {
        final aStatusPriority = _statusPriority(a.order);
        final bStatusPriority = _statusPriority(b.order);
        if (aStatusPriority != bStatusPriority) {
          return aStatusPriority.compareTo(bStatusPriority);
        }

        final aId = _parseInt(a.order['id'] ?? a.order['orderId']) ?? 0;
        final bId = _parseInt(b.order['id'] ?? b.order['orderId']) ?? 0;
        return bId.compareTo(aId);
      });

      if (!mounted) return;
      setState(() {
        _orders = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось загрузить заказы';
      });
    }
  }

  int _statusPriority(Map<String, dynamic> order) {
    if (isOrderConfirmed(order)) return 0;
    if (isOrderActive(order)) return 1;
    if (isOrderFinished(order)) return 2;
    if (isOrderCanceled(order)) return 3;
    return 4;
  }

  int? _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String? _extractClientGuid(
    Map<String, dynamic> order,
    Map<String, dynamic>? request,
  ) {
    final raw =
        order['client_guid'] ??
        order['clientGuid'] ??
        order['client_id'] ??
        order['clientId'] ??
        request?['client_guid'] ??
        request?['clientGuid'];
    final normalized = raw?.toString().trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  String _resolveClientName(_CompanyOrderListItem item) {
    final client = item.client;
    if (client != null) {
      final name = client['name']?.toString().trim() ?? '';
      final surname = client['surname']?.toString().trim() ?? '';
      final fullName = '$name $surname'.trim();
      if (fullName.isNotEmpty) return fullName;
    }
    return 'Клиент';
  }

  String _resolveRequestTitle(_CompanyOrderListItem item) {
    final description = item.request?['description']?.toString().trim();
    if (description != null && description.isNotEmpty) {
      return description;
    }

    final orderId = _parseInt(item.order['id'] ?? item.order['orderId']);
    return orderId == null ? 'Заказ' : 'Заказ #$orderId';
  }

  String _resolveCategoryTitle(_CompanyOrderListItem item) {
    final categoryId = _parseInt(
      item.request?['category_id'] ?? item.request?['categoryId'],
    );
    if (categoryId == null) return 'Категория не указана';
    return categoryIdToTitle(categoryId);
  }

  String _resolveStatusLabel(Map<String, dynamic> order) {
    if (isOrderFinished(order)) return 'Завершен';
    if (isOrderCanceled(order)) return 'Отменен';
    if (isOrderConfirmed(order)) return 'Подтвержден';
    return 'Ожидает подтверждения';
  }

  Color _resolveStatusColor(Map<String, dynamic> order) {
    if (isOrderFinished(order)) return Colors.blue;
    if (isOrderCanceled(order)) return Colors.red;
    if (isOrderConfirmed(order)) return Colors.green;
    return Colors.orange;
  }

  String _formatEnrollmentDate(Map<String, dynamic> order) {
    final raw = order['enrollment_date'] ?? order['enrollmentDate'];
    if (raw == null) return 'Дата не указана';
    try {
      final date = DateTime.parse(raw.toString());
      return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.toString();
    }
  }

  Widget _buildPersonIcon() {
    return const ProfileCornerIcon(userType: UserType.company, size: 30);
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrders = _showOnlyActive
        ? _orders.where((item) => isOrderActive(item.order)).toList()
        : _orders;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black, width: 3.0)),
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: ChoiceLogoIcon(size: 32),
            ),
            title: const Text(
              'Заказы',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${visibleOrders.length}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadOrders,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            )
          : visibleOrders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showOnlyActive
                        ? 'Нет активных заказов'
                        : 'У компании пока нет заказов',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadOrders,
                    child: const Text('Обновить'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Активные'),
                        selected: _showOnlyActive,
                        onSelected: (_) =>
                            setState(() => _showOnlyActive = true),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Все'),
                        selected: !_showOnlyActive,
                        onSelected: (_) =>
                            setState(() => _showOnlyActive = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...visibleOrders.map((item) {
                    final order = item.order;
                    final statusColor = _resolveStatusColor(order);
                    final statusLabel = _resolveStatusLabel(order);
                    final title = _resolveRequestTitle(item);
                    final category = _resolveCategoryTitle(item);
                    final clientName = _resolveClientName(item);
                    final appointmentDate = _formatEnrollmentDate(order);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.12),
                          child: Icon(
                            isOrderFinished(order)
                                ? Icons.task_alt
                                : isOrderCanceled(order)
                                ? Icons.cancel_outlined
                                : isOrderConfirmed(order)
                                ? Icons.event_available
                                : Icons.shopping_bag,
                            color: statusColor,
                          ),
                        ),
                        title: Text(
                          title.length > 65
                              ? '${title.substring(0, 65)}...'
                              : title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Категория: $category'),
                              Text('Клиент: $clientName'),
                              Text('Запись: $appointmentDate'),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CompanyClientDetailScreen(
                                order: Map<String, dynamic>.from(order),
                                client: item.client,
                              ),
                            ),
                          );
                          if (!mounted) return;
                          _loadOrders();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _CompanyOrderListItem {
  final Map<String, dynamic> order;
  final Map<String, dynamic>? request;
  final Map<String, dynamic>? client;

  const _CompanyOrderListItem({
    required this.order,
    required this.request,
    required this.client,
  });
}
