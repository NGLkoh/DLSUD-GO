// lib/screens/auth/terms_conditions_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../dashboard/main_dashboard.dart';

class TermsConditionsScreen extends StatefulWidget {
  final bool isFirstTime;
  const TermsConditionsScreen({super.key, this.isFirstTime = false});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    // Check if user has scrolled to near the bottom (within 100 pixels)
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
    );
  }

  void _acceptAndContinue() async {
    setState(() {
      _isAccepting = true;
    });

    // Save acceptance state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);

    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainDashboard()),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Scrollable terms content
            Expanded(
              child: _buildTermsContent(),
            ),

            // Bottom action buttons
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Agreement label
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'AGREEMENT',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Terms of Service title
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Terms of Service',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Last updated
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Last updated on 5/12/2025',
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Acceptance of Terms',
              'By using DLSU-D Go!, you acknowledge that you have read, understood, and agreed to be bound by these Terms and Conditions and the university\'s applicable data privacy and security policies.',
            ),

            _buildSection(
              'User Access and Accounts',
              'General users may access core features (navigation, chatbot, static maps, FAQs) without registration.\n\nAuthorized administrative personnel must use secure login credentials to access the backend for content management.\n\nUsers are responsible for maintaining the confidentiality of any login information.',
            ),

            _buildSection(
              'User Conduct',
              'You agree not to:\n• Use the app for unlawful purposes\n• Interfere with its operation or attempt to gain unauthorized access\n• Submit inappropriate content through queries through the chatbot',
            ),

            _buildSection(
              'Consent and Acceptance',
              'By clicking "Accept and Continue", installing, or using the DLSU-D Go! mobile application, you acknowledge that you have read, understood, and agreed to be bound by this Privacy Statement and the Terms and Conditions of the application. You expressly consent to the collection, use, processing, storage, and disclosure of your data as described above, in accordance with applicable university policies and the provisions of the Data Privacy Act of 2012.\n\nIf you do not agree with any part of this Privacy Statement or the related Terms and Conditions, you should discontinue use of the application immediately and uninstall it from your device.',
            ),

            // Add some extra space at the bottom for better scrolling experience
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scroll to Bottom button (only show if not scrolled to bottom)
          if (!_hasScrolledToBottom)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton(
                onPressed: _scrollToBottom,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Scroll to Bottom'),
              ),
            ),

          // Accept and Continue button
          CustomButton(
            text: 'Accept & Continue',
            onPressed: _hasScrolledToBottom ? _acceptAndContinue : null,
            isLoading: _isAccepting,
            width: double.infinity,
            height: 56,
          ),

          const SizedBox(height: 12),

          // Scroll to Top button (only show if scrolled down)
          if (_hasScrolledToBottom)
            OutlinedButton(
              onPressed: _scrollToTop,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMedium,
                side: BorderSide(color: Colors.grey[300]!),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Scroll to Top'),
            ),
        ],
      ),
    );
  }
}

// Helper widget for terms sections with expandable content
class ExpandableTermsSection extends StatefulWidget {
  final String title;
  final String content;
  final bool isInitiallyExpanded;

  const ExpandableTermsSection({
    super.key,
    required this.title,
    required this.content,
    this.isInitiallyExpanded = false,
  });

  @override
  State<ExpandableTermsSection> createState() => _ExpandableTermsSectionState();
}

class _ExpandableTermsSectionState extends State<ExpandableTermsSection> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}