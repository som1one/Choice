import 'package:flutter/material.dart';

import '../screens/service_query_screen.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/remote_client_service.dart';
import '../utils/auth_guard.dart';
import '../widgets/choice_logo_icon.dart';
import '../widgets/profile_corner_icon.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String? _city;
  bool _isLoadingCity = true;

  final List<String> _categories = const [
    'Автоуслуги',
    'Услуги строителя',
    'Красота',
    'Бытовые услуги',
    'Финансовые услуги',
    'Парфюм',
    'Автотовары',
  ];

  @override
  void initState() {
    super.initState();
    _loadCity();
  }

  Future<void> _loadCity() async {
    final userType = await AuthService.getUserType();
    if (userType == UserType.client) {
      final clientService = RemoteClientService();
      for (var attempt = 0; attempt < 5; attempt++) {
        try {
          final clientProfile = await clientService.getClientProfile(
            throwOnError: true,
          );
          if (clientProfile != null && mounted) {
            final city = clientProfile['city']?.toString();
            if (city != null && city.isNotEmpty) {
              setState(() {
                _city = city;
                _isLoadingCity = false;
              });
              return;
            }
          }
        } on ApiException catch (e) {
          if (e.statusCode != 404) {
            break;
          }
        } catch (_) {
          break;
        }

        if (attempt < 4) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingCity = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black, width: 2.5),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: ChoiceLogoIcon(size: 30),
            ),
            title: Text(
              _city ?? (_isLoadingCity ? 'Загрузка...' : ''),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
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
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/images/world_map.jpg'),
                fit: BoxFit.cover,
                opacity: 0.25,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.75,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue[100]?.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 2.8,
                                ),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              return _buildCategoryButton(
                                context,
                                _categories[index],
                              );
                            },
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
    );
  }

  Widget _buildCategoryButton(BuildContext context, String category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceQueryScreen(category: category),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF87CEEB),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          category,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPersonIcon() {
    return const ProfileCornerIcon(userType: UserType.client, size: 28);
  }
}
