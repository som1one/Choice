import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/remote_chat_service.dart';
import '../services/websocket_chat_service.dart';
import '../services/api_config.dart';
import '../services/auth_token_store.dart';
import '../services/auth_service.dart';
import '../services/remote_review_service.dart';
import 'image_viewer_screen.dart';
import 'dart:convert';
import 'dart:typed_data';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userIconUri;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userIconUri,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final RemoteChatService _chatService = RemoteChatService();
  final WebSocketChatService _wsService = WebSocketChatService();
  final RemoteReviewService _reviewService = RemoteReviewService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isSendingImage = false;
  String? _currentUserId;
  UserType? _userType;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadUserType();
    _loadMessages();
    _connectWebSocket();
  }

  /// Загрузка типа пользователя
  Future<void> _loadUserType() async {
    final userType = await AuthService.getUserType();
    setState(() {
      _userType = userType;
    });
  }

  /// Загрузка текущего ID пользователя из токена
  Future<void> _loadCurrentUserId() async {
    try {
      final token = await AuthTokenStore.getToken();
      if (token != null) {
        // Декодируем JWT токен для получения user ID
        final parts = token.split('.');
        if (parts.length >= 2) {
          final payload = parts[1];
          // Добавляем padding если нужно
          String normalized = payload;
          switch (payload.length % 4) {
            case 1:
              normalized += '===';
              break;
            case 2:
              normalized += '==';
              break;
            case 3:
              normalized += '=';
              break;
          }
          try {
            // Декодируем base64Url
            Uint8List bytes;
            try {
              bytes = base64Url.decode(normalized);
            } catch (_) {
              // Пробуем обычный base64
              bytes = base64Decode(normalized);
            }
            final decoded = utf8.decode(bytes);
            final json = jsonDecode(decoded) as Map<String, dynamic>;
            _currentUserId = json['id']?.toString();
          } catch (_) {
            // Если не удалось декодировать, оставляем null
          }
        }
      }
    } catch (_) {
      // Игнорируем ошибки
    }
  }

  @override
  void dispose() {
    _disconnectWebSocket();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Подключение к WebSocket для real-time обновлений
  Future<void> _connectWebSocket() async {
    if (!ApiConfig.isConfigured) return;

    try {
      // Подписываемся на новые сообщения
      _wsService.onMessage((message) {
        if (!mounted) return;

        final receiverId = (message['receiver_id'] ?? message['receiverId'])
            ?.toString();
        final senderId = (message['sender_id'] ?? message['senderId'])
            ?.toString();
        final currentUserIdStr = _currentUserId?.toString();
        final widgetUserIdStr = widget.userId.toString();

        // Добавляем сообщение только если оно для текущего чата
        // Сравниваем как строки, так как это могут быть UUID
        if ((receiverId != null &&
                (receiverId == currentUserIdStr ||
                    receiverId == widgetUserIdStr)) ||
            (senderId != null &&
                (senderId == currentUserIdStr ||
                    senderId == widgetUserIdStr))) {
          setState(() {
            // Проверяем, нет ли уже такого сообщения (по ID)
            final messageId = message['id'];
            if (messageId != null) {
              final exists = _messages.any((m) => m['id'] == messageId);
              if (!exists) {
                _messages.add(message);
              }
            } else {
              _messages.add(message);
            }
          });
          _scrollToBottom();
        }
      });

      // Подписываемся на события заказов (enrollmentDateChanged, enrolled, confirmed, statusChanged)
      _wsService.onOrderEvent((orderEvent) {
        if (!mounted) return;

        final eventType = orderEvent['type'] as String?;
        final orderId = orderEvent['order_id'] ?? orderEvent['orderId'];
        final clientId = orderEvent['client_id'] ?? orderEvent['clientId'];
        final companyId = orderEvent['company_id'] ?? orderEvent['companyId'];

        // Проверяем, относится ли событие к текущему чату
        if (clientId == widget.userId || companyId == widget.userId) {
          // Обновляем сообщения, связанные с заказом
          setState(() {
            // Ищем сообщения, связанные с этим заказом
            for (int i = 0; i < _messages.length; i++) {
              final msg = _messages[i];
              final body = msg['body'] ?? msg['text'];

              // Если сообщение содержит JSON с OrderId, обновляем его
              if (body != null) {
                try {
                  final bodyJson = jsonDecode(body.toString());
                  final msgOrderId =
                      bodyJson['OrderId'] ??
                      bodyJson['order_id'] ??
                      bodyJson['orderId'];

                  if (msgOrderId == orderId) {
                    // Обновляем данные заказа в сообщении
                    if (eventType == 'enrollmentDateChanged') {
                      bodyJson['EnrollmentDate'] =
                          orderEvent['enrollment_date'] ??
                          orderEvent['enrollmentDate'];
                      bodyJson['IsDateConfirmed'] = false;
                    } else if (eventType == 'enrolled') {
                      bodyJson['IsEnrolled'] = true;
                    } else if (eventType == 'confirmed') {
                      bodyJson['IsDateConfirmed'] = true;
                    } else if (eventType == 'statusChanged') {
                      bodyJson['Status'] =
                          orderEvent['status'] ?? orderEvent['Status'];
                    }

                    _messages[i] = {...msg, 'body': jsonEncode(bodyJson)};
                  }
                } catch (_) {
                  // Если не удалось распарсить, пропускаем
                }
              }
            }
          });
        }
      });

      // Подключаемся к WebSocket
      await _wsService.connect();
    } catch (e) {
      // Если WebSocket недоступен, продолжаем работу через REST API
      // Игнорируем, чат продолжит работать через REST.
    }
  }

  /// Отключение от WebSocket
  Future<void> _disconnectWebSocket() async {
    await _wsService.disconnect();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await _chatService.getMessages(widget.userId);
      if (!mounted) return;

      setState(() {
        _messages = messages ?? [];
        _isLoading = false;
      });

      // Отмечаем непрочитанные сообщения как прочитанные
      for (final msg in _messages) {
        final isRead = msg['is_read'] == true || msg['isRead'] == true;
        final id = msg['id'] as int?;
        if (!isRead && id != null) {
          _chatService.readMessage(id);
        }
      }

      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Отправляем через REST API (бэкенд отправляет через WebSocket автоматически)
      // WebSocket используется только для получения сообщений в real-time
      await _sendMessageViaRest(text);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  /// Отправка сообщения через REST API
  /// Бэкенд автоматически отправляет сообщение через WebSocket получателю
  Future<void> _sendMessageViaRest(String text) async {
    try {
      final result = await _chatService.sendMessage(
        text: text,
        receiverId: widget.userId,
      );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          // Добавляем отправленное сообщение в список
          // (оно также придет через WebSocket, но мы добавим его сразу для оптимистичного обновления)
          final messageId = result['id'];
          final exists =
              messageId != null && _messages.any((m) => m['id'] == messageId);
          if (!exists) {
            _messages.add(result);
          }
          _messageController.clear();
        });
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сообщение не отправлено: ошибка сервера'),
          ),
        );
      }
    } catch (e) {
      // Ошибка отправки - показываем уведомление
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка отправки сообщения')),
        );
      }
    }
  }

  /// Выбор и отправка изображения
  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isSendingImage = true;
      });

      // Отправляем изображение
      final result = await _chatService.sendImage(
        imagePath: image.path,
        receiverId: widget.userId,
      );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          final messageId = result['id'];
          final exists =
              messageId != null && _messages.any((m) => m['id'] == messageId);
          if (!exists) {
            _messages.add(result);
          }
        });
        _scrollToBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка отправки изображения')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка выбора изображения')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingImage = false;
        });
      }
    }
  }

  /// Отправка отзыва
  Future<void> _sendReview({
    required int grade,
    String? text,
    List<String>? photoUris,
  }) async {
    try {
      final result = await _reviewService.sendReview(
        guid: widget.userId,
        grade: grade,
        text: text,
        photoUris: photoUris,
      );

      if (!mounted) return;

      if (result != null && result['error'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отзыв успешно отправлен')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result?['error']?.toString() ?? 'Невозможно оставить отзыв',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка отправки отзыва')));
      }
    }
  }

  /// Показать диалог отправки отзыва
  void _showReviewDialog() {
    int grade = 5;
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Оставить отзыв'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Оценка: $grade'),
              Slider(
                value: grade.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: grade.toString(),
                onChanged: (value) {
                  setDialogState(() {
                    grade = value.toInt();
                  });
                },
              ),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Текст отзыва (необязательно)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _sendReview(
                  grade: grade,
                  text: textController.text.trim().isEmpty
                      ? null
                      : textController.text.trim(),
                );
              },
              child: const Text('Отправить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.userIconUri != null
                  ? NetworkImage(widget.userIconUri!)
                  : null,
              child: widget.userIconUri == null
                  ? Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.userName, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(child: Text('Нет сообщений'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final messageType =
                          msg['message_type'] ?? msg['messageType'];
                      final text =
                          msg['text'] ?? msg['body'] ?? msg['message'] ?? '';

                      // Определяем, наше ли это сообщение
                      // Сравниваем как строки, так как это могут быть UUID
                      final senderId = (msg['sender_id'] ?? msg['senderId'])
                          ?.toString();
                      final currentUserIdStr = _currentUserId?.toString();
                      final isMineBySender =
                          currentUserIdStr != null &&
                          senderId != null &&
                          senderId == currentUserIdStr;
                      final isMine =
                          isMineBySender ||
                          msg['is_mine'] == true ||
                          msg['isMine'] == true;

                      // Проверяем, является ли сообщение изображением
                      final messageTypeNormalized = messageType
                          ?.toString()
                          .toLowerCase();
                      final isImageMessage =
                          messageType == 2 ||
                          messageTypeNormalized == 'image' ||
                          messageTypeNormalized == '2';

                      if (isImageMessage) {
                        final imageUri = text.toString();
                        return Align(
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImageViewerScreen(
                                    imageUrls: [imageUri],
                                    initialIndex: 0,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              constraints: const BoxConstraints(
                                maxWidth: 250,
                                maxHeight: 300,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isMine
                                      ? const Color(0xFF87CEEB)
                                      : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUri,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      child: const Icon(Icons.broken_image),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          child:
                                              const CircularProgressIndicator(),
                                        );
                                      },
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      // Проверяем, является ли сообщение заказом
                      try {
                        final bodyJson = jsonDecode(text.toString());
                        if (bodyJson is Map &&
                            bodyJson.containsKey('OrderId')) {
                          return _buildOrderMessage(
                            msg,
                            Map<String, dynamic>.from(bodyJson),
                            isMine,
                          );
                        }
                      } catch (_) {
                        // Не заказ, обычное текстовое сообщение
                      }

                      // Обычное текстовое сообщение
                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? const Color(0xFF87CEEB)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            text.toString(),
                            style: TextStyle(
                              color: isMine ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: _isSendingImage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.image, color: Color(0xFF2D81E0)),
                    onPressed: _isSendingImage ? null : _pickAndSendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Напишите сообщение...',
                        border: InputBorder.none,
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: Color(0xFF2D81E0)),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          (_userType == UserType.client || _userType == UserType.company)
          ? FutureBuilder<bool>(
              future: _reviewService.canSendReview(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return FloatingActionButton(
                    onPressed: _showReviewDialog,
                    backgroundColor: const Color(0xFF2D81E0),
                    child: const Icon(Icons.star, color: Colors.white),
                    tooltip: 'Оставить отзыв',
                  );
                }
                return const SizedBox.shrink();
              },
            )
          : null,
    );
  }

  /// Построить виджет сообщения с заказом
  Widget _buildOrderMessage(
    Map<String, dynamic> msg,
    Map<String, dynamic> orderData,
    bool isMine,
  ) {
    final orderId = orderData['OrderId'] ?? orderData['order_id'];
    final price = orderData['Price'] ?? orderData['price'] ?? 0;
    final deadline = orderData['Deadline'] ?? orderData['deadline'] ?? 0;
    final enrollmentTime =
        orderData['EnrollmentTime'] ?? orderData['enrollment_time'];
    final isEnrolled =
        orderData['IsEnrolled'] ?? orderData['is_enrolled'] ?? false;
    final status = orderData['Status'] ?? orderData['status'] ?? 1;
    final isDateConfirmed =
        isEnrolled ||
        orderData['IsDateConfirmed'] == true ||
        orderData['is_date_confirmed'] == true;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB5CADD), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _userType == UserType.client
                  ? 'Ответ компании на ваш запрос'
                  : 'Ваш ответ на заказ клиента',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            if (price > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$price рублей',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (deadline > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Срок: $deadline дней',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            if (enrollmentTime != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Дата: ${_formatDateTime(enrollmentTime)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDateConfirmed ? Colors.black : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 2) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Заказ завершен',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Форматирование даты и времени
  String _formatDateTime(dynamic dateTime) {
    try {
      if (dateTime is String) {
        final dt = DateTime.parse(dateTime);
        return '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return dateTime.toString();
    } catch (_) {
      return dateTime.toString();
    }
  }
}
