import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class EnterCodeScreen extends StatefulWidget {
  final String phoneNumber;
  final Function(bool isCompany, bool needsFillData)? onLoginSuccess;

  const EnterCodeScreen({
    super.key,
    required this.phoneNumber,
    this.onLoginSuccess,
  });

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите код подтверждения')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Реальная проверка кода через API
      final result = await AuthService.verifyCode(
        phone: widget.phoneNumber,
        code: _codeController.text.trim(),
      );

      if (!mounted) return;

      if (result != null && result['success'] == true) {
        // Успешная верификация
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!(
            result['isCompany'] == true,
            result['needsFillData'] == true,
          );
        }
      } else {
        // Ошибка верификации
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный код подтверждения')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Введите код'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Код отправлен на номер\n${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Код подтверждения',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Подтвердить'),
            ),
          ],
        ),
      ),
    );
  }
}
