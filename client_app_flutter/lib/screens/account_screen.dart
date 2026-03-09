import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/remote_client_service.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart' as auth;
import '../services/auth_token_store.dart';
import '../utils/auth_guard.dart';
import 'change_password_screen.dart';
import 'welcome_screen.dart';
import 'package:file_picker/file_picker.dart';
import '../services/remote_file_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final RemoteClientService _clientService = RemoteClientService();
  
  bool _isLoading = true;
  bool _hasChanges = false;
  bool _isSaving = false;
  String? _iconUri;
  String? _localIconPath;
  bool _showSuccessModal = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _clientService.getClientProfile();
      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile['name'] ?? '';
          _surnameController.text = profile['surname'] ?? '';
          _emailController.text = profile['email'] ?? '';
          _phoneController.text = profile['phone_number'] ?? '';
          final city = profile['city'] ?? '';
          final street = profile['street'] ?? '';
          _addressController.text = '$city,$street';
          
          final iconUri = profile['icon_uri'];
          if (iconUri != null && iconUri.toString().isNotEmpty) {
            _iconUri = '${ApiConfig.fileBaseUrl}/api/objects/$iconUri';
          }
          
          _hasChanges = false;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки профиля: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null && mounted) {
        // Загружаем изображение на сервер
        final uploadedUri = await _uploadImage(image.path);
        if (uploadedUri != null) {
          // Обновляем иконку через API
          await _clientService.changeIconUri(uploadedUri);
          
          setState(() {
            _localIconPath = image.path;
            _iconUri = '${ApiConfig.fileBaseUrl}/api/objects/$uploadedUri';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выборе фото: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage(String imagePath) async {
    final fileService = RemoteFileService();
    return await fileService.uploadFile(imagePath);
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final addressParts = _addressController.text.split(',');
      final city = addressParts.isNotEmpty ? addressParts[0].trim() : '';
      final street = addressParts.length > 1 ? addressParts[1].trim() : '';

      final result = await _clientService.changeUserData(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        city: city,
        street: street,
      );

      if (result != null && mounted) {
        setState(() {
          _hasChanges = false;
          _showSuccessModal = true;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при сохранении')),
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
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await auth.AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Аккаунт',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),
              // Фото профиля
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _localIconPath != null
                          ? FileImage(File(_localIconPath!))
                          : (_iconUri != null
                              ? NetworkImage(_iconUri!)
                              : null) as ImageProvider?,
                      child: _iconUri == null && _localIconPath == null
                          ? const Icon(Icons.person, size: 40, color: Colors.grey)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _pickImage,
                child: const Text(
                  'Изменить фото',
                  style: TextStyle(
                    color: Color(0xFF2D81E0),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Поля ввода
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Имя'),
                    _buildTextField(_nameController, onChanged: _onFieldChanged),
                    const SizedBox(height: 20),
                    _buildFieldLabel('Фамилия'),
                    _buildTextField(_surnameController, onChanged: _onFieldChanged),
                    const SizedBox(height: 20),
                    _buildFieldLabel('E-mail'),
                    _buildTextField(_emailController, onChanged: _onFieldChanged),
                    const SizedBox(height: 20),
                    _buildFieldLabel('Телефон'),
                    _buildTextField(_phoneController, onChanged: _onFieldChanged),
                    const SizedBox(height: 20),
                    _buildFieldLabel('Адрес'),
                    _buildTextField(_addressController, maxLines: 2, onChanged: _onFieldChanged),
                    const SizedBox(height: 20),
                    // Кнопка "Изменить пароль"
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF001C3D0D),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Изменить пароль',
                          style: TextStyle(
                            color: Color(0xFF2688EB),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Кнопка "Выйти из аккаунта"
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF001C3D0D),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Выйти из аккаунта',
                          style: TextStyle(
                            color: Color(0xFFEB2626),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Кнопка "Сохранить изменения" (показывается только при изменениях)
                    if (_hasChanges) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D81E0),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Сохранить изменения',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Модальное окно успешного сохранения
      bottomSheet: _showSuccessModal
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.thumb_up,
                    color: Color(0xFF2D81E0),
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Изменения сохранены',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showSuccessModal = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D81E0),
                        padding: const EdgeInsets.symmetric(vertical: 15),
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
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6D7885),
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    int maxLines = 1,
    VoidCallback? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      onChanged: (_) => onChanged?.call(),
    );
  }
}
