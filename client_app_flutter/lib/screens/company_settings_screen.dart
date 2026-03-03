import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/remote_company_service.dart';
import '../services/api_config.dart';
import 'company_login_screen.dart';
import 'welcome_screen.dart';
import 'chats_screen.dart';
import 'company_admin_cabinet_screen.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
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
    'Логин': TextEditingController(),
    'Пароль': TextEditingController(),
  };
  String? _logoPath;
  final ImagePicker _picker = ImagePicker();
  bool _isAdmin = false;
  bool _isLoading = true;
  final RemoteCompanyService _companyService = RemoteCompanyService();

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
    final ok = loggedIn && (userType == UserType.company || userType == UserType.admin);

    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала войдите как компания')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CompanyLoginScreen()),
        (route) => false,
      );
      return;
    }

    setState(() {
      _isAdmin = userType == UserType.admin;
    });

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
    setState(() {
      _isLoading = true;
    });

    try {
      // Загружаем данные из API
      final profile = await _companyService.getCompanyProfile();
      
      // Загружаем сохраненные настройки из SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('company_settings');
      Map<String, dynamic> savedData = {};
      if (raw != null) {
        savedData = jsonDecode(raw) as Map<String, dynamic>;
      }

      if (!mounted) return;

      setState(() {
        // Сначала загружаем данные из API профиля (если есть)
        if (profile != null) {
          final title = profile['title']?.toString() ?? '';
          final email = profile['email']?.toString() ?? '';
          final phone = profile['phone_number']?.toString() ?? '';
          
          if (title.isNotEmpty) _controllers['Название']!.text = title;
          if (email.isNotEmpty) _controllers['Mail']!.text = email;
          if (phone.isNotEmpty) _controllers['Телефон']!.text = phone;
          
          // Адрес из API
          final address = profile['address'];
          if (address is Map<String, dynamic>) {
            final city = address['city']?.toString() ?? '';
            final street = address['street']?.toString() ?? '';
            if (city.isNotEmpty || street.isNotEmpty) {
              _controllers['Адрес']!.text = [city, street].where((s) => s.isNotEmpty).join(', ');
            }
          }
          
          final siteUrl = profile['site_url']?.toString() ?? '';
          final specialistName = profile['specialist_name']?.toString() ?? '';
          final activities = profile['activities']?.toString() ?? '';
          
          if (siteUrl.isNotEmpty) _controllers['Сайт']!.text = siteUrl;
          if (specialistName.isNotEmpty) _controllers['Имя специалиста']!.text = specialistName;
          if (activities.isNotEmpty) _controllers['Виды деятельности']!.text = activities;
          
          // Логотип из API
          final iconUri = profile['icon_uri'];
          if (iconUri != null && iconUri.toString().isNotEmpty) {
            _logoPath = '${ApiConfig.fileBaseUrl}/api/objects/$iconUri';
          }
        }
        
        // Затем загружаем из сохраненных настроек (для полей, которые не заполнены из API)
        _logoPath = savedData['logoPath'] as String? ?? _logoPath;
        for (final key in _checkboxes.keys) {
          _checkboxes[key] = savedData['cb_$key'] as bool? ?? _checkboxes[key]!;
        }
        for (final key in _controllers.keys) {
          final savedValue = savedData['f_$key'] as String?;
          // Заполняем только если поле пустое (данные из регистрации как fallback)
          if (savedValue != null && savedValue.isNotEmpty && _controllers[key]!.text.isEmpty) {
            _controllers[key]!.text = savedValue;
          }
        }
        
        _isLoading = false;
      });
    } catch (e) {
      // Если API недоступен, загружаем только из SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('company_settings');
      if (raw != null && mounted) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        setState(() {
          _logoPath = data['logoPath'] as String?;
          for (final key in _checkboxes.keys) {
            _checkboxes[key] = data['cb_$key'] as bool? ?? _checkboxes[key]!;
          }
          for (final key in _controllers.keys) {
            final savedValue = data['f_$key'] as String?;
            if (savedValue != null && savedValue.isNotEmpty) {
              _controllers[key]!.text = savedValue;
            }
          }
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{'logoPath': _logoPath};
    for (final entry in _checkboxes.entries) {
      data['cb_${entry.key}'] = entry.value;
    }
    for (final entry in _controllers.entries) {
      data['f_${entry.key}'] = entry.value.text.trim();
    }
    await prefs.setString('company_settings', jsonEncode(data));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки компании сохранены')),
    );
  }

  Future<void> _pickLogo() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _logoPath = image.path;
    });
    await _saveSettings();
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: const Text(
                        'Инструкция для компании',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Контент с прокруткой
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _InstructionItem(
                        number: '1',
                        title: 'Регистрация',
                        content: 'Для использования приложения необходимо зарегистрироваться. '
                            'При регистрации требуется логин (электронная почта) и пароль (не менее 6 символов).',
                      ),
                      SizedBox(height: 16),
                      _InstructionItem(
                        number: '2',
                        title: 'Личный кабинет',
                        icon: Icons.person,
                        content: '• Создание карточки компании\n'
                            '• Управление паролем\n'
                            '• Создание предоплаты',
                      ),
                      SizedBox(height: 16),
                      _InstructionItem(
                        number: '3',
                        title: 'Соцсети',
                        content: 'Внизу окна можно выбрать иконки соцсетей, чтобы добавить '
                            'социальную сеть компании в карточку компании.',
                      ),
                      SizedBox(height: 16),
                      _InstructionItem(
                        number: '4',
                        title: 'Отображение на карте',
                        content: 'Компания будет отображаться на карте по адресу, указанному в настройках. '
                            'На карте будет отображаться логотип компании и рейтинг.',
                      ),
                      SizedBox(height: 16),
                      _InstructionItem(
                        number: '5',
                        title: 'Рейтинг',
                        content: 'Рейтинг появляется после диалога клиента с компанией. '
                            'На карте отображается общий рейтинг клиента (клиент может не ставить оценку).',
                      ),
                      SizedBox(height: 16),
                      _InstructionItem(
                        number: '6',
                        title: 'Диалог с клиентом',
                        content: 'Клиент запрашивает услугу/товар и отмечает важные вопросы. '
                            'Компания получает уведомление (звук, отметка) и должна быстро ответить. '
                            'Ответ компании будет отображаться на карте в виде: логотип, цена, сроки, рейтинг '
                            '(для товара: цена и наличие).',
                      ),
                      SizedBox(height: 16),
                      _InstructionItem(
                        number: '7',
                        title: 'Выбор клиента',
                        content: 'Ответы компаний отображаются на карте. Клиент может выбрать компанию, '
                            'открыть карточку компании, посмотреть фото, перейти в соцсети, написать отзыв и поставить оценку. '
                            'Компания также может оценить клиента после выполнения услуги или продажи товара, '
                            'а также видеть рейтинг клиента во время общения.',
                      ),
                      SizedBox(height: 16),
                      _InstructionItem(
                        number: '8',
                        title: 'Предоплата',
                        content: 'Компания получает предоплату на карту или счет. '
                            'Если компания не хочет работать с предоплатой, не нужно нажимать кнопку '
                            '"работа с предоплатой". Предоплату можно отменить.',
                      ),
                      SizedBox(height: 16),
                      _InstructionItem(
                        number: '9',
                        title: 'Кнопка чат с клиентом',
                        content: 'Компания может просмотреть переписку с клиентом через эту кнопку.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
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
              'НАСТРОЙКИ КОМПАНИИ',
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
                      const SnackBar(content: Text('Вы уже в настройках компании')),
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
                'Отметьте информацию которая будет отображаться в карточке компании',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              
              _buildInputFieldWithCheckbox(Icons.edit, 'Название', _checkboxes['Название']!, _controllers['Название']!),
              _buildInputFieldWithCheckbox(Icons.home, 'Адрес', _checkboxes['Адрес']!, _controllers['Адрес']!),
              _buildInputFieldWithCheckbox(Icons.mail, 'Mail', _checkboxes['Mail']!, _controllers['Mail']!),
              _buildInputFieldWithCheckbox(Icons.phone, 'Телефон', _checkboxes['Телефон']!, _controllers['Телефон']!),
              _buildInputFieldWithCheckbox(Icons.person, 'Имя специалиста', _checkboxes['Имя специалиста']!, _controllers['Имя специалиста']!),
              _buildInputFieldWithCheckbox(Icons.account_tree, 'Виды деятельности', _checkboxes['Виды деятельности']!, _controllers['Виды деятельности']!),
              _buildInputFieldWithCheckbox(Icons.language, 'Сайт', _checkboxes['Сайт']!, _controllers['Сайт']!),
              
              const SizedBox(height: 12),
              _buildAddPhotoField(),

              const Divider(height: 32, thickness: 1, color: Colors.black),

              _buildTextFieldWithIcon(Icons.settings, 'Логин', _controllers['Логин']!),
              const SizedBox(height: 12),
              _buildTextField('Пароль', _controllers['Пароль']!, obscure: true),
              const SizedBox(height: 12),
              _buildLogoField(),

              const Divider(height: 32, thickness: 1, color: Colors.black),

              Row(
                children: [
                  Icon(Icons.monetization_on, size: 24, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  const Text('Деньги', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPrepaymentButton('Настроить прием предоплаты'),
                  ),
                  const SizedBox(width: 8),
                  _buildRoundPrepaymentButton('Работа с предоплатой'),
                  const SizedBox(width: 8),
                  _buildRoundPrepaymentButton('Отмена предоплаты'),
                ],
              ),

              const SizedBox(height: 20),

              _buildPrepaymentButton('Чат с клиентом', onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatsScreen()),
                );
              }),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSocialIcon(Icons.share, Colors.purple),
                  _buildSocialIcon(Icons.message, Colors.green),
                  _buildSocialIcon(Icons.telegram, Colors.blue),
                  _buildSocialIcon(Icons.circle, Colors.orange), // OK
                  _buildSocialIcon(Icons.play_circle_filled, Colors.red), // YouTube
                  _buildSocialIcon(Icons.facebook, Colors.blue),
                  _buildSocialIcon(Icons.circle, Colors.blue[900]!), // VK
                ],
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _buildPrepaymentButton(
                      'Инструкция приложения',
                      onTap: _showInstructions,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.purple[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit, color: Colors.purple[800]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPrepaymentButton('Сохранить настройки', onTap: _saveSettings),
              
              // Кнопка для администратора
              if (_isAdmin) ...[
                const SizedBox(height: 24),
                _buildPrepaymentButton(
                  'Кабинет администратора',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CompanyAdminCabinetScreen(),
                      ),
                    );
                  },
                ),
              ],
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

  Widget _buildAddPhotoField() {
    return GestureDetector(
      onTap: _pickLogo,
      child: Row(
        children: [
          Icon(Icons.camera_alt, size: 24, color: Colors.grey[700]),
          const SizedBox(width: 12),
          const Text('Добавить фото', style: TextStyle(fontSize: 15)),
          const Spacer(),
          Icon(
            _logoPath == null ? Icons.attach_file : Icons.check_circle,
            size: 24,
            color: _logoPath == null ? Colors.grey[700] : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldWithIcon(
    IconData icon,
    String label,
    TextEditingController controller,
  ) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              isDense: true,
              border: UnderlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return Row(
      children: [
        const SizedBox(width: 36),
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: const InputDecoration(
              isDense: true,
              border: UnderlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoField() {
    return Row(
      children: [
        const SizedBox(width: 36),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[400]!, width: 2),
          ),
        ),
        const SizedBox(width: 12),
        const Text('Логотип компании', style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildPrepaymentButton(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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

  Widget _buildRoundPrepaymentButton(String text) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.lightBlue[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text.split(' ').first,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
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

class _InstructionItem extends StatelessWidget {
  final String number;
  final String title;
  final String content;
  final IconData? icon;

  const _InstructionItem({
    required this.number,
    required this.title,
    required this.content,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
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
