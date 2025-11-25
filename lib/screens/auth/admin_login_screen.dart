// lib/screens/auth/admin_login_screen.dart
// Updated with Remember Me functionality and Dark Mode support

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../admin/admin_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  StreamSubscription<User?>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final savedEmail = await _secureStorage.read(key: 'admin_email');
    final savedPassword = await _secureStorage.read(key: 'admin_password');

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final completer = Completer<User?>();
      bool loginSuccessful = false;
      String? userId;

      _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null && !completer.isCompleted) {
          completer.complete(user);
        }
      });

      FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).catchError((error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });

      final user = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Login timeout'),
      );

      if (user != null) {
        userId = user.uid;
        loginSuccessful = true;
      }

      await _authStateSubscription?.cancel();
      _authStateSubscription = null;

      if (!loginSuccessful || userId == null) {
        throw Exception('Login failed: No user session created');
      }

      if (_rememberMe) {
        await _secureStorage.write(key: 'admin_email', value: email);
        await _secureStorage.write(key: 'admin_password', value: password);
      } else {
        await _secureStorage.delete(key: 'admin_email');
        await _secureStorage.delete(key: 'admin_password');
      }

      if (!mounted) return;

      await _setupAdminRole(userId, email);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
            (route) => false,
      );

    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar("Login failed: ${e.toString()}");
    } finally {
      await _authStateSubscription?.cancel();
      _authStateSubscription = null;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setupAdminRole(String uid, String email) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final docSnapshot = await userRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && (data['role'] != 'admin' || data['isAdmin'] != true)) {
          await userRef.update({
            'role': 'admin',
            'isAdmin': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        await userRef.set({
          'email': email,
          'role': 'admin',
          'isAdmin': true,
          'name': 'Admin',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔑 Detect if dark mode is enabled
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : AppColors.backgroundColor;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final subtitleColor = isDarkMode ? Colors.grey[400] : AppColors.textMedium;
    final surfaceColor = isDarkMode ? Colors.grey[850] : AppColors.surfaceColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Admin Login'),
        backgroundColor: backgroundColor,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                _buildWelcomeSection(textColor, subtitleColor),
                const SizedBox(height: 40),
                _buildLoginForm(),
                const SizedBox(height: 24),
                _buildRememberMeSection(textColor),
                const SizedBox(height: 32),
                _buildLoginButton(),
                const SizedBox(height: 24),
                _buildHelpSection(surfaceColor, subtitleColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(Color textColor, Color? subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back! Glad to\nsee you, Again!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sign in to access administrative features',
          style: TextStyle(fontSize: 16, color: subtitleColor),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !_isLoading,
          decoration: const InputDecoration(
            labelText: 'Enter your email',
            hintText: 'admin@example.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Email is required'
              : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          enabled: !_isLoading,
          onFieldSubmitted: (_) {
            if (!_isLoading) _handleLogin();
          },
          decoration: InputDecoration(
            labelText: 'Enter your password',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () => setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              }),
            ),
          ),
          validator: (value) => (value == null || value.isEmpty)
              ? 'Password is required'
              : null,
        ),
      ],
    );
  }

  Widget _buildRememberMeSection(Color textColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: _isLoading
              ? null
              : (value) => setState(() => _rememberMe = value ?? false),
          activeColor: AppColors.primaryGreen,
        ),
        Text(
          'Remember Me',
          style: TextStyle(color: textColor),
        ),
        const Spacer(),
        TextButton(
          onPressed: _isLoading ? null : _showForgotPasswordDialog,
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: _isLoading
                  ? (isDarkMode ? Colors.grey[700] : Colors.grey)
                  : AppColors.primaryGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return CustomButton(
      text: 'Sign in',
      onPressed: _handleLogin,
      isLoading: _isLoading,
      width: double.infinity,
      height: 56,
    );
  }

  Widget _buildHelpSection(Color? surfaceColor, Color? subtitleColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.grey.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: AppColors.primaryGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Having trouble? Contact your administrator for support.',
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : null,
        title: Text(
          'Reset Password',
          style: TextStyle(
            color: isDarkMode ? Colors.white : null,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email to receive a password reset link.',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[300] : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'admin@example.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : null,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();

              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your email'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: email,
                );

                if (!context.mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset link sent!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }
}