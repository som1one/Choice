// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import '../services/auth_service.dart';
import 'company_inquiries_screen.dart';
import 'client_registration_screen.dart';
import '../utils/auth_guard.dart';
import 'admin_login_screen.dart';

class CompanyLoginScreen extends StatefulWidget {
  const CompanyLoginScreen({super.key});

  @override
  State<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends State<CompanyLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Map<String, String> _testCompanyAdmin = AuthService.getCompanyAdminTestCredentials();
  String _selectedCity = 'Омск';
  final List<String> _cities = [
    'Москва',
    'Санкт-Петербург',
    'Новосибирск',
    'Екатеринбург',
    'Казань',
    'Нижний Новгород',
    'Челябинск',
    'Самара',
    'Омск',
    'Ростов-на-Дону',
    'Уфа',
    'Красноярск',
    'Воронеж',
    'Пермь',
    'Волгоград',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }
    final ok = await AuthService.loginCompany(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный email или пароль компании')),
      );
      return;
    }
    
    // Переходим на экран заявок компании
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => CompanyInquiriesScreen()),
      (route) => false,
    );
  }

  Widget _buildPersonIcon() {
    return CustomPaint(
      size: const Size(28, 28),
      painter: _PersonIconPainter(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black, width: 3.0),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.favorite, color: Colors.lightBlue, size: 32),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: _selectedCity,
                  underline: Container(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                  ),
                  items: _cities.map((String city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCity = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: _buildPersonIcon(),
                  onPressed: () => AuthGuard.openCompanySettings(context, redirectToLogin: false),
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
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.52,
                      height: 50,
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.52,
                      height: 50,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Пароль',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.52,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Войти',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    if (!kReleaseMode) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.52,
                        child: Text(
                          'Тестовая компания: ${_testCompanyAdmin['email']} / ${_testCompanyAdmin['password']}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.52,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () async {
                            _emailController.text = _testCompanyAdmin['email'] ?? '';
                            _passwordController.text = _testCompanyAdmin['password'] ?? '';
                            await _login();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Войти как тестовая компания',
                            style: TextStyle(color: Colors.black87, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientRegistrationScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Регистрация',
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                        );
                      },
                      child: const Text(
                        'Вход администратора',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Голова (круг)
    final headRadius = size.width * 0.15;
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.3),
      headRadius,
      paint,
    );

    // Тело (линия)
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.45),
      Offset(size.width / 2, size.height * 0.75),
      paint,
    );

    // Руки
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.55),
      Offset(size.width * 0.25, size.height * 0.65),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.55),
      Offset(size.width * 0.75, size.height * 0.65),
      paint,
    );

    // Ноги
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.75),
      Offset(size.width * 0.3, size.height * 0.9),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.75),
      Offset(size.width * 0.7, size.height * 0.9),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
