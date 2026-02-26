import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/company_login_screen.dart';
import '../screens/client_admin_cabinet_screen.dart';
import '../screens/company_settings_screen.dart';

class AuthGuard {
  static Future<void> openClientCabinet(BuildContext context, {bool redirectToLogin = true}) async {
    final loggedIn = await AuthService.isLoggedIn();
    final userType = await AuthService.getUserType();
    final ok = loggedIn && (userType == UserType.client || userType == UserType.admin);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала войдите как клиент')),
      );
      if (redirectToLogin) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientAdminCabinetScreen()));
  }

  static Future<void> openCompanySettings(BuildContext context, {bool redirectToLogin = true}) async {
    final loggedIn = await AuthService.isLoggedIn();
    final userType = await AuthService.getUserType();
    final ok = loggedIn && (userType == UserType.company || userType == UserType.admin);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала войдите как компания')),
      );
      if (redirectToLogin) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyLoginScreen()));
      }
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanySettingsScreen()));
  }
}

