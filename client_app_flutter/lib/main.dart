import 'package:flutter/material.dart';
import 'screens/client_registration_screen.dart';
import 'screens/category_screen.dart';
import 'screens/company_inquiries_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OMCK App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<Map<String, dynamic>>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          final data = snapshot.data ?? {'authenticated': false, 'isCompany': false};
          
          // Если пользователь авторизован, показываем соответствующий экран
          if (data['authenticated'] == true) {
            if (data['isCompany'] == true) {
              return CompanyInquiriesScreen();
            } else {
              return CategoryScreen();
            }
          }
          
          // Иначе показываем экран регистрации клиента
          return ClientRegistrationScreen();
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
