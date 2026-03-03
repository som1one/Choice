// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile_model.dart';
import '../utils/auth_guard.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';
import 'change_password_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'chats_screen.dart';

class ClientAdminCabinetScreen extends StatefulWidget {
  const ClientAdminCabinetScreen({super.key});

  @override
  State<ClientAdminCabinetScreen> createState() => _ClientAdminCabinetScreenState();
}

class _ClientAdminCabinetScreenState extends State<ClientAdminCabinetScreen> {
  final Map<String, bool> _checkboxes = {
    'Имя': true,
    'Адрес': true,
    'Mail': true,
    'Телефон': true,
  };
  final Map<String, TextEditingController> _controllers = {
    'Имя': TextEditingController(),
    'Адрес': TextEditingController(),
    'Mail': TextEditingController(),
    'Телефон': TextEditingController(),
  };
  
  bool _askPrice = true;
  bool _askSpecialist = true;
  bool _askAppointmentTime = true;
  bool _askAvailability = true;
  bool _askWorkTime = true;
  
  String? _selectedAccountOption = 'Логин'; // Логин, Пароль, Аватар
  String? _avatarPath;
  int _searchRadiusKm = 20;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureAuthorized();
    });
  }

  Future<void> _ensureAuthorized() async {
    final loggedIn = await AuthService.isLoggedIn();
    final userType = await AuthService.getUserType();
    final ok = loggedIn && (userType == UserType.client || userType == UserType.admin);

    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала войдите как клиент')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
      return;
    }

    _loadSettings();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('client_settings');
    if (raw == null) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (!mounted) return;
    setState(() {
      _avatarPath = data['avatarPath'] as String?;
      for (final key in _checkboxes.keys) {
        _checkboxes[key] = data['cb_$key'] as bool? ?? _checkboxes[key]!;
      }
      for (final key in _controllers.keys) {
        _controllers[key]!.text = data['f_$key'] as String? ?? '';
      }
      _askPrice = data['askPrice'] as bool? ?? true;
      _askSpecialist = data['askSpecialist'] as bool? ?? true;
      _askAppointmentTime = data['askAppointmentTime'] as bool? ?? true;
      _askAvailability = data['askAvailability'] as bool? ?? true;
      _askWorkTime = data['askWorkTime'] as bool? ?? true;
      _searchRadiusKm = data['searchRadiusKm'] as int? ?? 20;
      _selectedAccountOption = data['selectedAccountOption'] as String? ?? 'Логин';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{'avatarPath': _avatarPath};
    for (final entry in _checkboxes.entries) {
      data['cb_${entry.key}'] = entry.value;
    }
    for (final entry in _controllers.entries) {
      data['f_${entry.key}'] = entry.value.text.trim();
    }
    data['askPrice'] = _askPrice;
    data['askSpecialist'] = _askSpecialist;
    data['askAppointmentTime'] = _askAppointmentTime;
    data['askAvailability'] = _askAvailability;
    data['askWorkTime'] = _askWorkTime;
    data['searchRadiusKm'] = _searchRadiusKm;
    data['selectedAccountOption'] = _selectedAccountOption;
    await prefs.setString('client_settings', jsonEncode(data));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки клиента сохранены')),
    );
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _avatarPath = image.path;
    });
    await _saveSettings();
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Инструкция приложения'),
        content: const SingleChildScrollView(
          child: Text('Инструкция для клиента будет здесь...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
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
              bottom: BorderSide(
                color: Colors.black,
                width: 1.0,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.lightBlue[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        'V',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: const Text(
              'НАСТРОЙКИ КЛИЕНТА',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: _buildPersonIcon(),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Вы уже в настройках клиента')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Отметьте информацию которая будет отображаться в вопросе для компани',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              
              _buildInputFieldWithCheckbox(Icons.edit, 'Имя', _checkboxes['Имя']!, _controllers['Имя']!),
              _buildInputFieldWithCheckbox(Icons.home, 'Адрес', _checkboxes['Адрес']!, _controllers['Адрес']!),
              _buildInputFieldWithCheckbox(Icons.mail, 'Mail', _checkboxes['Mail']!, _controllers['Mail']!),
              _buildInputFieldWithCheckbox(Icons.phone, 'Телефон', _checkboxes['Телефон']!, _controllers['Телефон']!),
              
              _buildCheckboxField(Icons.attach_money, 'Узнать стоимость', _askPrice, (v) => setState(() => _askPrice = v)),
              _buildCheckboxField(Icons.person, 'Узнать имя специалиста', _askSpecialist, (v) => setState(() => _askSpecialist = v)),
              _buildCheckboxField(Icons.access_time, 'Узнать врямя записи', _askAppointmentTime, (v) => setState(() => _askAppointmentTime = v)),
              _buildCheckboxField(Icons.inventory, 'Узнать наличие товара', _askAvailability, (v) => setState(() => _askAvailability = v)),
              _buildCheckboxField(Icons.work, 'Узнать время выполнения работ', _askWorkTime, (v) => setState(() => _askWorkTime = v)),

              const Divider(height: 32, thickness: 1, color: Colors.black),

              _buildRadioField(Icons.settings, 'Логин', 'Логин'),
              _buildRadioField(null, 'Пароль', 'Пароль'),
              _buildRadioField(null, 'Аватар', 'Аватар'),

              const Divider(height: 32, thickness: 1, color: Colors.black),

              Row(
                children: [
                  Icon(Icons.monetization_on, size: 24, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  const Text('Деньги', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              _buildPrepaymentButton('Привязать карту для оплаты'),

              const SizedBox(height: 24),

              const Text(
                'Выбрать радиус поиска',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [5, 10, 15, 20, 50]
                    .map((km) => _buildRadiusButton(km))
                    .toList(),
              ),

              const SizedBox(height: 24),

              _buildPrepaymentButton('Инструкция приложения', onTap: _showInstructions),
              const SizedBox(height: 12),
              _buildPrepaymentButton('Чат с компанией', onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatsScreen()),
                );
              }),
              const SizedBox(height: 16),
              _buildPrepaymentButton('Сохранить настройки', onTap: _saveSettings),
              const SizedBox(height: 16),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputFieldWithCheckbox(
    IconData icon,
    String label,
    bool checked,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _checkboxes[label] = !_checkboxes[label]!;
          });
        },
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey[700]),
            const SizedBox(width: 12),
            SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 15))),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  isDense: true,
                  border: UnderlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              checked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: checked ? Colors.blue : Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxField(
    IconData icon,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
            Icon(
              value ? Icons.check_circle : Icons.radio_button_unchecked,
              color: value ? Colors.blue : Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioField(IconData? icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () => setState(() => _selectedAccountOption = value),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24, color: Colors.grey[700]),
              const SizedBox(width: 12),
            ] else
              const SizedBox(width: 36),
            Text(label, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Radio<String>(
              value: value,
              groupValue: _selectedAccountOption,
              onChanged: (v) => setState(() => _selectedAccountOption = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrepaymentButton(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.lightBlue[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRadiusButton(int km) {
    final selected = _searchRadiusKm == km;
    return GestureDetector(
      onTap: () => setState(() => _searchRadiusKm = km),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.lightGreen : Colors.lightGreen[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$km км',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildPersonIcon() {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _PersonIconPainter(),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
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
                child: const Text('Выйти', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm == true && mounted) {
          await AuthService.logout();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Выйти из аккаунта',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
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
      ..strokeWidth = 2;

    // Рисуем голову (круг)
    final headRadius = size.width * 0.25;
    canvas.drawCircle(
      Offset(size.width / 2, headRadius),
      headRadius,
      paint,
    );

    // Рисуем тело (прямоугольник с вогнутой нижней частью - две "ножки")
    final bodyWidth = size.width * 0.7;
    final bodyHeight = size.height * 0.5;
    final bodyTop = headRadius * 2.1;
    final bodyLeft = (size.width - bodyWidth) / 2;
    final bodyBottom = bodyTop + bodyHeight;
    final indentWidth = bodyWidth * 0.25;
    final indentDepth = bodyHeight * 0.15;

    final path = Path()
      ..moveTo(bodyLeft, bodyTop)
      ..lineTo(bodyLeft + bodyWidth, bodyTop)
      ..lineTo(bodyLeft + bodyWidth, bodyBottom - indentDepth)
      ..lineTo(bodyLeft + bodyWidth - indentWidth, bodyBottom - indentDepth)
      ..lineTo(bodyLeft + bodyWidth - indentWidth, bodyBottom)
      ..lineTo(bodyLeft + indentWidth, bodyBottom)
      ..lineTo(bodyLeft + indentWidth, bodyBottom - indentDepth)
      ..lineTo(bodyLeft, bodyBottom - indentDepth)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
