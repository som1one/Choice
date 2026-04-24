// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'client_view_inquiry_screen.dart';
import '../utils/auth_guard.dart';
import '../models/inquiry_model.dart';
import '../services/inquiry_service.dart';
import '../services/user_profile_service.dart';
import '../services/remote_client_service.dart';
import '../services/auth_service.dart';
import '../services/api_exception.dart';
import '../services/remote_file_service.dart';
import '../widgets/choice_logo_icon.dart';
import '../widgets/profile_corner_icon.dart';

class ServiceQueryScreen extends StatefulWidget {
  final String category;
  
  const ServiceQueryScreen({super.key, this.category = 'автоуслуги'});

  @override
  State<ServiceQueryScreen> createState() => _ServiceQueryScreenState();
}

class _ServiceQueryScreenState extends State<ServiceQueryScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final SpeechToText _speechToText = SpeechToText();
  final RemoteFileService _fileService = RemoteFileService();
  bool _knowPrice = true;
  bool _knowTime = true;
  bool _knowSpecialist = true;
  bool _knowAppointment = true;
  bool _hasText = false;
  bool _isListening = false;
  bool _isSending = false;

  String _clientName = 'Клиент';
  String? _city; // Загружается из API
  String? _attachmentPath;
  Uint8List? _attachmentBytes;

  @override
  void initState() {
    super.initState();
    _questionController.addListener(() {
      setState(() {
        _hasText = _questionController.text.isNotEmpty;
      });
    });
    _loadClientSettings();
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
    
    // Загружаем город из профиля клиента (обязательно)
    final userType = await AuthService.getUserType();
    if (userType == UserType.client) {
      final clientService = RemoteClientService();
      try {
        Map<String, dynamic>? clientProfile;
        for (var attempt = 0; attempt < 5; attempt++) {
          try {
            clientProfile = await clientService.getClientProfile(
              throwOnError: true,
            );
            if (clientProfile != null) {
              break;
            }
          } on ApiException catch (e) {
            if (e.statusCode != 404) {
              rethrow;
            }
          }

          if (attempt < 4) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }

        if (clientProfile != null && mounted) {
          final city = clientProfile['city']?.toString();
          if (city != null && city.isNotEmpty) {
            setState(() {
              _city = city;
            });
          } else {
            // Показываем ошибку только если профиль действительно уже есть.
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Город не указан в профиле. Пожалуйста, заполните данные профиля.'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
      } catch (e) {
        // Не блокируем создание заявки вторичной ошибкой профиля.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка загрузки города: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _attachmentPath = image.path;
      _attachmentBytes = bytes;
    });
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speechToText.stop();
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      return;
    }

    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
        });
      },
    );

    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Голосовой ввод недоступен на этом устройстве')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isListening = true;
    });

    await _speechToText.listen(
      localeId: 'ru_RU',
      onResult: (result) {
        final recognized = result.recognizedWords.trim();
        if (recognized.isEmpty) return;
        _questionController.value = TextEditingValue(
          text: recognized,
          selection: TextSelection.collapsed(offset: recognized.length),
        );
      },
    );
  }

  Future<void> _sendInquiry() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      String? attachmentUrl;
      if (_attachmentPath != null && _attachmentPath!.isNotEmpty) {
        attachmentUrl = await _fileService.uploadFile(_attachmentPath!);
      }

      final inquiry = InquiryModel(
        id: InquiryService.createLocalInquiryId(),
        question: question,
        category: widget.category,
        clientName: _clientName,
        createdAt: DateTime.now(),
        wantsPrice: _knowPrice,
        wantsTime: _knowTime,
        wantsSpecialist: _knowSpecialist,
        wantsAppointmentTime: _knowAppointment,
        attachmentUrl: attachmentUrl,
      );
      await InquiryService.saveInquiry(inquiry);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ClientViewInquiryScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить заявку: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
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
              child: const ChoiceLogoIcon(size: 30),
            ),
            title: Text(
              _city ?? 'Загрузка...',
              style: const TextStyle(
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
                  onPressed: () => AuthGuard.openClientCabinet(context),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E88E5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Row(
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
                                          maxLines: 3,
                                          minLines: 1,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _pickAttachment,
                                        icon: const Icon(
                                          Icons.attach_file,
                                          color: Colors.white,
                                        ),
                                        tooltip: 'Прикрепить фото',
                                      ),
                                      IconButton(
                                        onPressed: _toggleVoiceInput,
                                        icon: Icon(
                                          _isListening ? Icons.mic : Icons.mic_none,
                                          color: _isListening ? Colors.amber : Colors.white,
                                        ),
                                        tooltip: 'Спросить голосом',
                                      ),
                                      GestureDetector(
                                        onTap: _hasText && !_isSending ? _sendInquiry : null,
                                        child: Opacity(
                                          opacity: _hasText && !_isSending ? 1 : 0.5,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: Text(
                                              _isSending ? '...' : 'Отправить',
                                              style: const TextStyle(
                                                color: Color(0xFF1E88E5),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_attachmentBytes != null) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.memory(
                                            _attachmentBytes!,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Expanded(
                                          child: Text(
                                            'Фото будет отправлено вместе с вопросом',
                                            style: TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _attachmentPath = null;
                                              _attachmentBytes = null;
                                            });
                                          },
                                          icon: const Icon(Icons.close, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
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

  Widget _buildPersonIcon() {
    return const ProfileCornerIcon(userType: UserType.client, size: 28);
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
