// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'map_search_screen.dart';
import 'client_view_inquiry_screen.dart';
import 'client_admin_cabinet_screen.dart';
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import '../services/user_profile_service.dart';

class ServiceQueryScreen extends StatefulWidget {
  final String category;
  
  const ServiceQueryScreen({super.key, this.category = 'автоуслуги'});

  @override
  State<ServiceQueryScreen> createState() => _ServiceQueryScreenState();
}

class _ServiceQueryScreenState extends State<ServiceQueryScreen> {
  final TextEditingController _questionController = TextEditingController();
  bool _knowPrice = true;
  bool _knowTime = true;
  bool _knowSpecialist = true;
  bool _knowAppointment = true;
  bool _hasText = false;
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String? _attachmentPath;
  final ImagePicker _imagePicker = ImagePicker();
  String _clientName = 'Клиент';

  @override
  void initState() {
    super.initState();
    _questionController.addListener(() {
      setState(() {
        _hasText = _questionController.text.isNotEmpty;
      });
    });
    _loadClientSettings();
    _initializeSpeech();
  }

  Future<void> _loadClientSettings() async {
    final profile = await UserProfileService.getProfile();
    if (!mounted || profile == null) return;
    setState(() {
      _clientName = profile.fullName?.isNotEmpty == true ? profile.fullName! : 'Клиент';
      _knowPrice = profile.askPrice;
      _knowSpecialist = profile.askSpecialist;
      _knowAppointment = profile.askAppointmentTime;
      _knowTime = profile.askWorkTime;
    });
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        setState(() {
          _isListening = status == 'listening';
        });
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка распознавания речи: ${error.errorMsg}')),
        );
      },
    );
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Голосовой ввод недоступен')),
      );
    }
  }

  Future<void> _attachFile() async {
    try {
      // Запрашиваем разрешение на доступ к файлам только для мобильных платформ
      bool isMobile = false;
      try {
        isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      } catch (e) {
        // Если Platform недоступен, продолжаем без проверки разрешений
        isMobile = false;
      }

      if (isMobile) {
        try {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Необходимо разрешение на доступ к файлам')),
            );
            return;
          }
        } catch (e) {
          // Игнорируем ошибки разрешений на платформах, где они не нужны
        }
      }

      // Показываем диалог выбора типа файла
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Выберите тип файла'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMobile) ...[
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Фото из галереи'),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Сделать фото'),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
              ],
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Выбрать файл'),
                onTap: () => Navigator.pop(context, 'file'),
              ),
            ],
          ),
        ),
      );

      if (result == null) return;

      if (result == 'gallery' || result == 'camera') {
        // Выбор изображения (только для мобильных платформ)
        if (!isMobile) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Выбор фото доступен только на мобильных устройствах')),
          );
          return;
        }
        
        try {
          final XFile? image = await _imagePicker.pickImage(
            source: result == 'gallery' ? ImageSource.gallery : ImageSource.camera,
          );
          
          if (image != null) {
            setState(() {
              _attachmentPath = image.path;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Фото прикреплено: ${image.name}')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при выборе фото: $e')),
          );
        }
      } else if (result == 'file') {
        // Выбор файла (работает на всех платформах)
        try {
          FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
            type: FileType.any,
          );
          
          if (fileResult != null && fileResult.files.single.path != null) {
            setState(() {
              _attachmentPath = fileResult.files.single.path;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Файл прикреплен: ${fileResult.files.single.name}')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при выборе файла: $e')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при прикреплении файла: $e')),
      );
    }
  }

  Future<void> _startListening() async {
    if (_isListening) {
      await _speech.stop();
      return;
    }

    // Запрашиваем разрешение на микрофон только для мобильных платформ
    bool isMobile = false;
    try {
      isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    } catch (e) {
      // Если Platform недоступен, продолжаем без проверки разрешений
      isMobile = false;
    }

    if (isMobile) {
      try {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Необходимо разрешение на использование микрофона')),
          );
          return;
        }
      } catch (e) {
        // Игнорируем ошибки разрешений на платформах, где они не нужны
      }
    }

    bool available = await _speech.initialize();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Голосовой ввод недоступен')),
      );
      return;
    }

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _questionController.text = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'ru_RU',
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _speech.stop();
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
              child: Icon(
                Icons.favorite,
                color: Colors.lightBlue[300],
                size: 28,
              ),
            ),
            title: const Text(
              'Омск',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: _buildPersonIcon(),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClientAdminCabinetScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Белый фон
          Container(
            color: Colors.white,
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ваш выбор - ${widget.category.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                // Большой светло-голубой контейнер с картой
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Карта мира внутри контейнера
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/world_map.jpg'),
                                fit: BoxFit.cover,
                                opacity: 0.3,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                          ),
                        ),
                        // Контент поверх карты - по центру
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            // Темно-синяя полоса с текстом и иконками
                            GestureDetector(
                              onTap: () {
                                // Фокус на поле ввода
                                FocusScope.of(context).requestFocus(FocusNode());
                                Future.delayed(Duration(milliseconds: 100), () {
                                  FocusScope.of(context).requestFocus(FocusNode());
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E88E5), // Темно-синий цвет
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _questionController,
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                        decoration: const InputDecoration(
                                          hintText: 'Задайте вопрос в развернутом виде',
                                          hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (_hasText)
                                      GestureDetector(
                                        onTap: () async {
                                          if (_questionController.text.isNotEmpty) {
                                            // Сохранить запрос
                                            final inquiry = InquiryModel(
                                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                                              question: _questionController.text,
                                              category: widget.category,
                                              clientName: _clientName,
                                              createdAt: DateTime.now(),
                                              wantsPrice: _knowPrice,
                                              wantsTime: _knowTime,
                                              wantsSpecialist: _knowSpecialist,
                                              wantsAppointmentTime: _knowAppointment,
                                              attachmentUrl: _attachmentPath,
                                            );
                                            await InquiryService.saveInquiry(inquiry);
                                            
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ClientViewInquiryScreen(),
                                              ),
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: const Text(
                                            'Отправить',
                                            style: TextStyle(
                                              color: Color(0xFF1E88E5),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: _attachFile,
                                            child: const Icon(Icons.attach_file, color: Colors.white, size: 20),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: _startListening,
                                            child: Icon(
                                              Icons.mic,
                                              color: _isListening ? Colors.red : Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Список опций с зелеными галочками
                            _buildCheckbox('Узнать цену', _knowPrice, (value) {
                              setState(() {
                                _knowPrice = value ?? true;
                              });
                            }),
                            _buildCheckbox('Узнать время выполнения работ', _knowTime, (value) {
                              setState(() {
                                _knowTime = value ?? true;
                              });
                            }),
                            _buildCheckbox('Узнать имя специалиста', _knowSpecialist, (value) {
                              setState(() {
                                _knowSpecialist = value ?? true;
                              });
                            }),
                            _buildCheckbox('Узнать время записи', _knowAppointment, (value) {
                              setState(() {
                                _knowAppointment = value ?? true;
                              });
                            }),
                          ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Кнопки внизу
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildButton(
                        context,
                        'Выбрать услуги или товар',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MapSearchScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildButton(
                        context,
                        'Задать вопрос',
                        () async {
                          if (_questionController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Введите вопрос')),
                            );
                            return;
                          }
                          // Сохранить запрос
                          final inquiry = InquiryModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            question: _questionController.text,
                            category: widget.category,
                            clientName: _clientName,
                            createdAt: DateTime.now(),
                            wantsPrice: _knowPrice,
                            wantsTime: _knowTime,
                            wantsSpecialist: _knowSpecialist,
                            wantsAppointmentTime: _knowAppointment,
                            attachmentUrl: _attachmentPath,
                          );
                          await InquiryService.saveInquiry(inquiry);
                          
                          // Переход на экран просмотра запроса клиента
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClientViewInquiryScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String text, bool checked, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () {
          onChanged(!checked);
        },
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: checked ? Colors.green : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF87CEEB),
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
            fontSize: 13,
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
