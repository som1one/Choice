import 'package:flutter/material.dart';
import '../services/remote_chat_service.dart';
import '../services/auth_service.dart';

class ChatsScreen extends StatefulWidget {
  final Function(int)? onUnreadCountChanged;

  const ChatsScreen({super.key, this.onUnreadCountChanged});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final RemoteChatService _chatService = RemoteChatService();
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isCompany = false;

  @override
  void initState() {
    super.initState();
    _checkUserType();
    _loadChats();
  }

  Future<void> _checkUserType() async {
    final isCompany = await AuthService.isCompany();
    if (mounted) {
      setState(() {
        _isCompany = isCompany;
      });
    }
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chats = await _chatService.getChats();
      if (mounted) {
        setState(() {
          _chats = chats ?? [];
          _isLoading = false;
        });
        _updateUnreadCount();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshChats() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final chats = await _chatService.getChats();
      if (mounted) {
        setState(() {
          _chats = chats ?? [];
          _isRefreshing = false;
        });
        _updateUnreadCount();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _updateUnreadCount() {
    int unreadCount = 0;
    for (final chat in _chats) {
      final messages = chat['messages'] as List<dynamic>? ?? [];
      for (final msg in messages) {
        if (msg['is_read'] == false || msg['isRead'] == false) {
          unreadCount++;
        }
      }
    }
    widget.onUnreadCountChanged?.call(unreadCount);
  }

  void _openChat(Map<String, dynamic> chat) {
    final userId = chat['guid'] ?? chat['user_id'] ?? '';
    if (userId.isEmpty) return;

    // TODO: Открыть экран чата с конкретным пользователем
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ChatScreen(
    //       userId: userId.toString(),
    //       userName: chat['name'] ?? 'Пользователь',
    //       userIconUri: chat['icon_uri'] ?? chat['iconUri'],
    //     ),
    //   ),
    // ).then((_) {
    //   _loadChats();
    // });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открыть чат с ${chat['name'] ?? 'пользователем'}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshChats,
              child: _chats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isCompany ? 'Нет чатов с клиентами' : 'Нет чатов с компаниями',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _chats.length,
                      itemBuilder: (context, index) {
                        final chat = _chats[index];
                        final userName = chat['name'] ?? 'Пользователь';
                        final userIconUri = chat['icon_uri'] ?? chat['iconUri'];
                        final messages = chat['messages'] as List<dynamic>? ?? [];
                        
                        // Получаем последнее сообщение
                        Map<String, dynamic>? lastMessage;
                        if (messages.isNotEmpty) {
                          lastMessage = messages.last as Map<String, dynamic>?;
                        }
                        
                        // Подсчитываем непрочитанные сообщения
                        int unreadCount = 0;
                        for (final msg in messages) {
                          if (msg['is_read'] == false || msg['isRead'] == false) {
                            unreadCount++;
                          }
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: userIconUri != null
                                ? NetworkImage(userIconUri.toString())
                                : null,
                            child: userIconUri == null
                                ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?')
                                : null,
                          ),
                          title: Text(
                            userName,
                            style: TextStyle(
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: lastMessage != null
                              ? Text(
                                  lastMessage['text'] ?? lastMessage['body'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: unreadCount > 0
                              ? Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () => _openChat(chat),
                        );
                      },
                    ),
            ),
    );
  }
}
