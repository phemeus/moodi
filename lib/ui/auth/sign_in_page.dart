import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../home/home_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.06), // Responsive padding
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                // Header
                SizedBox(
                  height: isSmallScreen ? screenHeight * 0.25 : screenHeight * 0.3,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/moodi.png',
                          width: isVerySmallScreen ? 60 : 80,
                          height: isVerySmallScreen ? 60 : 80,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: isVerySmallScreen ? 12 : 16),
                        Text(
                          'Moodi',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: isVerySmallScreen ? 32 : null,
                          ),
                        ),
                        SizedBox(height: isVerySmallScreen ? 6 : 8),
                        Text(
                          'Ruh halini takip et, mutluluğunu ölç',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: isVerySmallScreen ? 14 : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.onSurface,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelStyle: TextStyle(
                      fontSize: isVerySmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Giriş Yap'),
                      Tab(text: 'Kayıt Ol'),
                    ],
                  ),
                ),

                SizedBox(height: isVerySmallScreen ? 16 : 24),

                // Google Sign In Button (Geçici olarak devre dışı)
                // SizedBox(
                //   width: double.infinity,
                //   height: 56,
                //   child: OutlinedButton.icon(
                //     onPressed: _isLoading ? null : _signInWithGoogle,
                //     icon: Icon(
                //       Icons.g_mobiledata,
                //       size: 24,
                //       color: Theme.of(context).colorScheme.primary,
                //     ),
                //     label: const Text('Google ile devam et'),
                //     style: OutlinedButton.styleFrom(
                //       side: BorderSide(color: Theme.of(context).colorScheme.outline),
                //     ),
                //   ),
                // ),

                SizedBox(height: isVerySmallScreen ? 16 : 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.3))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isVerySmallScreen ? 12 : 16),
                      child: Text(
                        'veya',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: isVerySmallScreen ? 14 : null,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.3))),
                  ],
                ),

                SizedBox(height: isVerySmallScreen ? 16 : 24),

                // Tab Views
                SizedBox(
                  height: isSmallScreen ? screenHeight * 0.35 : screenHeight * 0.4,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSignInForm(),
                      _buildRegisterForm(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isVerySmallScreen = screenHeight < 600;
    
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(
                Icons.email_outlined,
                size: isVerySmallScreen ? 20 : 24,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isVerySmallScreen ? 12 : 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email gerekli';
              }
              if (!value.contains('@')) {
                return 'Geçersiz email adresi';
              }
              return null;
            },
          ),
          
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: Icon(
                Icons.lock_outlined,
                size: isVerySmallScreen ? 20 : 24,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  size: isVerySmallScreen ? 20 : 24,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isVerySmallScreen ? 12 : 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre gerekli';
              }
              if (value.length < 6) {
                return 'Şifre en az 6 karakter olmalı';
              }
              return null;
            },
          ),
          
          SizedBox(height: isVerySmallScreen ? 20 : 24),
          
          // Sign In Button
          SizedBox(
            width: double.infinity,
            height: isVerySmallScreen ? 48 : 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signInWithEmail,
              child: _isLoading
                  ? SizedBox(
                      width: isVerySmallScreen ? 20 : 24,
                      height: isVerySmallScreen ? 20 : 24,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Giriş Yap',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isVerySmallScreen = screenHeight < 600;
    
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(
                Icons.email_outlined,
                size: isVerySmallScreen ? 20 : 24,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isVerySmallScreen ? 12 : 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email gerekli';
              }
              if (!value.contains('@')) {
                return 'Geçersiz email adresi';
              }
              return null;
            },
          ),
          
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: Icon(
                Icons.lock_outlined,
                size: isVerySmallScreen ? 20 : 24,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  size: isVerySmallScreen ? 20 : 24,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isVerySmallScreen ? 12 : 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre gerekli';
              }
              if (value.length < 6) {
                return 'Şifre en az 6 karakter olmalı';
              }
              return null;
            },
          ),
          
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          // Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Şifre Tekrar',
              prefixIcon: Icon(
                Icons.lock_outlined,
                size: isVerySmallScreen ? 20 : 24,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  size: isVerySmallScreen ? 20 : 24,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isVerySmallScreen ? 12 : 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre tekrarı gerekli';
              }
              if (value != _passwordController.text) {
                return 'Şifreler eşleşmiyor';
              }
              return null;
            },
          ),
          
          SizedBox(height: isVerySmallScreen ? 20 : 24),
          
          // Register Button
          SizedBox(
            width: double.infinity,
            height: isVerySmallScreen ? 48 : 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _registerWithEmail,
              child: _isLoading
                  ? SizedBox(
                      width: isVerySmallScreen ? 20 : 24,
                      height: isVerySmallScreen ? 20 : 24,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Kayıt Ol',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = context.read<AuthService>();
      await authService.signInWithGoogle();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Hata mesajını temizle
        if (errorMessage.contains('Exception:')) {
          errorMessage = errorMessage.split('Exception:')[1].trim();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tamam',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authService = context.read<AuthService>();
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authService = context.read<AuthService>();
      await authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 