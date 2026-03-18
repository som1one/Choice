import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _isPhoneValid {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return false;
    
    // Убираем все кроме цифр
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Международные номера могут содержать от 7 до 15 цифр (включая код страны)
    // Российские номера: 10 цифр (без кода страны) или 11 цифр (с кодом 7 или 8)
    // Белорусские и другие международные: от 9 до 15 цифр (с кодом страны)
    
    // Проверяем общую длину (стандарт E.164 для международных номеров)
    if (digits.length < 7 || digits.length > 15) {
      return false;
    }
    
    // Для российских номеров (10 или 11 цифр) - дополнительная проверка
    if (digits.length == 11) {
      // 11 цифр - должен начинаться с 7 или 8
      return digits.startsWith('7') || digits.startsWith('8');
    }
    
    // Для остальных длин (7-10, 12-15) - просто проверяем длину
    return true;
  }

  bool get _isCodeValid {
    return _codeController.text.trim().isNotEmpty;
  }

  String _normalizePhone(String phone) {
    // Убираем все кроме цифр
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Нормализация для российских номеров
    // Если начинается с 8 и 11 цифр, заменяем на 7
    if (digits.startsWith('8') && digits.length == 11) {
      return '7${digits.substring(1)}';
    }
    // Если начинается с 7 и 11 цифр - уже нормализован
    if (digits.startsWith('7') && digits.length == 11) {
      return digits;
    }
    // Если 10 цифр (российский номер без кода страны), добавляем 7
    if (digits.length == 10) {
      return '7$digits';
    }
    
    // Для международных номеров (9-15 цифр) возвращаем как есть
    // Например, белорусский номер +375298062217 -> 375298062217
    if (digits.length >= 9 && digits.length <= 15) {
      return digits;
    }
    
    // Для остальных случаев возвращаем как есть
    return digits;
  }

  Future<void> _sendCode() async {
    if (!_isPhoneValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _normalizePhone(_phoneController.text.trim());
      final success = await AuthService.loginByPhone(phone);

      if (success && mounted) {
        setState(() {
          _codeSent = true;
          _codeController.clear();
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Не удалось отправить код. Проверьте номер и попробуйте снова.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка сети при отправке кода.';
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
      _errorMessage = null;
    });

    try {
      final phone = _normalizePhone(_phoneController.text.trim());
      final code = _codeController.text.trim();
      final result = await AuthService.verifyCode(phone: phone, code: code);
      final success = result?['success'] == true;
      final isCompany = result?['isCompany'] == true;
      final needsFillData = result?['needsFillData'] == true;

      if (success && mounted) {
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!(isCompany, needsFillData);
        }
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Неверный код или код истёк.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка сети при проверке кода.';
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
              if (_errorMessage != null) ...[
                const SizedBox(height: 5),
                Text(
                  _errorMessage!,
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
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _sendCode,
                  child: const Text('Отправить код повторно'),
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
              if (_errorMessage != null) ...[
                const SizedBox(height: 5),
                Text(
                  _errorMessage!,
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
