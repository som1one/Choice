import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'company_login_screen.dart';
import '../utils/auth_guard.dart';

class CompanyRegistrationScreen extends StatefulWidget {
  final String? email;
  final String? password;

  const CompanyRegistrationScreen({super.key, this.email, this.password});

  @override
  State<CompanyRegistrationScreen> createState() => _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState extends State<CompanyRegistrationScreen> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _innController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController(text: 'Омск');
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _innController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && (digits.startsWith('7') || digits.startsWith('8'))) {
      digits = digits.substring(1);
    }
    return digits;
  }

  bool _isValidPhone(String phone) => RegExp(r'^\d{10}$').hasMatch(_normalizePhone(phone));

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
                  SizedBox(height: 24),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildTextField(_companyNameController, 'Название компании'),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildTextField(_innController, 'ИНН'),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildTextField(_emailController, 'mail'),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildTextField(_phoneController, 'Телефон (10 цифр)'),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildTextField(_cityController, 'Город'),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildTextField(_streetController, 'Улица'),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildTextField(_passwordController, 'Пароль минимум 8 знаков', isPassword: true),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildTextField(_confirmPasswordController, 'Повторите пароль', isPassword: true),
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.52,
                    child: _buildActionButton('Регистрация компании'),
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

  Widget _buildActionButton(String text) {
    return GestureDetector(
      onTap: () async {
        if (_companyNameController.text.trim().isEmpty ||
            _innController.text.trim().isEmpty ||
            _emailController.text.trim().isEmpty ||
            _phoneController.text.trim().isEmpty ||
            _cityController.text.trim().isEmpty ||
            _streetController.text.trim().isEmpty ||
            _passwordController.text.isEmpty ||
            _confirmPasswordController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Заполните все поля')),
          );
          return;
        }
        if (_passwordController.text.length < 8) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пароль должен содержать минимум 8 символов')),
          );
          return;
        }
        if (!_isValidPhone(_phoneController.text)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Телефон: 10 цифр (можно вводить +7/8)')),
          );
          return;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пароли не совпадают')),
          );
          return;
        }
        await AuthService.registerCompany(
          companyName: _companyNameController.text,
          inn: _innController.text,
          email: _emailController.text,
          password: _passwordController.text,
          city: _cityController.text,
          street: _streetController.text,
          phoneNumber: _normalizePhone(_phoneController.text),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Компания зарегистрирована')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CompanyLoginScreen()),
        );
      },
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
        alignment: Alignment.center,
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
