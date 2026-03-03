import 'package:flutter/material.dart';
import '../screens/company_inquiries_screen.dart';
import '../screens/chats_screen.dart';
import '../screens/company_settings_screen.dart';

class CompanyTabNavigator extends StatefulWidget {
  const CompanyTabNavigator({super.key});

  @override
  State<CompanyTabNavigator> createState() => _CompanyTabNavigatorState();
}

class _CompanyTabNavigatorState extends State<CompanyTabNavigator> {
  int _currentIndex = 0;
  int _unreadMessagesCount = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _updateUnreadCount(int count) {
    setState(() {
      _unreadMessagesCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const CompanyInquiriesScreen(),
          ChatsScreen(onUnreadCountChanged: _updateUnreadCount),
          const CompanySettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2975CC),
        unselectedItemColor: const Color(0xFF99A2AD),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Заявки',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat),
                if (_unreadMessagesCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_unreadMessagesCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Чат',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Аккаунт',
          ),
        ],
      ),
    );
  }
}
