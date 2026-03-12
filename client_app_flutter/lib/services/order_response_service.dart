import '../models/inquiry_model.dart';
import 'remote_ordering_service.dart';
import 'remote_company_service.dart';
import '../constants/categories.dart';

/// Модель ответа компании на заявку
class CompanyOrderResponse {
  final Map<String, dynamic> order;
  final Map<String, dynamic> company;

  CompanyOrderResponse({
    required this.order,
    required this.company,
  });

  String get companyName => company['title'] ?? company['name'] ?? 'Компания';
  double get rating => (company['average_grade'] ?? company['rating'] as num?)?.toDouble() ?? 0.0;
  int get price => order['price'] ?? 0;
  int get deadline => order['deadline'] ?? 0;
  String? get companyId => (order['company_id'] ?? order['companyId'])?.toString();
}

/// Сервис для работы с ответами компаний на заявки
class OrderResponseService {
  final RemoteOrderingService _orderingService = RemoteOrderingService();
  final RemoteCompanyService _companyService = RemoteCompanyService();

  /// Получить ответы компаний на заявку
  /// 
  /// [inquiry] - заявка клиента
  /// Возвращает список ответов компаний или пустой список при ошибке
  Future<List<CompanyOrderResponse>> getCompanyResponses(InquiryModel inquiry) async {
    if (inquiry.id.isEmpty) {
      return [];
    }

    try {
      // Получаем ID заявки
      final orderRequestId = int.tryParse(inquiry.id);
      if (orderRequestId == null) {
        return [];
      }

      // Получаем заказы (ответы компаний) по ID заявки
      final orders = await _orderingService.getOrders(orderRequestId: orderRequestId);
      if (orders == null || orders.isEmpty) {
        return [];
      }

      // Получаем категорию заявки для оптимизации запросов
      final categoryId = categoryTitleToId(inquiry.category);
      
      // Загружаем компании батчами для оптимизации
      final responses = await _loadCompaniesForOrders(orders, categoryId);
      
      return responses;
    } catch (e) {
      print('Error loading company responses: $e');
      return [];
    }
  }

  /// Загружает информацию о компаниях для заказов
  /// 
  /// Оптимизирует запросы, сначала пытаясь получить компании по категории,
  /// затем загружая недостающие по отдельности
  Future<List<CompanyOrderResponse>> _loadCompaniesForOrders(
    List<Map<String, dynamic>> orders,
    int categoryId,
  ) async {
    if (orders.isEmpty) {
      return [];
    }

    // Собираем уникальные ID компаний
    final companyIds = orders
        .map((order) => (order['company_id'] ?? order['companyId'])?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (companyIds.isEmpty) {
      return [];
    }

    // Создаем Map для быстрого поиска компаний
    final companiesMap = <String, Map<String, dynamic>>{};

    // Пытаемся получить компании по категории (оптимизация)
    if (categoryId > 0) {
      try {
        final companiesByCategory = await _companyService.getCompaniesByCategory(categoryId);
        if (companiesByCategory != null) {
          for (final company in companiesByCategory) {
            final guid = (company['guid'] ?? company['id'] ?? '').toString();
            if (guid.isNotEmpty && companyIds.contains(guid)) {
              companiesMap[guid] = company;
            }
          }
        }
      } catch (e) {
        print('Error loading companies by category: $e');
      }
    }

    // Загружаем недостающие компании по отдельности
    final missingCompanyIds = companyIds.where((id) => !companiesMap.containsKey(id)).toList();
    
    if (missingCompanyIds.isNotEmpty) {
      await Future.wait(
        missingCompanyIds.map((companyId) async {
          try {
            final company = await _companyService.getCompany(companyId);
            if (company != null) {
              companiesMap[companyId] = company;
            }
          } catch (e) {
            print('Error loading company $companyId: $e');
          }
        }),
      );
    }

    // Формируем список ответов
    final responses = <CompanyOrderResponse>[];
    for (final order in orders) {
      final companyId = (order['company_id'] ?? order['companyId'])?.toString();
      if (companyId != null && companiesMap.containsKey(companyId)) {
        responses.add(
          CompanyOrderResponse(
            order: order,
            company: companiesMap[companyId]!,
          ),
        );
      }
    }

    return responses;
  }

  /// Получить количество ответов компаний на заявку
  Future<int> getResponseCount(InquiryModel inquiry) async {
    final responses = await getCompanyResponses(inquiry);
    return responses.length;
  }
}
