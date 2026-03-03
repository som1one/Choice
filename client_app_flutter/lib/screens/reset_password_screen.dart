import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'set_new_password_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isCodeSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Введите email';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await AuthService.resetPassword(_emailController.text.trim());
    
    setState(() {
      _isLoading = false;
    });

    if (success) {
      setState(() {
        _isCodeSent = true;
        _errorMessage = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Код отправлен на email')),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Нет аккаунта с таким email';
      });
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Введите код';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final resetToken = await AuthService.verifyPasswordReset(
      _emailController.text.trim(),
      _codeController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (resetToken != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SetNewPasswordScreen(resetToken: resetToken),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Неверный код';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF2688EB), size: 35),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Восстановить пароль',
          style: TextStyle(
            color: Colors.black,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              _isCodeSent
                  ? 'Мы отправили код для сброса пароля на электронную почту: ${_emailController.text}'
                  : 'Введите ваш e-mail (логин), мы отправим на него\nкод для сброса пароля',
              style: const TextStyle(
                color: Color(0xFF181818),
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isCodeSent ? 'Код для сброса пароля' : 'E-mail (логин)',
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF6D7885),
              ),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _isCodeSent ? _codeController : _emailController,
              enabled: !_isLoading,
              keyboardType: _isCodeSent ? TextInputType.number : TextInputType.emailAddress,
              maxLength: _isCodeSent ? 6 : null,
              decoration: InputDecoration(
                hintText: _isCodeSent ? '000-000' : 'Введите E-mail (логин)',
                errorText: _errorMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_isCodeSent ? _verifyCode : _sendCode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _emailController.text.isEmpty && !_isCodeSent
                      ? const Color(0xFFABCDf3)
                      : const Color(0xFF2D81E0),
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
                    : Text(
                        _isCodeSent ? 'Сбросить пароль' : 'Отправить код',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

