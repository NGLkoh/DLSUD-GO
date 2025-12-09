// lib/screens/chatbot/chatbot_screen.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chat_message.dart';

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

  // --- GEMINI AI CONFIGURATION ---
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    
    // 1. Initialize Gemini
    _initGemini();
    
    // 2. Add Welcome Message
    _addWelcomeMessage();
  }

  void _initGemini() {
    // Ideally use dotenv, but fallback to hardcode for testing if needed
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'YOUR_API_KEY_HERE'; 
    
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      debugPrint("❌ No API Key provided.");
      return;
    }

    // --- EXPANDED KNOWLEDGE BASE FOR LILY ---
    const String appKnowledge = '''
    You are Lily, the official AI campus guide for the "DLSU-D Go" mobile application.
    Your Persona: Friendly, spirited, helpful, and polite. Always address the user as "Patriot".
    
    **OFFICIAL APP SECTIONS & INFORMATION:**
    
    **1. ADMISSIONS:**
    "Welcome to De La Salle University-Dasmariñas — a Lasallian institution that blends academic excellence with character formation."
    - Lily's Role: Assist with inquiries about entrance exams, application requirements, and scholarships. Remind users that official applications are processed via the School Automate portal.

    **2. ACADEMIC PROGRAMS:**
    "De La Salle University-Dasmariñas offers academic programs designed to match global standards and industry needs."
    - Colleges: College of Science (COS), College of Engineering (CEAT), College of Business (CBA), College of Liberal Arts (CLA), College of Education (COED), College of Tourism (CTHM), and College of Criminal Justice Education (CCJE).

    **3. RESEARCH:**
    "De La Salle University-Dasmariñas (DLSU-D) promotes a strong culture of research and development."
    - Key Hub: The University Research Office (URO).

    **4. GLOBAL LINKAGES:**
    "Engage in international linkages and exchange student programs."
    - Opportunities: Student exchange programs, international internships, and global partnerships.

    **5. ABOUT DLSU-D (Campus Info):**
    "De La Salle University-Dasmariñas (DLSU-D) is a private Catholic university in Cavite founded by the De La Salle Brothers. Established in 1977, it stands as one of the largest Lasallian institutions in the Philippines."

    **APP FEATURES:**
    - **Navigation:** Navigate around campus with interactive maps to find buildings, offices, and student services easily. Locations are categorized into "East Campus" and "West Campus".
    - **Virtual Tours:** Users can view 360-degree panoramas of key buildings by selecting them on the map.
    - **Dashboard:** Provides quick access to Maps, Chatbot, and Campus Information.
    
    **CAMPUS LOCATIONS CHEATSHEET:**
    
    **EAST CAMPUS:**
    - **Aklatang Emilio Aguinaldo (IRC):** The main university library.
    - **Ayuntamiento de Gonzales Hall (AGH):** The main administrative building (Admissions, Registrar).
    - **Julian Felipe Hall (JFH):** Main academic building with classrooms.
    - **Museo De La Salle:** The university museum showcasing lifestyle of the 19th century.
    - **Hotel Rafael / Gourmet / Centennial:** Event venues and hospitality training centers.
    - **ICTC:** Information & Communications Technology Center (Tech support).
    - **College of Science (COS):** Academic building for science programs.
    - **Gate 1 (Magdalo):** The main entrance gate.
    
    **WEST CAMPUS:**
    - **Ugnayang La Salle (ULS):** The sports complex and gym.
    - **Grandstand & Track Oval:** For sports and PE classes.
    - **University Chapel:** Located centrally near the lake/bridge.
    - **University Food Square:** The main dining area.
    - **Candido Tirona Hall (CTH):** Academic building.
    - **Gregoria Montoya Hall (GMH):** Administration/Academic building.
    - **Gate 3 (Magdiwang):** Entrance near the sports complex.
    - **Bahay Pag-asa:** Center for youth in conflict with the law.
    
    **INSTRUCTIONS:**
    - If asked about "Admissions", "Programs", or "Research", quote the official descriptions above.
    - If asked for directions, guide them to use the "Maps" tab in the app.
    - Keep answers concise and helpful.
    ''';

    _model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: apiKey,
      systemInstruction: Content.system(appKnowledge),
    );

    _chatSession = _model.startChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text: 'Hi there, Patriot! 👋\n\nI\'m Lily, your DLSU-D Go guide! I can tell you about our Admissions, Academic Programs, Research culture, or help you navigate the campus.\n\nWhat would you like to know?',
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

    if (!_isConnected) {
      _handleError('You are offline. Please check your connection.');
      return;
    }

    try {
      final response = await _chatSession.sendMessage(
        Content.text(text.trim()),
      );

      final botText = response.text;

      if (botText == null) {
        _handleError("I'm having trouble thinking right now.");
        return;
      }

      setState(() {
        _messages.add(ChatMessage(
          text: botText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });

    } catch (e) {
      String errorMsg = "Sorry, I can't connect right now.";
      if (e.toString().contains("404")) {
        errorMsg = "Configuration Error: AI Model not found. Please check API settings.";
      } else if (e.toString().contains("API key")) {
        errorMsg = "Authentication Error: Invalid API Key.";
      }
      _handleError(errorMsg);
    }

    _scrollToBottom();
  }

  void _handleError(String msg) {
    setState(() {
      _messages.add(ChatMessage(
        text: msg,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isTyping = false;
    });
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

  // --- CONNECTIVITY HELPERS ---
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
  }

  // --- UI BUILD (Standard Chat Interface) ---
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : AppColors.backgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primaryGreen,
              radius: 18,
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lily (AI)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                ),
                Text(
                  'Powered by Gemini',
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
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showClearChatDialog,
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isUser 
        ? (isDarkMode ? Colors.green[700] : AppColors.chatUserBubble) 
        : (isDarkMode ? Colors.grey[800] : AppColors.chatBotBubble);
    final textColor = isUser ? Colors.white : (isDarkMode ? Colors.white : AppColors.textDark);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text("Lily is thinking...", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Ask Lily anything...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primaryGreen,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Chat?"),
        content: const Text("This will start a new conversation context."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _chatSession = _model.startChat();
              });
              Navigator.pop(ctx);
              _addWelcomeMessage();
            },
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}