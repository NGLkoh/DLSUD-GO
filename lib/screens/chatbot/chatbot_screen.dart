// lib/screens/chatbot/chatbot_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chat_message.dart';

Future<String> sendToDialogflow(String text) async {
  try {
    final jsonKey = await rootBundle.loadString('assets/dialogflow_key.json');
    final Map<String, dynamic> keyMap = jsonDecode(jsonKey);

    final String projectId = keyMap["project_id"];

    final credentials = ServiceAccountCredentials.fromJson(jsonKey);

    final client = await clientViaServiceAccount(
      credentials,
      ['https://www.googleapis.com/auth/cloud-platform'],
    );

    final url =
        "https://dialogflow.googleapis.com/v2/projects/$projectId/agent/sessions/flutter-session:detectIntent";

    final response = await client.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "queryInput": {
          "text": {"text": text, "languageCode": "en"}
        }
      }),
    );

    client.close();

    final data = jsonDecode(response.body);

    // Debug print
    print("DF RESPONSE: ${response.body}");

    final queryResult = data["queryResult"];

    if (queryResult == null) {
      return "I'm having trouble connecting. Try again.";
    }

    return queryResult["fulfillmentText"] ?? "I couldn't understand that.";

  } catch (e) {
    print("ERROR: $e");
    return "I can't connect to the server right now.";
  }
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isConnected = true;



  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initializeDialogflow() async {
    try {
      final String response = await rootBundle.loadString('assets/dialogflow_key.json');
      final data = json.decode(response);

    } catch (e) {
      if (mounted) {
        final botResponse = ChatMessage(
          text: 'Initialization Error: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
        );
        setState(() {
          _messages.add(botResponse);
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _addWelcomeMessage() {
    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Hi there, Patriot! 👋\n\nI\'m Lily, your friendly DLSU-D campus guide! I\'m here to help make your campus life easier. I can assist you with:\n\n🗺️ Campus navigation and directions\n🎓 Student services information\n📚 Academic programs and requirements\n🏢 Office locations and hours\n❓ General campus questions\n\nFeel free to ask me anything about DLSU-D! What can I help you with today?',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    if (mounted) {
      setState(() {
        _messages.add(userMessage);
        _isTyping = true;
      });
    }

    _messageController.clear();
    _scrollToBottom();

    if (!_isConnected) {
      final botResponse = ChatMessage(
        text: 'You are offline. Please check your connection.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      if(mounted) {
        setState(() {
          _messages.add(botResponse);
          _isTyping = false;
        });
      }
      return;
    }

    try {
      // CALL DIALOGFLOW REST API
      String fulfillmentText = await sendToDialogflow(text.trim());

      final botResponse = ChatMessage(
        text: fulfillmentText.isEmpty
            ? "I'm sorry, I couldn't understand that. Can you rephrase?"
            : fulfillmentText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(botResponse);
          _isTyping = false;
        });
      }
    } catch (e) {
      final botResponse = ChatMessage(
        text: 'Connection Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(botResponse);
          _isTyping = false;
        });
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  Future<void> _checkConnectivity() async {
    final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if(mounted) {
      setState(() {
        _isConnected = !results.contains(ConnectivityResult.none);
      });
    }
    if (!_isConnected) {
      _showConnectivitySnackBar();
    }
  }

  void _showConnectivitySnackBar() {
    if(mounted) {
      final snackBar = SnackBar(
        content: const Text('You are offline. Please check your connection.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔑 Detect dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final surfaceColor = isDarkMode ? Colors.grey[850] : AppColors.surfaceColor;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primaryGreen,
              radius: 20,
              child: Icon(Icons.favorite, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lily',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                ),
                Text(
                  'Your campus guide',
                  style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.grey[400] : AppColors.textMedium,
                      fontWeight: FontWeight.w500
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _showClearChatDialog();
                  break;
                case 'help':
                  _showHelpDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Chat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 8),
                    Text('Help'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Language toggle (placeholder for future implementation)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: surfaceColor,
            child: Row(
              children: [
                Icon(
                    Icons.language,
                    size: 16,
                    color: isDarkMode ? Colors.grey[400] : AppColors.textMedium
                ),
                const SizedBox(width: 8),
                Text(
                  'English/Filipino support available',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),

          
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Typing indicator
          if (_isTyping) _buildTypingIndicator(),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Dynamic colors for chat bubbles
    final userBubbleColor = isDarkMode ? Colors.green[700] : AppColors.chatUserBubble;
    final botBubbleColor = isDarkMode ? Colors.grey[800] : AppColors.chatBotBubble;
    final userTextColor = Colors.white;
    final botTextColor = isDarkMode ? Colors.white : AppColors.textDark;
    final timestampColor = isUser
        ? Colors.white70
        : (isDarkMode ? Colors.grey[400] : AppColors.textLight);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryGreen,
              child: Icon(Icons.favorite, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? userBubbleColor : botBubbleColor,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? userTextColor : botTextColor,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: timestampColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accentBlue,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDarkMode ? Colors.grey[800] : AppColors.chatBotBubble;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primaryGreen,
            child: Icon(Icons.favorite, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (0.5 * value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation for continuous loop
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildMessageInput() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final inputColor = isDarkMode ? Colors.grey[800] : AppColors.surfaceColor;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDarkMode ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Type message',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),

          const SizedBox(width: 12),

          FloatingActionButton(
            mini: true,
            backgroundColor: AppColors.primaryGreen,
            onPressed: () => _sendMessage(_messageController.text),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showClearChatDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : null,
        title: Text(
          'Clear Chat',
          style: TextStyle(color: isDarkMode ? Colors.white : null),
        ),
        content: Text(
          'Are you sure you want to clear all messages?',
          style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDarkMode ? Colors.grey[400] : null),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              Navigator.pop(context);
              _addWelcomeMessage();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : null,
        title: const Row(
          children: [
            Icon(Icons.favorite, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Lily\'s Guide'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '✨ What Lily can help with:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '🗺️ Campus navigation and directions',
                style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
              ),
              const SizedBox(height: 6),
              Text(
                '📚 Student services & academic info',
                style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
              ),
              const SizedBox(height: 6),
              Text(
                '🏢 Office locations and hour',
                style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
              ),
              const SizedBox(height: 6),
              Text(
                '💳 Payment and enrollment details',
                style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
              ),
              const SizedBox(height: 6),
              Text(
                '🎓 Academic programs and courses',
                style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
              ),
              const SizedBox(height: 6),
              Text(
                '❓ General campus questions',
                style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
              ),
              const SizedBox(height: 20),
              Text(
                '💡 Tips for better results:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '• Ask specific, clear questions',
                style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
              ),
              const SizedBox(height: 6),
              Text(
                '• Use keywords like "payment", "directions"',
                style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
              ),
              const SizedBox(height: 6),
              Text(
                '• Ask in English or Filipino',
                style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
              ),
              const SizedBox(height: 6),
              Text(
                '• Try rephrasing if unsure',
                style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it! 👍',
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}