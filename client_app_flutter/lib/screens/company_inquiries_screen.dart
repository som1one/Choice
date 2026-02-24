// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import '../services/auth_service.dart';
import 'client_inquiry_screen.dart';
import 'company_login_screen.dart';

class CompanyInquiriesScreen extends StatefulWidget {
  const CompanyInquiriesScreen({super.key});

  @override
  State<CompanyInquiriesScreen> createState() => _CompanyInquiriesScreenState();
}

class _CompanyInquiriesScreenState extends State<CompanyInquiriesScreen> {
  List<InquiryModel> _allInquiries = [];
  bool _isLoading = true;
  bool _showOnlyPending = true;

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  Future<void> _loadInquiries() async {
    final allInquiries = await InquiryService.getAllInquiries();

    allInquiries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _allInquiries = allInquiries;
      _isLoading = false;
    });
  }

  bool _isPending(InquiryModel inquiry) {
    return inquiry.companyResponse == null || inquiry.companyResponse!.isEmpty;
  }

  Widget _buildPersonIcon() {
    return CustomPaint(
      size: const Size(28, 28),
      painter: _PersonIconPainter(),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
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

    if (confirm == true) {
      await AuthService.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CompanyLoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleInquiries = _showOnlyPending
        ? _allInquiries.where(_isPending).toList()
        : _allInquiries;

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
            title: const Text(
              'Заявки',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${visibleInquiries.length}',
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: _buildPersonIcon(),
                  onPressed: _logout,
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
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : visibleInquiries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Нет новых заявок',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadInquiries,
                            child: const Text('Обновить'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadInquiries,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Новые'),
                                selected: _showOnlyPending,
                                onSelected: (_) => setState(() => _showOnlyPending = true),
                              ),
                              const SizedBox(width: 10),
                              ChoiceChip(
                                label: const Text('Все'),
                                selected: !_showOnlyPending,
                                onSelected: (_) => setState(() => _showOnlyPending = false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...visibleInquiries.map((inquiry) {
                            final pending = _isPending(inquiry);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Icon(
                                  pending ? Icons.markunread : Icons.done_all,
                                  color: pending ? Colors.blue : Colors.green,
                                ),
                                title: Text(
                                  inquiry.question.length > 50
                                      ? '${inquiry.question.substring(0, 50)}...'
                                      : inquiry.question,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Категория: ${inquiry.category}'),
                                    Text('Клиент: ${inquiry.clientName}'),
                                    Text(
                                      'Дата: ${inquiry.createdAt.day}.${inquiry.createdAt.month}.${inquiry.createdAt.year}',
                                    ),
                                    if (!pending && inquiry.companyName?.isNotEmpty == true)
                                      Text('Ответила: ${inquiry.companyName}'),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () async {
                                  await InquiryService.updateCurrentInquiry(inquiry);
                                  if (!mounted) return;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ClientInquiryScreen(),
                                    ),
                                  );
                                  if (!mounted) return;
                                  _loadInquiries();
                                },
                              ),
                            );
                          }),
                        ],
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
