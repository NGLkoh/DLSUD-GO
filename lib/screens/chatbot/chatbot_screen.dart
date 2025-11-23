// lib/screens/chatbot/chatbot_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Generate bot response based on user input
    final botResponse = _generateBotResponse(text.trim().toLowerCase());

    setState(() {
      _messages.add(botResponse);
      _isTyping = false;
    });

    _scrollToBottom();
  }

  ChatMessage _generateBotResponse(String userInput) {
    String response;

    // Simple keyword-based responses (in production, this would connect to Dialogflow)
    if (userInput.contains('payment') || userInput.contains('tuition') || userInput.contains('cashier')) {
      response = '💳 Great question! Here\'s what I know about payments:\n\nThe Cashier\'s Office is located at the ground floor of Ayuntamiento de Gonzales Hall. They\'re available Monday to Friday, 8:00 AM to 4:00 PM (excluding holidays).\n\n✨ Payment options:\n• Full payment (with 10% discount)\n• Installment plans\n• Monthly payment schemes\n\nWould you like directions to the Cashier office? I can guide you there! 😊';
    } else if (userInput.contains('admission') || userInput.contains('enroll') || userInput.contains('apply')) {
      response = '🎓 Exciting! Welcome to the DLSU-D family! We have an open admission policy for all senior high school graduates.\n\n📋 You\'ll need:\n• High school diploma\n• Official transcripts\n• Birth certificate (NSO)\n• Medical certificate\n• 2x2 ID photos\n\nWould you like to know more about our programs or the application process? I\'m here to help! ✨';
    } else if (userInput.contains('map') || userInput.contains('direction') || userInput.contains('location') || userInput.contains('where')) {
      response = '🗺️ Navigation assistance! I\'m happy to help!\n\nYou can use the Maps feature in the app to:\n• Get turn-by-turn directions\n• Search for buildings and offices\n• Find walking routes between locations\n\nSome popular destinations:\n🏫 Julian Felipe Hall • 🏢 Ayuntamiento de Gonzales Hall • 📚 Library • 🍽️ Cafeteria\n\nWhich location are you looking for? 😊';
    } else if (userInput.contains('office hours') || userInput.contains('schedule') || userInput.contains('time')) {
      response = '⏰ Here\'s what I found about office hours:\n\n🏢 Administrative Offices:\nMonday - Friday: 8:00 AM - 4:00 PM\n\n📚 Library:\nMonday - Friday: 7:00 AM - 7:00 PM\nSaturday: 8:00 AM - 5:00 PM\n\n🏥 Health Services:\nMonday - Friday: 8:00 AM - 5:00 PM\n\nIs there a specific office you need? I can give you more details! ✨';
    } else if (userInput.contains('program') || userInput.contains('course') || userInput.contains('degree')) {
      response = '📚 Wonderful question! DLSU-D offers amazing academic programs:\n\n🎓 Undergraduate Degrees:\n• Business & Economics\n• Engineering & Technology\n• Liberal Arts & Communication\n• Education & Human Development\n• Science & Mathematics\n\n📖 Graduate Programs:\n• Master\'s degrees\n• Doctoral programs\n\nWhich field interests you? I\'d love to tell you more! 😊';
    } else if (userInput.contains('help') || userInput.contains('support')) {
      response = '🌟 Of course! I\'m Lily, and I\'m here to help with:\n\n📍 Campus navigation & directions\n📋 Student services\n💳 Payment information\n🏫 Office locations & hours\n📚 Academic programs\n⏰ Schedules\n📞 Contact information\n\nWhat can I assist you with today, Patriot? 😊';
    } else if (userInput.contains('hello') || userInput.contains('hi') || userInput.contains('good morning') || userInput.contains('good afternoon')) {
      response = 'Hey there, Patriot! 👋 Welcome back!\n\nI\'m Lily, your friendly campus guide. I\'m here to help you navigate DLSU-D, find information about services, answer questions about student life, and make your campus experience amazing!\n\nWhat can I help you with today? 🌟';
    } else if (userInput.contains('thank') || userInput.contains('salamat')) {
      response = 'Aw, you\'re so welcome! 🥰 I\'m always happy to help my fellow Patriots!\n\nIf you have any other questions about DLSU-D, just ask anytime. Have an amazing day on campus! 🌟';
    } else {
      // Default response for unrecognized input
      response = 'I understand you\'re asking about "$userInput"! I\'m still learning, but I can definitely help with:\n\n🗺️ Campus navigation\n📋 Student services\n🏢 Office locations\n⏰ Hours & schedules\n💳 Payments & enrollment\n📚 Academic programs\n\nCould you try rephrasing, or ask about one of these topics? I\'m here to help! 😊';
    }

    return ChatMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryGreen,
              radius: 20,
              child: Icon(Icons.favorite, color: Colors.white, size: 22),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lily',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                ),
                Text(
                  'Your campus guide',
                  style: TextStyle(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
            color: AppColors.surfaceColor,
            child: Row(
              children: [
                const Icon(Icons.language, size: 16, color: AppColors.textMedium),
                const SizedBox(width: 8),
                Text(
                  'English/Filipino support available',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          
          // Messages list
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
                color: isUser ? AppColors.chatUserBubble : AppColors.chatBotBubble,
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
                      color: isUser ? Colors.white : AppColors.textDark,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser ? Colors.white70 : AppColors.textLight,
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
              color: AppColors.chatBotBubble,
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
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Type message',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              Navigator.pop(context);
              _addWelcomeMessage();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.favorite, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Lily\'s Guide'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '✨ What Lily can help with:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 12),
              Text('🗺️ Campus navigation and directions'),
              SizedBox(height: 6),
              Text('📚 Student services & academic info'),
              SizedBox(height: 6),
              Text('🏢 Office locations and hours'),
              SizedBox(height: 6),
              Text('💳 Payment and enrollment details'),
              SizedBox(height: 6),
              Text('🎓 Academic programs and courses'),
              SizedBox(height: 6),
              Text('❓ General campus questions'),
              SizedBox(height: 20),
              Text(
                '💡 Tips for better results:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 12),
              Text('• Ask specific, clear questions'),
              SizedBox(height: 6),
              Text('• Use keywords like "payment", "directions"'),
              SizedBox(height: 6),
              Text('• Ask in English or Filipino'),
              SizedBox(height: 6),
              Text('• Try rephrasing if unsure'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it! 👍'),
          ),
        ],
      ),
    );
  }
}

// lib/models/chat_message.dart
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}