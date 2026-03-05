import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/auth_guard.dart';
import 'reset_password_screen.dart';

class LoginByEmailScreen extends StatefulWidget {
  final Function(bool isCompany, bool needsFillData)? onLoginSuccess;

  const LoginByEmailScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginByEmailScreen> createState() => _LoginByEmailScreenState();
}

class _LoginByEmailScreenState extends State<LoginByEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _error = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  Future<void> _login() async {
    if (!_isFormValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = false;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Используем универсальный метод входа, который определяет тип пользователя из токена
      final userType = await AuthService.loginUniversal(
        email: email,
        password: password,
      );

      if (userType != null) {
        if (userType == UserType.client) {
          if (widget.onLoginSuccess != null) {
            widget.onLoginSuccess!(false, false);
          }
          return;
        } else if (userType == UserType.company) {
          // TODO: Проверить, заполнены ли данные компании
          final needsFillData = false; // TODO: проверить через UserProfileService
          if (widget.onLoginSuccess != null) {
            widget.onLoginSuccess!(true, needsFillData);
          }
          return;
        } else if (userType == UserType.admin) {
          // Админ - обрабатываем как компанию для совместимости
          if (widget.onLoginSuccess != null) {
            widget.onLoginSuccess!(true, false);
          }
          return;
        }
      }

      // Если не удалось войти
      if (mounted) {
        setState(() {
          _error = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Логин',
              style: TextStyle(
                color: Color(0xFF6D7885),
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Логин',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE64646)),
                ),
                errorText: _error ? null : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 30),
            const Text(
              'Пароль',
              style: TextStyle(
                color: Color(0xFF6D7885),
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Пароль',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE64646)),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_error) ...[
              const SizedBox(height: 5),
              const Text(
                'Пароль или логин неверны',
                style: TextStyle(
                  color: Color(0xFFE64646),
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFormValid && !_isLoading ? _login : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid && !_isLoading
                      ? const Color(0xFF87CEEB)
                      : const Color(0xFFABCDf3),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Войти',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // Кнопка "Забыли логин и пароль"
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResetPasswordScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Забыли логин и пароль',
                  style: TextStyle(
                    color: Color(0xFF2D81E0),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
