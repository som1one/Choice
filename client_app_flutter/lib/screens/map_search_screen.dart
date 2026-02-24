import 'package:flutter/material.dart';
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import '../services/user_profile_service.dart';
import 'client_admin_cabinet_screen.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  List<InquiryModel> _inquiriesWithResponses = [];
  bool _isLoading = true;
  int _radiusKm = 20;

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем при возврате на экран
    _loadInquiries();
  }

  Future<void> _loadInquiries() async {
    final allInquiries = await InquiryService.getAllInquiries();
    final profile = await UserProfileService.getProfile();
    // Фильтруем только те заявки, на которые компания ответила и есть координаты
    final inquiriesWithResponses = allInquiries.where((inquiry) => 
      inquiry.companyResponse != null && 
      inquiry.companyResponse!.isNotEmpty &&
      inquiry.companyLatitude != null &&
      inquiry.companyLongitude != null
    ).toList();
    
    setState(() {
      _inquiriesWithResponses = inquiriesWithResponses;
      _radiusKm = profile?.searchRadiusKm ?? 20;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.favorite, color: Colors.blue, size: 32),
        title: const Text(
          'Омск',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ClientAdminCabinetScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Placeholder для карты (замените на GoogleMap или аналог)
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/images/world_map.jpg'),
                fit: BoxFit.cover,
                opacity: 0.35,
              ),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Круг радиуса
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                  ),
                  // Метки компаний, которые ответили на заявки
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ..._inquiriesWithResponses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final inquiry = entry.value;
                      final colors = [Colors.yellow, Colors.red, Colors.green, Colors.blue, Colors.orange];
                      final color = colors[index % colors.length];
                      final offset = _offsetFromCoordinates(
                        inquiry.companyLatitude!,
                        inquiry.companyLongitude!,
                      );

                      return Align(
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: offset,
                          child: _CompanyMarker(
                            inquiry.companyName ?? 'Компания',
                            inquiry.price != null ? 'Цена ${inquiry.price}' : 'Цена не указана',
                            inquiry.time != null ? 'Срок ${inquiry.time}' : 'Срок не указан',
                            color,
                            response: inquiry.companyResponse,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.5),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Text(
                'Ответили в радиусе $_radiusKm км',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Нажмите на метку, чтобы открыть ответ компании',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (!_isLoading && _inquiriesWithResponses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 380),
                child: Text(
                  'Пока нет ответов от компаний',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),

    );
  }

  Offset _offsetFromCoordinates(double latitude, double longitude) {
    // Центр Омска. Преобразование приблизительное для плейсхолдера-карты.
    const centerLat = 54.9885;
    const centerLon = 73.3686;
    final dx = (longitude - centerLon) * 900;
    final dy = -(latitude - centerLat) * 900;
    return Offset(
      dx.clamp(-120.0, 120.0).toDouble(),
      dy.clamp(-120.0, 120.0).toDouble(),
    );
  }
}

class _CompanyMarker extends StatelessWidget {
  final String name;
  final String price;
  final String time;
  final Color color;
  final String? response;

  const _CompanyMarker(this.name, this.price, this.time, this.color, {this.response});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: response != null && response!.isNotEmpty
          ? () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(name),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (price.isNotEmpty) Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (time.isNotEmpty) Text(time),
                        if (response != null && response!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Ответ:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(response!),
                        ],
                      ],
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
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: color, size: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(price, style: const TextStyle(fontSize: 10)),
                Text(time, style: const TextStyle(fontSize: 10)),
                if (response != null && response!.isNotEmpty)
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
