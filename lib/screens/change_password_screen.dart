import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Pre-fill the email field with the current user's email
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      _emailController.text = user!.email!;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // 1. Re-authenticate user to verify current credentials
          final cred = EmailAuthProvider.credential(
            email: _emailController.text.trim(),
            password: _currentPasswordController.text.trim(),
          );
          
          await user.reauthenticateWithCredential(cred);

          // 2. Update password
          await user.updatePassword(_newPasswordController.text.trim());

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Password changed successfully!"), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
        } else {
          setState(() => _errorMessage = "No user is currently logged in.");
          if (mounted) {
          }
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = "An error occurred. Please try again.";
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          errorMessage = "Invalid email or current password.";
        } else if (e.code == 'weak-password') {
          errorMessage = "The new password is too weak.";
        } else if (e.code == 'user-mismatch') {
          errorMessage = "Email does not match the currently logged in user.";
        } else if (e.code == 'invalid-email') {
          errorMessage = "Invalid email format.";
        }
        
        if (mounted) {
          setState(() => _errorMessage = errorMessage);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _errorMessage = "An unexpected error occurred. Please try again.");
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Card(
                      elevation: 4,
                      shadowColor: Colors.blue.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.lock_reset, size: 60, color: Colors.blue.shade600),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Change Password",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Update your security credentials",
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 30),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                                  ),
                                  prefixIcon: Icon(Icons.email, color: Colors.blue.shade600),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) => value == null || value.isEmpty ? 'Please enter your email' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _currentPasswordController,
                                obscureText: !_isCurrentPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Current Password',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                                  ),
                                  prefixIcon: Icon(Icons.lock_outline, color: Colors.blue.shade600),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isCurrentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'Please enter your current password' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _newPasswordController,
                                obscureText: !_isNewPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                                  ),
                                  prefixIcon: Icon(Icons.lock, color: Colors.blue.shade600),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isNewPasswordVisible = !_isNewPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a new password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  if (value == _currentPasswordController.text) {
                                    return 'New password cannot be the same as the current one.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                  ),
                                  onPressed: _isLoading ? null : _changePassword,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text("Update Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.blue.shade800),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}