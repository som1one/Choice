import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/remote_company_service.dart';
import '../services/auth_service.dart';
import '../services/remote_file_service.dart';
import '../services/api_config.dart';
import '../navigation/company_tab_navigator.dart';

class FillCompanyDataScreen extends StatefulWidget {
  final String email;
  final String password;

  const FillCompanyDataScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<FillCompanyDataScreen> createState() => _FillCompanyDataScreenState();
}

class _FillCompanyDataScreenState extends State<FillCompanyDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _socialMediaController = TextEditingController();
  
  final List<String> _socialMedias = [];
  final List<String> _photoUris = [];
  final List<int> _selectedCategories = [];
  bool _prepaymentAvailable = false;
  bool _isLoading = false;
  
  final ImagePicker _imagePicker = ImagePicker();
  
  // Категории (соответствуют ID из бэкенда)
  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Автоуслуги'},
    {'id': 2, 'name': 'Услуги строителя'},
    {'id': 3, 'name': 'Красота'},
    {'id': 4, 'name': 'Бытовые услуги'},
    {'id': 5, 'name': 'Финансовые услуги'},
    {'id': 6, 'name': 'Парфюм'},
    {'id': 7, 'name': 'Автотовары'},
  ];

  @override
  void dispose() {
    _siteUrlController.dispose();
    _descriptionController.dispose();
    _socialMediaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null && _photoUris.length < 6) {
      // Загружаем изображение на сервер
      if (ApiConfig.isConfigured) {
        try {
          final fileService = RemoteFileService();
          final filename = await fileService.uploadFile(image.path);
          if (filename != null) {
            setState(() {
              _photoUris.add(RemoteFileService.getFileUrl(filename));
            });
          } else {
            // Если загрузка не удалась, используем локальный путь
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Не удалось загрузить файл на сервер')),
              );
            }
            setState(() {
              _photoUris.add(image.path);
            });
          }
        } catch (e) {
          // Обработка ошибок загрузки
          if (mounted) {
            String errorMsg = 'Ошибка при загрузке файла';
            if (e.toString().contains('_Namespace')) {
              errorMsg = 'Ошибка сервера при загрузке файла';
            } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
              errorMsg = 'Проблема с сетью. Файл сохранен локально';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg)),
            );
          }
          // Используем локальный путь в случае ошибки
          setState(() {
            _photoUris.add(image.path);
          });
        }
      } else {
        // Локальное сохранение (для разработки)
        setState(() {
          _photoUris.add(image.path);
        });
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoUris.removeAt(index);
    });
  }

  void _addSocialMedia() {
    final text = _socialMediaController.text.trim();
    if (text.isNotEmpty && !_socialMedias.contains(text)) {
      setState(() {
        _socialMedias.add(text);
        _socialMediaController.clear();
      });
    }
  }

  void _removeSocialMedia(int index) {
    setState(() {
      _socialMedias.removeAt(index);
    });
  }

  void _toggleCategory(int categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одну категорию')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final companyService = RemoteCompanyService();
      final success = await companyService.fillCompanyData({
        'site_url': _siteUrlController.text.trim(),
        'social_medias': _socialMedias,
        'photo_uris': _photoUris,
        'categories_id': _selectedCategories,
        'prepayment_available': _prepaymentAvailable,
        'description': _descriptionController.text.trim(),
      });

      if (success && mounted) {
        // Пользователь уже залогинен после регистрации, просто переходим
        // Проверяем, что токен еще валиден
        final isLoggedIn = await AuthService.isLoggedIn();
        
        if (isLoggedIn && mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const CompanyTabNavigator()),
            (route) => false,
          );
        } else if (mounted) {
          // Если токен истек, пробуем залогиниться заново
          final loginResult = await AuthService.loginUniversal(
            email: widget.email,
            password: widget.password,
          );
          
          if (loginResult != null && mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CompanyTabNavigator()),
              (route) => false,
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Данные сохранены, но сессия истекла. Войдите заново.')),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при сохранении данных')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Ошибка при сохранении данных';
        if (e.toString().contains('All fields should not be empty')) {
          errorMessage = 'Заполните хотя бы одно поле (сайт, соцсети, фото или категории)';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Неверные данные. Проверьте заполненные поля';
        } else if (e.toString().contains('401')) {
          errorMessage = 'Сессия истекла. Войдите заново';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Компания не найдена';
        } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
          errorMessage = 'Проблема с подключением. Проверьте интернет';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
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
          title: const Text('Заполнение данных компании'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Сайт
                      TextFormField(
                        controller: _siteUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Сайт (URL)',
                          hintText: 'https://example.com',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),

                      // Социальные сети
                      const Text(
                        'Социальные сети',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _socialMediaController,
                              decoration: const InputDecoration(
                                hintText: 'Введите ссылку на соцсеть',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addSocialMedia,
                          ),
                        ],
                      ),
                      if (_socialMedias.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _socialMedias.asMap().entries.map((entry) {
                            return Chip(
                              label: Text(entry.value),
                              onDeleted: () => _removeSocialMedia(entry.key),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Категории
                      const Text(
                        'Категории',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategories.contains(category['id']);
                          return FilterChip(
                            label: Text(category['name']),
                            selected: isSelected,
                            onSelected: (_) => _toggleCategory(category['id']),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Фотографии
                      const Text(
                        'Фотографии (максимум 6)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_photoUris.length < 6)
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Добавить фото'),
                        ),
                      const SizedBox(height: 8),
                      if (_photoUris.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _photoUris.asMap().entries.map((entry) {
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      entry.value,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        // Не показываем ошибку в UI, просто иконку
                                        return const Icon(Icons.broken_image, color: Colors.grey);
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    color: Colors.red,
                                    onPressed: () => _removePhoto(entry.key),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),

                      // Описание
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание компании',
                          hintText: 'Расскажите о вашей компании',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                      ),
                      const SizedBox(height: 16),

                      // Предоплата
                      CheckboxListTile(
                        title: const Text('Доступна предоплата'),
                        value: _prepaymentAvailable,
                        onChanged: (value) {
                          setState(() {
                            _prepaymentAvailable = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Кнопка отправки
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitData,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Сохранить и продолжить'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  } 
}
