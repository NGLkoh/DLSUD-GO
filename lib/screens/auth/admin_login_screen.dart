// lib/screens/auth/admin_login_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
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

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  // Listen to auth state changes to avoid Pigeon issues
  StreamSubscription<User?>? _authStateSubscription;

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

      print('🔐 Starting login for: $email');

      // Set up a one-time listener for auth state changes
      bool loginSuccessful = false;
      String? userId;

      // Create a completer to wait for auth state change
      final completer = Completer<User?>();

      // Listen for auth state change
      _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null && !completer.isCompleted) {
          completer.complete(user);
        }
      });

      // Attempt sign in - don't await or access the result
      FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).catchError((error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });

      // Wait for the auth state change
      final user = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Login timeout');
        },
      );

      if (user != null) {
        userId = user.uid;
        loginSuccessful = true;
        print('✅ Auth successful. UID: $userId');
      }

      // Cancel the subscription
      await _authStateSubscription?.cancel();
      _authStateSubscription = null;

      if (!loginSuccessful || userId == null) {
        throw Exception('Login failed: No user session created');
      }

      if (!mounted) return;

      // Setup admin role
      await _setupAdminRole(userId, email);

      if (!mounted) return;

      print('✅ Navigating to Admin Dashboard');

      // Navigate to dashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AdminDashboard(),
        ),
            (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      print('❌ Auth Error: ${e.code}');

      if (!mounted) return;

      _showErrorSnackBar(_getAuthErrorMessage(e.code));

    } on TimeoutException catch (_) {
      print('❌ Login timeout');

      if (!mounted) return;

      _showErrorSnackBar('Login timeout. Please try again.');

    } catch (e) {
      print('❌ Error: $e');

      if (!mounted) return;

      _showErrorSnackBar('Login failed: ${e.toString()}');
    } finally {
      await _authStateSubscription?.cancel();
      _authStateSubscription = null;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setupAdminRole(String uid, String email) async {
    try {
      print('📄 Checking admin role in Firestore...');

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // Try to get the document
      final docSnapshot = await userRef.get();

      if (docSnapshot.exists) {
        print('✅ User document found');
        final data = docSnapshot.data();

        if (data != null) {
          final role = data['role'];
          final isAdmin = data['isAdmin'];

          print('Role: $role, isAdmin: $isAdmin');

          // If not admin, try to update
          if (role != 'admin' && isAdmin != true) {
            print('⚠️ Not admin, updating role...');
            await userRef.update({
              'role': 'admin',
              'isAdmin': true,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print('✅ Updated to admin');
          }
        }
      } else {
        print('📝 Creating admin document...');
        await userRef.set({
          'email': email,
          'role': 'admin',
          'isAdmin': true,
          'name': 'Admin',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ Admin document created');
      }
    } catch (e) {
      print('⚠️ Firestore error (continuing anyway): $e');
      // Don't throw - allow login to proceed
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Admin Login'),
        backgroundColor: AppColors.backgroundColor,
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
                _buildWelcomeSection(),
                const SizedBox(height: 40),
                _buildLoginForm(),
                const SizedBox(height: 24),
                _buildRememberMeSection(),
                const SizedBox(height: 32),
                _buildLoginButton(),
                const SizedBox(height: 24),
                _buildHelpSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back! Glad to\nsee you, Again!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sign in to access administrative features',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textMedium,
          ),
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          enabled: !_isLoading,
          onFieldSubmitted: (_) {
            if (!_isLoading) {
              _handleLogin();
            }
          },
          decoration: InputDecoration(
            labelText: 'Enter your password',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRememberMeSection() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: _isLoading ? null : (value) {
            setState(() => _rememberMe = value ?? false);
          },
          activeColor: AppColors.primaryGreen,
        ),
        const Text('Remember Me'),
        const Spacer(),
        TextButton(
          onPressed: _isLoading ? null : _showForgotPasswordDialog,
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: _isLoading ? Colors.grey : AppColors.primaryGreen,
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

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
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
                color: AppColors.textMedium,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email to receive a password reset link.',
              style: TextStyle(fontSize: 14),
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
            child: const Text('Cancel'),
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