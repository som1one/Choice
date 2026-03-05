import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'company_login_screen.dart';
import '../utils/auth_guard.dart';
import '../navigation/company_tab_navigator.dart';

class CompanyRegistrationScreen extends StatefulWidget {
  final String? email;
  final String? password;

  const CompanyRegistrationScreen({super.key, this.email, this.password});

  @override
  State<CompanyRegistrationScreen> createState() => _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState extends State<CompanyRegistrationScreen> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Влияет на отображение/сохранение данных, но не ломает бек (пока отправляем только существующие поля)
  String _companyType = 'юрлицо';
  
  bool _emailError = false;
  bool _emailValidationError = false;
  bool _weakPasswordError = false;
  bool _passwordsNotMatchedError = false;

  @override
  void initState() {
    super.initState();
    // Заполняем поля переданными данными
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
    if (widget.password != null) {
      _passwordController.text = widget.password!;
      _confirmPasswordController.text = widget.password!;
    }
    
    _companyNameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    _validateFields();
    setState(() {});
  }

  void _validateFields() {
    // Валидация email
    if (_emailController.text.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      _emailValidationError = !emailRegex.hasMatch(_emailController.text);
    } else {
      _emailValidationError = false;
    }

    // Валидация пароля (минимум 6 знаков)
    if (_passwordController.text.isNotEmpty) {
      _weakPasswordError = _passwordController.text.length < 6;
    } else {
      _weakPasswordError = false;
    }

    // Проверка совпадения паролей
    if (_confirmPasswordController.text.isNotEmpty) {
      _passwordsNotMatchedError = _passwordController.text != _confirmPasswordController.text;
    } else {
      _passwordsNotMatchedError = false;
    }
  }

  bool _areAllFieldsFilled() {
    return _companyNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty;
  }

  bool _isFormValid() {
    return _areAllFieldsFilled() &&
        !_emailValidationError &&
        !_weakPasswordError &&
        !_passwordsNotMatchedError;
  }

  @override
  void dispose() {
    _companyNameController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _confirmPasswordController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _companyNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
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
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.check,
                    color: Colors.lightBlue[300],
                    size: 28,
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Омск',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.black,
                  size: 20,
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: _buildPersonIcon(),
                  onPressed: () {
                    AuthGuard.openCompanySettings(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background map
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/images/world_map.jpg'),
                fit: BoxFit.cover,
                opacity: 0.25,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'РЕГИСТРАЦИЯ КОМПАНИИ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.70,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'юрлицо', label: Text('Юрлицо')),
                        ButtonSegment(value: 'физлицо', label: Text('Физлицо')),
                      ],
                      selected: {_companyType},
                      onSelectionChanged: (v) => setState(() => _companyType = v.first),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildTextField(_companyNameController, 'Название компании'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildTextField(_emailController, 'mail'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildTextField(_phoneController, 'Телефон'),
                  ),
                  if (_emailValidationError || _emailError) ...[
                    const SizedBox(height: 5),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.52,
                      child: Text(
                        _emailError ? 'E-mail уже используется' : 'Введите корректный E-mail',
                        style: const TextStyle(
                          color: Color(0xFFE64646),
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildTextField(_passwordController, 'Пароль минимум 6 знаков', isPassword: true),
                  ),
                  if (_weakPasswordError) ...[
                    const SizedBox(height: 5),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.52,
                      child: const Text(
                        'Пароль должен содержать минимум 6 символов',
                        style: TextStyle(
                          color: Color(0xFFE64646),
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildTextField(_confirmPasswordController, 'Повторить пароль', isPassword: true),
                  ),
                  if (_passwordsNotMatchedError) ...[
                    const SizedBox(height: 5),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.52,
                      child: const Text(
                        'Пароли не совпадают',
                        style: TextStyle(
                          color: Color(0xFFE64646),
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildActionButton('Регистрация компании', isEnabled: _isFormValid()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF87CEEB), // Яркий небесно-голубой цвет
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _validateAndRegister() async {
    if (!_isFormValid()) {
      if (!_areAllFieldsFilled()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заполните все поля')),
        );
      } else if (_emailValidationError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите корректный email')),
        );
      } else if (_weakPasswordError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пароль должен содержать минимум 6 символов')),
        );
      } else if (_passwordsNotMatchedError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пароли не совпадают')),
        );
      }
      return;
    }

    setState(() {
      _emailError = false;
    });

    if (!mounted) return;

    try {
      await AuthService.registerCompany(
        companyName: _companyNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : '0000000000',
        companyType: _companyType,
      );
      // Автоматически переходим на главный экран компании после регистрации
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const CompanyTabNavigator()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _emailError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка регистрации. Email уже используется')),
      );
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.thumb_up,
              color: Color(0xFF2D81E0),
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              'Аккаунт компании создан',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Заполните информацию о вашей компании',
              style: TextStyle(
                color: Color(0xFF6D7885),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Закрываем модальное окно
                // Автоматический вход и переход на FillCompanyDataScreen
                final loginSuccess = await AuthService.loginCompany(
                  email: _emailController.text,
                  password: _passwordController.text,
                );
                if (!mounted) return;
                if (loginSuccess) {
                  // TODO: Переход на FillCompanyDataScreen
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => CompanyLoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D81E0),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Ок',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, {bool isEnabled = true}) {
    return GestureDetector(
      onTap: isEnabled ? _validateAndRegister : null,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFF87CEEB) : const Color(0xFFABCDf3),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
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
}

class _PersonIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

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
    final indentWidth = bodyWidth * 0.25; // Ширина выемки
    final indentDepth = bodyHeight * 0.15; // Глубина выемки

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
