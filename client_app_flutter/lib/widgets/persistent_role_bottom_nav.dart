import 'package:flutter/material.dart';

import '../navigation/client_tab_navigator.dart';
import '../navigation/company_tab_navigator.dart';

enum RoleBottomNavType { client, company }

class PersistentRoleBottomNav extends StatelessWidget {
  final RoleBottomNavType type;
  final int currentIndex;

  const PersistentRoleBottomNav({
    super.key,
    required this.type,
    required this.currentIndex,
  });

  void _openRootTab(BuildContext context, int index) {
    final Widget destination = switch (type) {
      RoleBottomNavType.client => ClientTabNavigator(initialIndex: index),
      RoleBottomNavType.company => CompanyTabNavigator(initialIndex: index),
    };

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = type == RoleBottomNavType.client
        ? const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.category),
              label: 'Услуги',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: 'Заказы',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Чат',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Аккаунт',
            ),
          ]
        : const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.category),
              label: 'Заявки',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: 'Заказы',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Чат',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Аккаунт',
            ),
          ];

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _openRootTab(context, index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF2975CC),
      unselectedItemColor: const Color(0xFF99A2AD),
      items: items,
    );
  }
}
