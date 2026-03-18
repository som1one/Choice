import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../utils/auth_guard.dart';
import 'company_login_screen.dart';
import 'welcome_screen.dart';

class CompanyAdminCabinetScreen extends StatefulWidget {
  const CompanyAdminCabinetScreen({super.key});

  @override
  State<CompanyAdminCabinetScreen> createState() => _CompanyAdminCabinetScreenState();
}

class _CompanyAdminCabinetScreenState extends State<CompanyAdminCabinetScreen> {
  final Map<String, bool> _checkboxes = {
    'Название': true,
    'Адрес': true,
    'Mail': true,
    'Телефон': true,
    'Имя специалиста': true,
    'Виды деятельности': true,
    'Сайт': true,
  };
  final Map<String, TextEditingController> _controllers = {
    'Название': TextEditingController(),
    'Адрес': TextEditingController(),
    'Mail': TextEditingController(),
    'Телефон': TextEditingController(),
    'Имя специалиста': TextEditingController(),
    'Виды деятельности': TextEditingController(),
    'Сайт': TextEditingController(),
  };
  
  String? _logoPath;
  String? _photoPath;
  Color _selectedCardColor = Colors.blue;
  final ImagePicker _picker = ImagePicker();
  
  // Список рейтинговых критериев (действий)
  List<String> _ratingCriteria = [
    'Качество работы',
    'Скорость выполнения',
    'Вежливость',
    'Цена',
    'Соблюдение сроков',
  ];
  
  // Список услуг
  List<String> _services = [
    'Малярные работы',
    'Мелкосрочный ремонт',
    'Установка гбо',
    'Диагностика',
    'Установка сигнализации',
  ];
  
  final TextEditingController _newRatingCriterionController = TextEditingController();
  final TextEditingController _newServiceController = TextEditingController();

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
    // Только админ может видеть этот экран
    final ok = loggedIn && userType == UserType.admin;

    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Доступ только для администратора')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CompanyLoginScreen()),
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
    _newRatingCriterionController.dispose();
    _newServiceController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('company_admin_settings');
    if (raw == null) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (!mounted) return;
    setState(() {
      _logoPath = data['logoPath'] as String?;
      _photoPath = data['photoPath'] as String?;
      final colorValue = data['cardColor'] as int?;
      if (colorValue != null) {
        _selectedCardColor = Color(colorValue);
      }
      for (final key in _checkboxes.keys) {
        _checkboxes[key] = data['cb_$key'] as bool? ?? _checkboxes[key]!;
      }
      for (final key in _controllers.keys) {
        _controllers[key]!.text = data['f_$key'] as String? ?? '';
      }
      // Загружаем рейтинговые критерии и услуги
      if (data['ratingCriteria'] is List) {
        _ratingCriteria = (data['ratingCriteria'] as List).map((e) => e.toString()).toList();
      }
      if (data['services'] is List) {
        _services = (data['services'] as List).map((e) => e.toString()).toList();
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'logoPath': _logoPath,
      'photoPath': _photoPath,
      'cardColor': _selectedCardColor.toARGB32(),
      'ratingCriteria': _ratingCriteria,
      'services': _services,
    };
    for (final entry in _checkboxes.entries) {
      data['cb_${entry.key}'] = entry.value;
    }
    for (final entry in _controllers.entries) {
      data['f_${entry.key}'] = entry.value.text;
    }
    await prefs.setString('company_admin_settings', jsonEncode(data));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки сохранены')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source, {bool isLogo = false}) async {
    try {
      final image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          if (isLogo) {
            _logoPath = image.path;
          } else {
            _photoPath = image.path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора изображения: $e')),
        );
      }
    }
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
                width: 2.5,
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
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: const Text(
              'Кабинет администратора',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: _buildPersonIcon(),
                  onPressed: () => AuthGuard.openCompanySettings(context),
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
                    // Секция КОМПАНИЯ
                    const Center(
                      child: Text(
                        'КОМПАНИЯ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Отметьте информацию которая будет отображаться в карточке',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildInputFieldWithCheckbox(Icons.edit, 'Название', _checkboxes['Название']!, _controllers['Название']!),
                    _buildInputFieldWithCheckbox(Icons.home, 'Адрес', _checkboxes['Адрес']!, _controllers['Адрес']!),
                    _buildInputFieldWithCheckbox(Icons.mail, 'Mail', _checkboxes['Mail']!, _controllers['Mail']!),
                    _buildInputFieldWithCheckbox(Icons.phone, 'Телефон', _checkboxes['Телефон']!, _controllers['Телефон']!),
                    _buildInputFieldWithCheckbox(Icons.person, 'Имя специалиста', _checkboxes['Имя специалиста']!, _controllers['Имя специалиста']!),
                    _buildInputFieldWithCheckbox(Icons.account_tree, 'Виды деятельности', _checkboxes['Виды деятельности']!, _controllers['Виды деятельности']!),
                    _buildInputFieldWithCheckbox(Icons.language, 'Сайт', _checkboxes['Сайт']!, _controllers['Сайт']!),

                    const SizedBox(height: 24),

                    // Услуги
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Услуги',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addService,
                          tooltip: 'Добавить услугу',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._services.asMap().entries.map((entry) {
                      final index = entry.key;
                      final service = entry.value;
                      return _buildServiceItem(service, index);
                    }),

                    const SizedBox(height: 24),

                    // Рабочие действия по изображениям
                    _buildActionButtons(),

                    const Divider(height: 32, thickness: 1, color: Colors.black),

                    // Рейтинг - список критериев
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Рейтинг',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addRatingCriterion,
                          tooltip: 'Добавить критерий',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Список действий для оценки (пользователи выбирают из этого списка)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ..._ratingCriteria.asMap().entries.map((entry) {
                      final index = entry.key;
                      final criterion = entry.value;
                      return _buildRatingCriterionItem(criterion, index);
                    }),

                    const SizedBox(height: 24),

                    // Соцсети
                    const Text(
                      'Добавить соц сети',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSocialNetworks(),

                    const SizedBox(height: 24),

                    // Цвет карточки
                    const Text(
                      'Отметить цветом карточку компании',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildColorPicker(),

                    const SizedBox(height: 32),

                    _buildLogoutButton(),

              const SizedBox(height: 80), // Отступ для FAB
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: (value) {
              setState(() {
                _checkboxes[label] = value ?? false;
              });
            },
          ),
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const UnderlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton('Фото добавить', Icons.add_photo_alternate, () {
                _pickImage(ImageSource.gallery);
              }),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.attach_file, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton('Фото удалить', Icons.delete, () {
                setState(() {
                  _photoPath = null;
                });
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton('Логотип добавить', Icons.add_photo_alternate, () {
                _pickImage(ImageSource.gallery, isLogo: true);
              }),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.attach_file, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton('Лого удалить', Icons.delete, () {
                setState(() {
                  _logoPath = null;
                });
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Добавить услугу',
                Icons.add_business,
                _addService,
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(width: 20),
            Expanded(
              child: _buildActionButton('Сохранить', Icons.save, _saveSettings),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.blue[800]),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialNetworks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialIcon(Icons.send, Colors.blue, 'Telegram', () {}),
        _buildSocialIcon(Icons.chat_bubble, Colors.blue[700]!, 'VK', () {}),
        _buildSocialIcon(Icons.circle, Colors.orange, 'OK', () {}),
        _buildSocialIcon(Icons.facebook, Colors.blue[800]!, 'Facebook', () {}),
        _buildSocialIcon(Icons.camera_alt, const Color(0xFFE1306C), 'Instagram', () {}),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) {
        final isSelected =
            _selectedCardColor.toARGB32() == color.toARGB32();
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCardColor = color;
            });
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingCriterionItem(String criterion, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            return Icon(
              Icons.star_border,
              color: Colors.amber,
              size: 16,
            );
          }),
        ),
        title: Text(criterion),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editRatingCriterion(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteRatingCriterion(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(String service, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.business),
        title: Text(service),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editService(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteService(index),
            ),
          ],
        ),
      ),
    );
  }

  void _addRatingCriterion() {
    _newRatingCriterionController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить критерий рейтинга'),
        content: TextField(
          controller: _newRatingCriterionController,
          decoration: const InputDecoration(
            hintText: 'Название критерия (например: Качество работы)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final text = _newRatingCriterionController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _ratingCriteria.add(text);
                });
                _saveSettings();
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _editRatingCriterion(int index) {
    _newRatingCriterionController.text = _ratingCriteria[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать критерий'),
        content: TextField(
          controller: _newRatingCriterionController,
          decoration: const InputDecoration(
            hintText: 'Название критерия',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final text = _newRatingCriterionController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _ratingCriteria[index] = text;
                });
                _saveSettings();
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _deleteRatingCriterion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить критерий?'),
        content: Text('Вы уверены, что хотите удалить "${_ratingCriteria[index]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _ratingCriteria.removeAt(index);
              });
              _saveSettings();
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addService() {
    _newServiceController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить услугу'),
        content: TextField(
          controller: _newServiceController,
          decoration: const InputDecoration(
            hintText: 'Название услуги (например: Малярные работы)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final text = _newServiceController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _services.add(text);
                });
                _saveSettings();
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _editService(int index) {
    _newServiceController.text = _services[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать услугу'),
        content: TextField(
          controller: _newServiceController,
          decoration: const InputDecoration(
            hintText: 'Название услуги',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final text = _newServiceController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _services[index] = text;
                });
                _saveSettings();
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _deleteService(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить услугу?'),
        content: Text('Вы уверены, что хотите удалить "${_services[index]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _services.removeAt(index);
              });
              _saveSettings();
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
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
      ..style = PaintingStyle.fill;

    final headRadius = size.width * 0.25;
    canvas.drawCircle(
      Offset(size.width / 2, headRadius),
      headRadius,
      paint,
    );

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
