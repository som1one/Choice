import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen_new.dart';
import 'navigation/client_tab_navigator.dart';
import 'navigation/company_tab_navigator.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ВЫБОР',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2D81E0),
      ),
      home: FutureBuilder<Map<String, dynamic>>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Показываем welcome screen во время проверки авторизации
            return const WelcomeScreen();
          }
          
          final data = snapshot.data ?? {'authenticated': false, 'isCompany': false};
          
          // Если пользователь авторизован, показываем соответствующий экран с табами
          if (data['authenticated'] == true) {
            if (data['isCompany'] == true) {
              return const CompanyTabNavigator();
            } else {
              return const ClientTabNavigator();
            }
          }
          
          // Иначе показываем welcome screen, который перейдет на экран входа
          return const WelcomeScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  Future<Map<String, dynamic>> _getInitialScreen() async {
    final authenticated = await AuthService.isAuthenticated();
    final isCompany = await AuthService.isCompany();
    return {
      'authenticated': authenticated,
      'isCompany': isCompany,
    };
  }
}
