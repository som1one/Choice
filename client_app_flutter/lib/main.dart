import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform;
import 'screens/welcome_screen.dart';
import 'navigation/client_tab_navigator.dart';
import 'navigation/company_tab_navigator.dart';
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';
import 'services/api_client.dart';

// Обработчик фоновых сообщений (должен быть top-level функцией)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Проверяем, не инициализирован ли уже Firebase
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      debugPrint('Background message received: ${message.messageId}');
  } catch (e) {
    debugPrint('Firebase background handler error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeMobileServices();
  });
}

Future<void> _initializeMobileServices() async {
  if (kIsWeb) {
    debugPrint('Firebase skipped on web platform');
    return;
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // На iOS не блокируем старт приложения и не даем push-инициализации
    // ломать базовый UI, если проект еще не полностью настроен под Firebase.
    if (Platform.isIOS) {
      try {
        await PushNotificationService.initialize();
      } catch (e) {
        debugPrint('Push initialization skipped on iOS: $e');
      }
      return;
    }

    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  // Глобальный navigator key для навигации и показа ошибок
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Устанавливаем navigator key для ApiClient
    ApiClient.setNavigatorKey(navigatorKey);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
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
