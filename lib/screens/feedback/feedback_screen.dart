// lib/screens/feedback/feedback_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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

  int _rating = 4;
  final List<String> _selectedPositives = [];
  final List<String> _selectedImprovements = [];
  bool _isSubmitting = false;

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
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation: ensure at least some feedback is provided
    if (_selectedPositives.isEmpty &&
        _selectedImprovements.isEmpty &&
        _feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please provide at least one form of feedback'),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get a reference to the Firestore collection
      final collection = FirebaseFirestore.instance.collection('feedback');

      // Prepare the feedback data
      final feedbackData = {
        'rating': _rating,
        'positives': _selectedPositives,
        'improvements': _selectedImprovements,
        'additional_feedback': _feedbackController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'submitted_at': FieldValue.serverTimestamp(),
        'app_version': '1.0.0', // You can get this from package_info_plus
        'platform': Theme.of(context).platform.toString(),
      };

      // Add the document to Firestore
      final docRef = await collection.add(feedbackData);

      // Log success for debugging
      debugPrint('Feedback submitted successfully with ID: ${docRef.id}');

      if (mounted) {
        _showSuccessDialog();
      }
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors
      debugPrint('Firebase error: ${e.code} - ${e.message}');

      if (mounted) {
        String errorMessage = 'Failed to submit feedback. ';

        switch (e.code) {
          case 'permission-denied':
            errorMessage += 'Permission denied. Please check Firestore rules.';
            break;
          case 'unavailable':
            errorMessage += 'Service unavailable. Please check your connection.';
            break;
          case 'unauthenticated':
            errorMessage += 'Authentication required.';
            break;
          default:
            errorMessage += e.message ?? 'Unknown error occurred.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Handle any other errors
      debugPrint('Unexpected error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(
          Icons.check_circle,
          color: AppColors.primaryGreen,
          size: 64,
        ),
        title: const Text(
          'Thank You!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Your feedback has been submitted successfully. We appreciate your input and will use it to improve DLSU-D Go!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 200,
            child: CustomButton(
              text: 'Continue',
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close feedback screen
              },
            ),
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
              _buildHeader(),
              const SizedBox(height: 32),
              _buildRatingSection(),
              const SizedBox(height: 32),
              _buildLikedSection(),
              const SizedBox(height: 32),
              _buildImprovementSection(),
              const SizedBox(height: 32),
              _buildAdditionalFeedbackSection(),
              const SizedBox(height: 32),
              _buildEmailSection(),
              const SizedBox(height: 40),
              _buildSubmitButton(),
              const SizedBox(height: 20),
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
                  size: 40,
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
            fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGreen : Colors.grey[400]!,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.errorRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.errorRed : Colors.grey[400]!,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
          maxLength: 500,
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
            counterText: '',
          ),
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
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(value)) {
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
      text: _isSubmitting ? 'Submitting...' : 'Submit Feedback',
      onPressed: _isSubmitting ? null : _submitFeedback,
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