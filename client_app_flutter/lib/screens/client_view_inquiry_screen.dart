import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import '../services/remote_ordering_service.dart';
import '../services/remote_company_service.dart';
import '../services/remote_client_service.dart';
import '../services/user_profile_service.dart';
import '../utils/auth_guard.dart';
import '../constants/categories.dart';
import 'company_detail_screen.dart';

class ClientViewInquiryScreen extends StatefulWidget {
  const ClientViewInquiryScreen({super.key});

  @override
  State<ClientViewInquiryScreen> createState() => _ClientViewInquiryScreenState();
}

class _ClientViewInquiryScreenState extends State<ClientViewInquiryScreen> {
  InquiryModel? _inquiry;
  bool _isLoading = true;
  List<Map<String, dynamic>> _companyResponses = [];
  int _searchRadiusKm = 20;
  String? _clientCoordinates; // Координаты клиента (lat,lng)
  String? _city; // Город клиента

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Загружаем заявку
    final inquiry = await InquiryService.getCurrentInquiry();
    
    // Загружаем радиус поиска из настроек
    final profile = await UserProfileService.getProfile();
    _searchRadiusKm = profile?.searchRadiusKm ?? 20;

    // Загружаем координаты и город клиента
    final clientService = RemoteClientService();
    final clientProfile = await clientService.getClientProfile();
    if (clientProfile != null) {
      _clientCoordinates = clientProfile['coordinates']?.toString();
      final city = clientProfile['city']?.toString();
      if (city != null && city.isNotEmpty) {
        setState(() {
          _city = city;
        });
      }
    }

    if (inquiry != null) {
      // Получаем заказы по ID заявки (ответы компаний)
      final orderingService = RemoteOrderingService();
      
      // Пытаемся преобразовать ID в int для запроса к API
      final orderRequestId = int.tryParse(inquiry.id);
      
      List<Map<String, dynamic>> relevantOrders = [];
      if (orderRequestId != null) {
        // Получаем заказы напрямую по order_request_id через API
        final orders = await orderingService.getOrders(orderRequestId: orderRequestId);
        relevantOrders = orders ?? [];
      } else {
        // Если ID не может быть преобразован в int, пытаемся найти заказы по строковому ID
        // Получаем все заказы и фильтруем по строковому ID заявки
        final allOrders = await orderingService.getOrders();
        if (allOrders != null && inquiry.id.isNotEmpty) {
          relevantOrders = allOrders.where((order) {
            final reqId = order['order_request_id'] ?? order['orderRequestId'];
            // Сравниваем как строки, так как ID может быть строкой
            return reqId != null && reqId.toString() == inquiry.id;
          }).toList();
        }
      }
      
      if (relevantOrders.isNotEmpty) {

        // Загружаем информацию о компаниях для каждого заказа
        final companyService = RemoteCompanyService();
        final responses = <Map<String, dynamic>>[];
        
        // Получаем категорию заявки для фильтрации компаний
        final inquiryCategory = inquiry?.category ?? '';
        final categoryId = categoryTitleToId(inquiryCategory);
        
        // Получаем компании по категории (если категория известна)
        List<Map<String, dynamic>>? companiesByCategory;
        if (categoryId > 0) {
          companiesByCategory = await companyService.getCompaniesByCategory(categoryId);
        }
        
        // Создаем Map для быстрого поиска компаний по ID
        final companiesMap = <String, Map<String, dynamic>>{};
        if (companiesByCategory != null) {
          for (final company in companiesByCategory) {
            final guid = (company['guid'] ?? company['id'] ?? '').toString();
            if (guid.isNotEmpty) {
              companiesMap[guid] = company;
            }
          }
        }
        
        for (final order in relevantOrders) {
          final companyId = order['company_id'] ?? order['companyId'];
          if (companyId != null) {
            // Сначала пытаемся найти компанию в отфильтрованном списке
            Map<String, dynamic>? company = companiesMap[companyId.toString()];
            
            // Если не найдена в отфильтрованном списке, получаем напрямую
            if (company == null) {
              company = await companyService.getCompany(companyId.toString());
            }
            
            if (company != null) {
              responses.add({
                'order': order,
                'company': company,
              });
            }
          }
        }
        
        setState(() {
          _companyResponses = responses;
        });
      }
    }

    setState(() {
      _inquiry = inquiry;
      _isLoading = false;
    });
  }

  void _selectCompany(Map<String, dynamic> response) {
    final company = response['company'] as Map<String, dynamic>;
    final order = response['order'] as Map<String, dynamic>;
    
    // Открываем детальный экран компании
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailScreen(
          company: company,
          order: order,
          searchRadiusKm: _searchRadiusKm,
        ),
      ),
    );
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
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _city ?? 'Загрузка...',
                  style: const TextStyle(
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
      body: Stack(
        children: [
          // Фоновая карта
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/images/world_map.jpg'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
          ),
          // Круг радиуса поиска
          CustomPaint(
            painter: RadiusCirclePainter(radiusKm: _searchRadiusKm),
            child: Container(),
          ),
          // Маркеры компаний
          ..._buildCompanyMarkers(),
          // Текст "Ответили в радиусе X км" или сообщение об отсутствии ответов
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _companyResponses.isEmpty
                      ? 'Нет ответов от компаний'
                      : 'Ответили в радиусе $_searchRadiusKm км: ${_companyResponses.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          // Кнопка внизу или сообщение об отсутствии компаний
          Positioned(
            bottom: 20,
            left: 20,
            right: 80,
            child: _companyResponses.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Нет ответов от компаний',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Попробуйте позже',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      // Показываем диалог выбора компании
                      _showCompanySelectionDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.lightBlue[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Сделайте выбор',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'откроется информация',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'от компании',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          // Кнопка редактирования
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.purple[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit, color: Colors.purple[800]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCompanyMarkers() {
    final markers = <Widget>[];
    
    if (_companyResponses.isEmpty) return markers;

    // Парсим координаты клиента
    double? clientLat;
    double? clientLng;
    if (_clientCoordinates != null && _clientCoordinates!.isNotEmpty) {
      final coords = _parseCoordinates(_clientCoordinates!);
      if (coords != null) {
        clientLat = coords['lat'];
        clientLng = coords['lng'];
      }
    }

    // Если нет координат клиента, не устанавливаем центр карты
    // Координаты должны быть загружены из профиля клиента
    if (clientLat == null || clientLng == null) {
      // Не используем хардкод координат - координаты должны быть в профиле
      return markers; // Возвращаем только маркеры компаний без центра
    }

    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    for (int i = 0; i < _companyResponses.length; i++) {
      final response = _companyResponses[i];
      final company = response['company'] as Map<String, dynamic>;
      final order = response['order'] as Map<String, dynamic>;
      
      final companyName = company['title'] ?? company['name'] ?? 'Компания';
      final rating = (company['average_grade'] ?? company['rating'] as num?)?.toDouble() ?? 0.0;
      final price = order['price'] ?? 0;
      final deadline = order['deadline'] ?? 0;

      // Получаем координаты компании
      final companyCoordsStr = company['coords'] ?? company['coordinates'];
      Offset? markerPosition;
      
      if (companyCoordsStr != null && companyCoordsStr.toString().isNotEmpty) {
        final companyCoords = _parseCoordinates(companyCoordsStr.toString());
        if (companyCoords != null && clientLat != null && clientLng != null) {
          final companyLat = companyCoords['lat']!;
          final companyLng = companyCoords['lng']!;
          
          // Вычисляем относительную позицию на карте
          markerPosition = _calculateMarkerPosition(
            clientLat,
            clientLng,
            companyLat,
            companyLng,
            centerX,
            centerY,
            screenSize,
          );
        }
      }

      // Если не удалось вычислить позицию, используем равномерное распределение
      if (markerPosition == null) {
        final angle = (2 * math.pi * i) / _companyResponses.length;
        final radius = math.min(screenSize.width, screenSize.height) * 0.25;
        markerPosition = Offset(
          centerX + radius * math.cos(angle) - 60,
          centerY + radius * math.sin(angle) - 80,
        );
      }

      markers.add(
        Positioned(
          left: markerPosition.dx,
          top: markerPosition.dy,
          child: GestureDetector(
            onTap: () => _selectCompany(response),
            child: _buildCompanyMarker(
              companyName: companyName,
              rating: rating,
              price: price,
              deadline: deadline,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  /// Парсит координаты из строки формата "lat,lng" или "lat lng"
  Map<String, double>? _parseCoordinates(String coordsStr) {
    try {
      // Убираем пробелы и разбиваем по запятой или пробелу
      final parts = coordsStr.trim().split(RegExp(r'[,\s]+'));
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          return {'lat': lat, 'lng': lng};
        }
      }
    } catch (e) {
      // Игнорируем ошибки парсинга
    }
    return null;
  }

  /// Вычисляет позицию маркера на экране на основе координат
  Offset _calculateMarkerPosition(
    double clientLat,
    double clientLng,
    double companyLat,
    double companyLng,
    double centerX,
    double centerY,
    Size screenSize,
  ) {
    // Вычисляем расстояние и направление
    final dLat = companyLat - clientLat;
    final dLng = companyLng - clientLng;
    
    // Вычисляем реальное расстояние по формуле гаверсинуса (более точная)
    final R = 6371000.0; // Радиус Земли в метрах
    final lat1Rad = clientLat * math.pi / 180;
    final lat2Rad = companyLat * math.pi / 180;
    final dLatRad = dLat * math.pi / 180;
    final dLngRad = dLng * math.pi / 180;
    
    final a = math.sin(dLatRad / 2) * math.sin(dLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(dLngRad / 2) * math.sin(dLngRad / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = R * c; // расстояние в метрах
    
    // Масштабируем для отображения на экране
    // Используем радиус поиска для масштабирования
    final maxDistance = _searchRadiusKm * 1000; // в метрах
    
    // Если компания вне радиуса, показываем на границе круга
    final scale = distance > maxDistance 
        ? 1.0 
        : math.min(1.0, distance / maxDistance);
    final radius = math.min(screenSize.width, screenSize.height) * 0.3 * scale;
    
    // Вычисляем угол (азимут)
    final angle = math.atan2(dLngRad, dLatRad);
    
    // Вычисляем позицию относительно центра
    final x = centerX + radius * math.cos(angle) - 60;
    final y = centerY + radius * math.sin(angle) - 80;
    
    // Ограничиваем позицию границами экрана
    return Offset(
      x.clamp(0.0, screenSize.width - 120),
      y.clamp(0.0, screenSize.height - 160),
    );
  }

  Widget _buildCompanyMarker({
    required String companyName,
    required double rating,
    required int price,
    required int deadline,
  }) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Рейтинг
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              return Icon(
                index < rating.round() ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 12,
              );
            }),
          ),
          const SizedBox(height: 4),
          // Название компании
          Text(
            companyName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Иконка (автомобиль)
          Icon(Icons.directions_car, size: 16, color: Colors.blue[300]),
          const SizedBox(height: 4),
          // Цена
          Text(
            'Цена $price',
            style: const TextStyle(fontSize: 10),
          ),
          // Сроки
          Text(
            'Срок $deadline ${_getDeadlineUnit(deadline)}',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _getDeadlineUnit(int deadline) {
    if (deadline < 24) return 'часов';
    if (deadline < 168) return 'дней';
    return 'недель';
  }

  void _showCompanySelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите компанию'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _companyResponses.length,
            itemBuilder: (context, index) {
              final response = _companyResponses[index];
              final company = response['company'] as Map<String, dynamic>;
              final order = response['order'] as Map<String, dynamic>;
              final companyName = company['title'] ?? company['name'] ?? 'Компания';
              final rating = (company['average_grade'] ?? company['rating'] as num?)?.toDouble() ?? 0.0;
              final price = order['price'] ?? 0;
              final deadline = order['deadline'] ?? 0;

              return ListTile(
                title: Text(companyName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < rating.round() ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                    Text('Цена: $price'),
                    Text('Срок: $deadline ${_getDeadlineUnit(deadline)}'),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  _selectCompany(response);
                },
              );
            },
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

class RadiusCirclePainter extends CustomPainter {
  final int radiusKm;

  RadiusCirclePainter({required this.radiusKm});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Рисуем круг радиуса поиска (примерно по центру экрана)
    final center = Offset(size.width / 2, size.height / 2);
    // Радиус в пикселях (примерно 1/4 экрана для 20 км)
    final radius = size.width * 0.3;
    
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
