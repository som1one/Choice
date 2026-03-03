import 'package:flutter/material.dart';
import 'login_by_email_screen.dart';
import 'login_by_phone_screen.dart';
import 'client_registration_screen.dart';
import 'company_registration_screen.dart';
import 'reset_password_screen.dart';
import '../navigation/client_tab_navigator.dart';
import '../navigation/company_tab_navigator.dart';

class LoginScreenNew extends StatefulWidget {
  const LoginScreenNew({super.key});

  @override
  State<LoginScreenNew> createState() => _LoginScreenNewState();
}

class _LoginScreenNewState extends State<LoginScreenNew>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentTab = 0;
  bool _showRegisterModal = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController(initialPage: 0);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      setState(() {
        _currentTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleLoginSuccess(bool isCompany, bool needsFillData) {
    if (!mounted) return;
    
    // Перезагружаем приложение чтобы показать правильный экран
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => isCompany
            ? const CompanyTabNavigator()
            : const ClientTabNavigator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Логотип и название
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Column(
                children: [
                  // TODO: Добавить логотип choice-logo.png
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.business, size: 80, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ВЫБОР',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF313131),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Приложение для выбора',
                    style: TextStyle(fontSize: 16),
                  ),
                  const Text(
                    'лучших условий',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Заголовок "Авторизация" и кнопка "Создать аккаунт"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const Text(
                    'Авторизация',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF313131),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showRegisterModal = true;
                      });
                    },
                    child: const Text(
                      'Создать аккаунт',
                      style: TextStyle(
                        color: Color(0xFF2D81E0),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Табы
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _tabController.animateTo(0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _currentTab == 0
                                  ? const Color(0xFF2D81E0)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          'E-mail',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _currentTab == 0
                                ? const Color(0xFF2D81E0)
                                : Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _tabController.animateTo(1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _currentTab == 1
                                  ? const Color(0xFF2D81E0)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          'Телефон',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _currentTab == 1
                                ? const Color(0xFF2D81E0)
                                : Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Контент табов
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  _tabController.animateTo(index);
                  setState(() {
                    _currentTab = index;
                  });
                },
                children: [
                  LoginByEmailScreen(onLoginSuccess: _handleLoginSuccess),
                  LoginByPhoneScreen(onLoginSuccess: _handleLoginSuccess),
                ],
              ),
            ),
          ],
        ),
      ),
      // Модальное окно выбора типа регистрации
      bottomSheet: _showRegisterModal
          ? Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  ListTile(
                    title: const Text(
                      'Создать аккаунт клиента',
                      style: TextStyle(
                        color: Color(0xFF2688EB),
                        fontWeight: FontWeight.w400,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      setState(() {
                        _showRegisterModal = false;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ClientRegistrationScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text(
                      'Создать аккаунт компании',
                      style: TextStyle(
                        color: Color(0xFF2688EB),
                        fontWeight: FontWeight.w400,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      setState(() {
                        _showRegisterModal = false;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CompanyRegistrationScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text(
                      'Отменить',
                      style: TextStyle(
                        color: Color(0xFF2688EB),
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      setState(() {
                        _showRegisterModal = false;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            )
          : null,
    );
  }
}
