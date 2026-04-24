import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import '../services/order_response_service.dart';
import '../services/remote_client_service.dart';
import '../services/user_profile_service.dart';
import '../utils/auth_guard.dart';
import 'company_detail_screen.dart';
import '../services/auth_service.dart';
import '../widgets/choice_logo_icon.dart';
import '../widgets/profile_corner_icon.dart';

class ClientViewInquiryScreen extends StatefulWidget {
  const ClientViewInquiryScreen({super.key});

  @override
  State<ClientViewInquiryScreen> createState() => _ClientViewInquiryScreenState();
}

class _ClientViewInquiryScreenState extends State<ClientViewInquiryScreen> {
  InquiryModel? _inquiry;
  bool _isLoading = true;
  bool _isLoadingResponses = false;
  List<CompanyOrderResponse> _companyResponses = [];
  int _searchRadiusKm = 20;
  String? _clientCoordinates; // Координаты клиента (lat,lng)
  String? _city; // Город клиента
  String? _errorMessage;
  
  final OrderResponseService _responseService = OrderResponseService();

  bool get _hasClientCoordinates {
    if (_clientCoordinates == null || _clientCoordinates!.trim().isEmpty) {
      return false;
    }
    return _parseCoordinates(_clientCoordinates!) != null;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Загружаем заявку
      final inquiry = await InquiryService.getCurrentInquiry();
      
      if (inquiry == null) {
        setState(() {
          _inquiry = null;
          _isLoading = false;
          _errorMessage = 'Заявка не найдена';
        });
        return;
      }

      // Загружаем радиус поиска из настроек
      final profile = await UserProfileService.getProfile();
      _searchRadiusKm = profile?.searchRadiusKm ?? 20;

      // Загружаем координаты и город клиента
      await _loadClientProfile();

      // Загружаем ответы компаний
      await _loadCompanyResponses(inquiry);

      setState(() {
        _inquiry = inquiry;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading inquiry data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка загрузки данных';
      });
    }
  }

  /// Загружает профиль клиента (координаты и город)
  Future<void> _loadClientProfile() async {
    try {
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
    } catch (e) {
      debugPrint('Error loading client profile: $e');
    }
  }

  /// Загружает ответы компаний на заявку
  Future<void> _loadCompanyResponses(InquiryModel inquiry) async {
    setState(() {
      _isLoadingResponses = true;
    });

    try {
      final responses = await _responseService.getCompanyResponses(inquiry);
      setState(() {
        _companyResponses = responses;
        _isLoadingResponses = false;
      });
    } catch (e) {
      debugPrint('Error loading company responses: $e');
      setState(() {
        _companyResponses = [];
        _isLoadingResponses = false;
      });
    }
  }

  /// Обновить данные (pull-to-refresh)
  Future<void> _refreshData() async {
    if (_inquiry != null) {
      await _loadCompanyResponses(_inquiry!);
    }
  }

  void _selectCompany(CompanyOrderResponse response) {
    // Открываем детальный экран компании
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailScreen(
          company: response.company,
          order: response.order,
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
        appBar: AppBar(title: const Text('Ошибка')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Запрос не найден',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Назад'),
              ),
            ],
          ),
        ),
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
              child: const ChoiceLogoIcon(size: 30),
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Stack(
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _companyResponses.isEmpty
                        ? Colors.grey[300]!
                        : const Color(0xFF87CEEB).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isLoadingResponses
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Загрузка ответов...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _companyResponses.isEmpty
                                ? Icons.info_outline
                                : Icons.check_circle,
                            size: 18,
                            color: _companyResponses.isEmpty
                                ? Colors.grey[600]
                                : const Color(0xFF87CEEB),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _companyResponses.isEmpty
                                ? 'Нет ответов от компаний'
                                : 'Ответили в радиусе $_searchRadiusKm км: ${_companyResponses.length}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _companyResponses.isEmpty
                                  ? Colors.grey[700]
                                  : const Color(0xFF2D81E0),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (!_isLoadingResponses &&
              _companyResponses.isNotEmpty &&
              !_hasClientCoordinates)
            Positioned(
              top: 122,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                  ),
                  child: const Text(
                    'Точные координаты профиля не найдены, поэтому отклики показаны схематично.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 24,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Нет ответов от компаний',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Попробуйте позже',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Показываем диалог выбора компании
                        _showCompanySelectionDialog();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.touch_app,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Сделайте выбор',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'откроется информация от компании',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
        ],
        ),
      ),
    );
  }

  List<Widget> _buildCompanyMarkers() {
    final markers = <Widget>[];

    if (_companyResponses.isEmpty) return markers;

    const markerWidth = 140.0;
    const markerHeight = 132.0;

    double? clientLat;
    double? clientLng;
    if (_clientCoordinates != null && _clientCoordinates!.isNotEmpty) {
      final coords = _parseCoordinates(_clientCoordinates!);
      if (coords != null) {
        clientLat = coords['lat'];
        clientLng = coords['lng'];
      }
    }

    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height * 0.46;
    final fallbackRadius = math.min(screenSize.width, screenSize.height) * 0.24;

    for (int i = 0; i < _companyResponses.length; i++) {
      final response = _companyResponses[i];
      
      final companyName = response.companyName;
      final rating = response.rating;
      final price = response.price;
      final deadline = response.deadline;

      // Получаем координаты компании
      final companyCoordsStr = response.company['coords'] ?? response.company['coordinates'];
      Offset? markerPosition;

      if (clientLat != null &&
          clientLng != null &&
          companyCoordsStr != null &&
          companyCoordsStr.toString().isNotEmpty) {
        final companyCoords = _parseCoordinates(companyCoordsStr.toString());
        if (companyCoords != null) {
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
            markerWidth,
            markerHeight,
          );
        }
      }

      // Если точных координат нет, не прячем отклики — показываем их равномерно.
      if (markerPosition == null) {
        final angle = (2 * math.pi * i) / math.max(_companyResponses.length, 1);
        final x =
            centerX + fallbackRadius * math.cos(angle) - (markerWidth / 2);
        final y =
            centerY + fallbackRadius * math.sin(angle) - (markerHeight / 2);
        markerPosition = _clampMarkerPosition(
          Offset(x, y),
          screenSize,
          markerWidth,
          markerHeight,
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
    double markerWidth,
    double markerHeight,
  ) {
    final avgLatRad = ((clientLat + companyLat) / 2) * math.pi / 180;
    final dxMeters =
        (companyLng - clientLng) * 111320 * math.cos(avgLatRad);
    final dyMeters = (companyLat - clientLat) * 111320;

    final maxDistanceMeters = math.max(_searchRadiusKm * 1000, 1);
    double normalizedX = dxMeters / maxDistanceMeters;
    double normalizedY = dyMeters / maxDistanceMeters;

    final distanceRatio =
        math.sqrt((normalizedX * normalizedX) + (normalizedY * normalizedY));
    if (distanceRatio > 1) {
      normalizedX /= distanceRatio;
      normalizedY /= distanceRatio;
    }

    final visualRadius = math.min(screenSize.width, screenSize.height) * 0.28;
    final rawPosition = Offset(
      centerX + (normalizedX * visualRadius) - (markerWidth / 2),
      centerY - (normalizedY * visualRadius) - (markerHeight / 2),
    );

    return _clampMarkerPosition(
      rawPosition,
      screenSize,
      markerWidth,
      markerHeight,
    );
  }

  Offset _clampMarkerPosition(
    Offset rawPosition,
    Size screenSize,
    double markerWidth,
    double markerHeight,
  ) {
    return Offset(
      rawPosition.dx.clamp(8.0, screenSize.width - markerWidth - 8.0),
      rawPosition.dy.clamp(150.0, screenSize.height - markerHeight - 120.0),
    );
  }

  Widget _buildCompanyMarker({
    required String companyName,
    required double rating,
    required int price,
    required int deadline,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFF87CEEB).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF87CEEB).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF87CEEB).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Рейтинг с фоном
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < rating.round() ? Icons.star : Icons.star_border,
                          color: Colors.amber[700],
                          size: 10,
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber[900],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Название компании
                Text(
                  companyName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                // Цена и сроки
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 12,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  price > 0 ? '$price ₽' : 'По договорённости',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '$deadline ${_getDeadlineUnit(deadline)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D81E0), Color(0xFF87CEEB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Выберите компанию',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Список компаний
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _companyResponses.length,
                  itemBuilder: (context, index) {
                    final response = _companyResponses[index];
                    final companyName = response.companyName;
                    final rating = response.rating;
                    final price = response.price;
                    final deadline = response.deadline;

                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF87CEEB).withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _selectCompany(response);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Иконка компании
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF87CEEB),
                                          const Color(0xFF2D81E0),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.business_center,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Информация
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          companyName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            ...List.generate(5, (i) {
                                              return Icon(
                                                i < rating.round() ? Icons.star : Icons.star_border,
                                                color: Colors.amber,
                                                size: 14,
                                              );
                                            }),
                                            const SizedBox(width: 6),
                                            Text(
                                              rating.toStringAsFixed(1),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.attach_money,
                                                    size: 12,
                                                    color: Colors.green[700],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    price > 0 ? '$price ₽' : 'По договорённости',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.green[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 12,
                                                    color: Colors.blue[700],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$deadline ${_getDeadlineUnit(deadline)}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.blue[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Стрелка
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey[400],
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonIcon() {
    return const ProfileCornerIcon(userType: UserType.client, size: 28);
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
