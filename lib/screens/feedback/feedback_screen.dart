// lib/screens/feedback/feedback_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/custom_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _emailController = TextEditingController();
  
  int _rating = 4; // Default rating from the mockup
  final List<String> _selectedPositives = [];
  final List<String> _selectedImprovements = [];
  bool _isSubmitting = false;

  // Feedback options from the mockup
  final List<String> _positiveOptions = [
    'EASY TO NAVIGATE',
    'VISUALLY CLEAR',
    'INFORMATIVE',
    'USEFUL FEATURES',
  ];

  final List<String> _improvementOptions = [
    'NEEDS MORE FEATURES',
    'LIMITED INTERACTION',
    'MISSING CONTENT',
    'LACKS ANSWERS TO QUESTIONS',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      // Show success dialog
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: AppColors.primaryGreen,
          size: 48,
        ),
        title: const Text('Thank You!'),
        content: const Text(
          'Your feedback has been submitted successfully. We appreciate your input and will use it to improve DLSU-D Go!',
        ),
        actions: [
          CustomButton(
            text: 'Continue',
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close feedback screen
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: AppColors.backgroundColor,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              
              const SizedBox(height: 32),
              
              // Rating section
              _buildRatingSection(),
              
              const SizedBox(height: 32),
              
              // What did you like section
              _buildLikedSection(),
              
              const SizedBox(height: 32),
              
              // Improvement section
              _buildImprovementSection(),
              
              const SizedBox(height: 32),
              
              // Additional feedback
              _buildAdditionalFeedbackSection(),
              
              const SizedBox(height: 32),
              
              // Email field (optional)
              _buildEmailSection(),
              
              const SizedBox(height: 40),
              
              // Submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thank you for exploring DLSU-D Go!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Your feedback helps us improve the app experience for all Patriots.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textMedium,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How would you rate your experience using the app?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _rating = index + 1;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.star,
                  size: 32,
                  color: index < _rating 
                      ? AppColors.primaryGreen 
                      : Colors.grey[300],
                ),
              ),
            );
          }),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          _getRatingText(_rating),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildLikedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What did you like about it?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _positiveOptions.map((option) {
            final isSelected = _selectedPositives.contains(option);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedPositives.remove(option);
                  } else {
                    _selectedPositives.add(option);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGreen : Colors.grey[400]!,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textMedium,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImprovementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What could be improved?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _improvementOptions.map((option) {
            final isSelected = _selectedImprovements.contains(option);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedImprovements.remove(option);
                  } else {
                    _selectedImprovements.add(option);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.errorRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.errorRed : Colors.grey[400]!,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textMedium,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdditionalFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anything else?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _feedbackController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Tell us everything.',
            hintStyle: TextStyle(color: AppColors.textLight),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
          ),
          validator: (value) {
            if ((value == null || value.trim().isEmpty) && 
                _selectedPositives.isEmpty && 
                _selectedImprovements.isEmpty) {
              return 'Please provide some feedback or select options above';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email (optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'We may reach out for follow-up questions or to inform you about updates.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMedium,
          ),
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'your.email@example.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return CustomButton(
      text: 'Submit',
      onPressed: _submitFeedback,
      isLoading: _isSubmitting,
      width: double.infinity,
      height: 56,
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor - Needs significant improvement';
      case 2:
        return 'Fair - Could be better';
      case 3:
        return 'Good - Meets expectations';
      case 4:
        return 'Very Good - Exceeds expectations';
      case 5:
        return 'Excellent - Outstanding experience';
      default:
        return '';
    }
  }
}

// Alternative minimal feedback screen
class SimpleFeedbackScreen extends StatefulWidget {
  const SimpleFeedbackScreen({super.key});

  @override
  State<SimpleFeedbackScreen> createState() => _SimpleFeedbackScreenState();
}

class _SimpleFeedbackScreenState extends State<SimpleFeedbackScreen> {
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedCategory = 'General Feedback';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General Feedback',
    'Bug Report',
    'Feature Request',
    'Navigation Issue',
    'Content Error',
    'Other',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We value your feedback!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Category selection
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Message field
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: 'Your message',
                  hintText: 'Describe your feedback, suggestion, or issue...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Email field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                hintText: 'For follow-up questions',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit button
            CustomButton(
              text: 'Send Feedback',
              onPressed: _submitFeedback,
              isLoading: _isSubmitting,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}