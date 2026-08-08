import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'search_song_screen.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'history_screen.dart';
import 'favourite_screen.dart';
import '../provider/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String? _username;
  String? _profileImageUrl;
  bool _isLoadingUsername = true;


  Future<void> _logout() async {
    // Store navigator before the async gap to avoid using BuildContext across async gaps.
    final navigator = Navigator.of(context);

    await FirebaseAuth.instance.signOut();
    
    try {
      // Sign out of Google to force the account picker on the next login
      await GoogleSignIn().signOut();
    } catch (e) {
      // Ignore errors if the user didn't log in with Google
    }
    
    if (mounted) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _deleteAccount() async {
    // Store instances before the async gap to avoid using BuildContext across async gaps.
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Delete record from Firestore database
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        
        // Delete account from Firebase Authentication
        await user.delete();
        
        try {
          // Revoke Google Sign-In access if deleting account
          await GoogleSignIn().disconnect();
        } catch (e) {
          // Ignore errors
        }

        if (mounted) {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        // Firebase requires a recent login for sensitive functions
        if (e.code == 'requires-recent-login') {
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text("Please log out and log in again to delete the account."),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text("Error: ${e.message}"), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to delete your account? This action is permanent and cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        // Using a temporary variable to hold the selected value inside the dialog
        ThemeMode? selectedMode = themeProvider.themeMode;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Mode"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: ThemeMode.values.map((mode) {
                  return RadioListTile<ThemeMode>(
                    title: Text(mode.name[0].toUpperCase() + mode.name.substring(1)),
                    value: mode,
                    groupValue: selectedMode,
                    onChanged: (ThemeMode? value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedMode = value;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
                TextButton(
                    onPressed: () {
                      if (selectedMode != null) themeProvider.setThemeMode(selectedMode!);
                      Navigator.pop(dialogContext);
                    },
                    child: const Text("OK")),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
            CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  Future<void> _loadUsername() async {
    if (_currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
            .get();
        if (mounted && userDoc.exists) {
          final data = userDoc.data();
          setState(() {
            _username = data?['username'];
            _profileImageUrl = data?['photoUrl'] ?? _currentUser?.photoURL;
          });
        }
      } catch (e) {
        // Fallback to email on error
      }
    }
    if (mounted) {
      setState(() => _isLoadingUsername = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: isDark ? Colors.white70 : Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchSongScreen()),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: _buildBottomNavBar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF111827), const Color(0xFF1F2937)]
                : [colorScheme.primary.withOpacity(0.96), colorScheme.secondary.withOpacity(0.95), const Color(0xFFF7F8FC)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: screenWidth * 0.085,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                          child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                              ? null
                              : Text(
                                  (_username?.isNotEmpty ?? false)
                                      ? _username!.trim()[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.055,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingUsername)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Text(
                            _username ?? 'No Username',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF111827),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.lock_rounded,
                          iconColor: const Color(0xFF4F46E5),
                          iconBg: const Color(0xFFEDE9FE),
                          title: 'Change Password',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                        _buildSettingTile(
                          icon: Icons.palette_rounded,
                          iconColor: const Color(0xFF0F766E),
                          iconBg: const Color(0xFFCCFBF1),
                          title: 'Mode',
                          onTap: _showThemeDialog,
                        ),
                        const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                        _buildSettingTile(
                          icon: Icons.favorite_rounded,
                          iconColor: const Color(0xFFDC2626),
                          iconBg: const Color(0xFFFEE2E2),
                          title: 'Favourite',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FavouriteScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                        _buildSettingTile(
                          icon: Icons.history_rounded,
                          iconColor: const Color(0xFF0F766E),
                          iconBg: const Color(0xFFCCFBF1),
                          title: 'History',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HistoryScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                        _buildSettingTile(
                          icon: Icons.logout_rounded,
                          iconColor: const Color(0xFFD97706),
                          iconBg: const Color(0xFFFEF3C7),
                          title: 'Logout',
                          onTap: _logout,
                        ),
                        const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                        _buildSettingTile(
                          icon: Icons.delete_forever_rounded,
                          iconColor: const Color(0xFFDC2626),
                          iconBg: const Color(0xFFFEE2E2),
                          title: 'Delete Account',
                          titleColor: Colors.red,
                          onTap: _showDeleteConfirmation,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: titleColor ?? (isDark ? Colors.white : const Color(0xFF111827)),
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: isDark ? Colors.white70 : Colors.grey.shade400),
      onTap: onTap,
    );
  }
}