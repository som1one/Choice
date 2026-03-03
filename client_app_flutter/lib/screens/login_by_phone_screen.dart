import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'enter_code_screen.dart';

class LoginByPhoneScreen extends StatefulWidget {
  final Function(bool isCompany, bool needsFillData)? onLoginSuccess;

  const LoginByPhoneScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginByPhoneScreen> createState() => _LoginByPhoneScreenState();
}

class _LoginByPhoneScreenState extends State<LoginByPhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  bool _error = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _isPhoneValid {
    final phone = _phoneController.text.trim();
    return phone.isNotEmpty && phone.length >= 10;
  }

  bool get _isCodeValid {
    return _codeController.text.trim().isNotEmpty;
  }

  String _normalizePhone(String phone) {
    // Убираем все кроме цифр
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Если начинается с 8, заменяем на 7
    if (digits.startsWith('8') && digits.length == 11) {
      return '7${digits.substring(1)}';
    }
    // Если начинается с +7 или 7
    if (digits.startsWith('7') && digits.length == 11) {
      return digits;
    }
    // Если 10 цифр, добавляем 7
    if (digits.length == 10) {
      return '7$digits';
    }
    return digits;
  }

  Future<void> _sendCode() async {
    if (!_isPhoneValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = false;
    });

    try {
      final phone = _normalizePhone(_phoneController.text.trim());
      // TODO: Реализовать отправку кода через AuthService
      // final success = await AuthService.loginByPhone(phone);
      
      // Временная заглушка
      await Future.delayed(const Duration(seconds: 1));
      final success = true;

      if (success && mounted) {
        setState(() {
          _codeSent = true;
        });
      } else if (mounted) {
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

  Future<void> _verifyCode() async {
    if (!_isCodeValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = false;
    });

    try {
      final phone = _normalizePhone(_phoneController.text.trim());
      final code = _codeController.text.trim();
      
      // TODO: Реализовать верификацию кода через AuthService
      // final userType = await AuthService.verifyCode(phone, code);
      
      // Временная заглушка - всегда успех
      final success = true;
      final isCompany = false;
      final needsFillData = false;

      if (success && mounted) {
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!(isCompany, needsFillData);
        }
      } else if (mounted) {
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
            if (_codeSent) ...[
              const Text(
                'Код',
                style: TextStyle(
                  color: Color(0xFF6D7885),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Введите код из смс',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_error) ...[
                const SizedBox(height: 5),
                const Text(
                  'Неверный код',
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
                  onPressed: _isCodeValid && !_isLoading ? _verifyCode : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCodeValid && !_isLoading
                        ? const Color(0xFF2D81E0)
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
            ] else ...[
              const Text(
                'Телефон',
                style: TextStyle(
                  color: Color(0xFF6D7885),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+7 (000) 000-00-00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_error) ...[
                const SizedBox(height: 5),
                const Text(
                  'Ошибка при отправке кода',
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
                  onPressed: _isPhoneValid && !_isLoading ? _sendCode : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPhoneValid && !_isLoading
                        ? const Color(0xFF2D81E0)
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
                          'Отправить код',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
