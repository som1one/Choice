// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/remote_admin_service.dart';
import 'login_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _remote = RemoteAdminService();

  Future<List<Map<String, dynamic>>?> _clientsFuture = Future.value(null);
  Future<List<Map<String, dynamic>>?> _companiesFuture = Future.value(null);
  Future<List<Map<String, dynamic>>?> _reviewsFuture = Future.value(null);

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  void _reloadAll() {
    setState(() {
      _clientsFuture = _remote.getClients();
      _companiesFuture = _remote.getCompaniesAdmin();
      _reviewsFuture = _remote.getAllReviewsAdmin();
    });
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Выйти из админ-аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Админ-панель'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Клиенты'),
              Tab(text: 'Компании'),
              Tab(text: 'Отзывы'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Обновить',
              icon: const Icon(Icons.refresh),
              onPressed: _reloadAll,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _ClientsTab(future: _clientsFuture, onDelete: _remote.deleteClientByGuid, onReload: _reloadAll),
            _CompaniesTab(future: _companiesFuture, onDelete: _remote.deleteCompanyByGuid, onReload: _reloadAll),
            _ReviewsTab(future: _reviewsFuture, onDelete: _remote.deleteReview, onReload: _reloadAll),
          ],
        ),
      ),
    );
  }
}

class _ClientsTab extends StatelessWidget {
  final Future<List<Map<String, dynamic>>?> future;
  final Future<bool> Function(String guid) onDelete;
  final VoidCallback onReload;

  const _ClientsTab({
    required this.future,
    required this.onDelete,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data;
        if (items == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Нет доступа или бэк недоступен. Убедись, что вошёл как Admin и сервисы подняты.'),
            ),
          );
        }
        if (items.isEmpty) return const Center(child: Text('Клиентов нет'));
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final c = items[i];
            final guid = (c['guid'] ?? '').toString();
            final name = '${c['name'] ?? ''} ${c['surname'] ?? ''}'.trim();
            final email = (c['email'] ?? '').toString();
            final phone = (c['phone_number'] ?? '').toString();
            return ListTile(
              title: Text(name.isEmpty ? '(без имени)' : name),
              subtitle: Text('$email\n$phone\n$guid'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: guid.isEmpty
                    ? null
                    : () async {
                        final ok = await onDelete(guid);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Клиент удалён' : 'Не удалось удалить клиента')),
                        );
                        onReload();
                      },
              ),
            );
          },
        );
      },
    );
  }
}

class _CompaniesTab extends StatelessWidget {
  final Future<List<Map<String, dynamic>>?> future;
  final Future<bool> Function(String guid) onDelete;
  final VoidCallback onReload;

  const _CompaniesTab({
    required this.future,
    required this.onDelete,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data;
        if (items == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Нет доступа или бэк недоступен. Убедись, что вошёл как Admin и сервисы подняты.'),
            ),
          );
        }
        if (items.isEmpty) return const Center(child: Text('Компаний нет'));
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final c = items[i];
            final guid = (c['guid'] ?? '').toString();
            final title = (c['title'] ?? '').toString();
            final email = (c['email'] ?? '').toString();
            final phone = (c['phone_number'] ?? '').toString();
            return ListTile(
              title: Text(title.isEmpty ? '(без названия)' : title),
              subtitle: Text('$email\n$phone\n$guid'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: guid.isEmpty
                    ? null
                    : () async {
                        final ok = await onDelete(guid);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Компания удалена' : 'Не удалось удалить компанию')),
                        );
                        onReload();
                      },
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final Future<List<Map<String, dynamic>>?> future;
  final Future<bool> Function(int id) onDelete;
  final VoidCallback onReload;

  const _ReviewsTab({
    required this.future,
    required this.onDelete,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data;
        if (items == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Нет доступа или бэк недоступен. Убедись, что вошёл как Admin и сервисы подняты.'),
            ),
          );
        }
        if (items.isEmpty) return const Center(child: Text('Отзывов нет'));
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = items[i];
            final id = (r['id'] as num?)?.toInt();
            final grade = r['grade']?.toString() ?? '';
            final text = (r['text'] ?? '').toString();
            final sender = (r['sender_id'] ?? '').toString();
            final receiver = (r['receiver_id'] ?? '').toString();
            return ListTile(
              title: Text('★ $grade  (id: ${id ?? '-'})'),
              subtitle: Text('$text\nsender: $sender\nreceiver: $receiver'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: id == null
                    ? null
                    : () async {
                        final ok = await onDelete(id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Отзыв удалён' : 'Не удалось удалить отзыв')),
                        );
                        onReload();
                      },
              ),
            );
          },
        );
      },
    );
  }
}

