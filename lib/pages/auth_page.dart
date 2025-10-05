import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_login_button.dart';
 



class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final GlobalKey<LoginButtonState> _loginButtonKey = GlobalKey<LoginButtonState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final mobileController = TextEditingController();
  final recoveryEmailController = TextEditingController();
  bool isLogin = true;
  bool isCreate = false;
  bool acceptTerms = false;
  bool rememberMe = false;
  String error = '';
  bool loading = false;
  // Password visibility toggles
  bool isLoginPasswordObscured = true;
  bool isCreatePasswordObscured = true;

  Map<String, dynamic> _decodeUser(String userJson) {
    final parts = userJson.split('|');
    return {
      'name': parts[0],
      'email': parts[1],
      'password': parts[2],
      'mobile': parts.length > 3 ? parts[3] : '',
    };
  }

  Future<void> _login() async {
  setState(() { loading = true; error = ''; });
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (!_validatePassword(password)) {
      setState(() {
        error = 'Password must be at least 8 characters, include uppercase, lowercase, number, and special character.';
        loading = false;
      });
      _loginButtonKey.currentState?.showErrorAnimation();
      return;
    }
    bool onlineSuccess = false;
    try {
      final client = Supabase.instance.client;
      final response = await client.auth.signInWithPassword(email: email, password: password);
      if (response.session != null && response.user != null) {
        // Save credentials for offline login
        final prefs = await SharedPreferences.getInstance();
        final usersJson = prefs.getStringList('offline_users') ?? [];
        final exists = usersJson.any((u) => _decodeUser(u)['email'] == email);
        if (!exists) {
          // Save name and mobile if available from Supabase user metadata
          final name = response.user?.userMetadata?['name'] ?? '';
          final mobile = response.user?.userMetadata?['mobile'] ?? '';
          usersJson.add('$name|$email|$password|$mobile');
          await prefs.setStringList('offline_users', usersJson);
        }
        setState(() { error = ''; loading = false; });
        _loginButtonKey.currentState?.showSuccessAnimation();
        await Future.delayed(const Duration(milliseconds: 1200));
        Navigator.pushReplacementNamed(context, '/dashboard');
        onlineSuccess = true;
        return;
      }
    } catch (_) {}
    if (!onlineSuccess) {
      final offlineUser = await _getOfflineUser(email, password);
      if (offlineUser != null) {
        setState(() { error = ''; loading = false; });
        _loginButtonKey.currentState?.showSuccessAnimation();
        await Future.delayed(const Duration(milliseconds: 1200));
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() { error = 'Login failed. Please check your credentials or network.'; loading = false; });
        _loginButtonKey.currentState?.showErrorAnimation();
      }
    }
  }

  Future<Map<String, dynamic>?> _getOfflineUser(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList('offline_users') ?? [];
    for (final userJson in usersJson) {
      final user = _decodeUser(userJson);
      if (user['email'] == email && user['password'] == password) {
        // Save user details for session
        await prefs.setString('user_name', user['name']);
        await prefs.setString('user_email', user['email']);
        await prefs.setString('user_mobile', user['mobile']);
        return user;
      }
    }
    return null;
  }

  Future<void> _createAccount() async {
    setState(() { loading = true; error = ''; });
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final mobile = mobileController.text.trim();
    if (name.isEmpty || email.isEmpty || password.isEmpty || mobile.isEmpty) {
      setState(() { error = 'All fields are required.'; loading = false; });
      return;
    }
    if (!_validatePassword(password)) {
      setState(() {
        error = 'Password must be at least 8 characters, include uppercase, lowercase, number, and special character.';
        loading = false;
      });
      return;
    }
    if (!acceptTerms) {
      setState(() { error = 'You must accept Terms & Conditions to sign up.'; loading = false; });
      return;
    }

    try {
      final client = Supabase.instance.client;
      final response = await client.auth.signUp(email: email, password: password, data: {
        'name': name,
        'mobile': mobile,
      });
      if (response.user != null) {
        setState(() { error = ''; loading = false; isCreate = false; isLogin = true; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created! Please check your email to verify.')));
        // Save to local for settings retrieval
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', name);
        await prefs.setString('user_email', email);
        await prefs.setString('user_mobile', mobile);
        // Also save offline for future offline login
        final usersJson = prefs.getStringList('offline_users') ?? [];
        final exists = usersJson.any((u) => _decodeUser(u)['email'] == email);
        if (!exists) {
          usersJson.add('$name|$email|$password|$mobile');
          await prefs.setStringList('offline_users', usersJson);
        }
        return;
      }
    } catch (_) {
      // offline fallback
    }
    // Offline fallback (always allow offline creation if online fails)
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList('offline_users') ?? [];
    // Prevent duplicate emails
    final exists = usersJson.any((u) => _decodeUser(u)['email'] == email);
    if (exists) {
      setState(() { error = 'Account with this email already exists offline.'; loading = false; });
      return;
    }
    usersJson.add('$name|$email|$password|$mobile');
    await prefs.setStringList('offline_users', usersJson);
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_mobile', mobile);
    setState(() { error = ''; loading = false; isCreate = false; isLogin = true; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline account created! You can now login offline.')));
  }

  Future<void> _recoverPassword() async {
    setState(() { loading = true; error = ''; });
    final email = recoveryEmailController.text.trim();
    final client = Supabase.instance.client;
    await client.auth.resetPasswordForEmail(email);
    setState(() { loading = false; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password recovery email sent (if account exists).')));
    Navigator.pop(context);
  }

  bool _validatePassword(String password) {
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');
    return regex.hasMatch(password);
  }

  // Helper for rounded input fields with optional show/hide password toggle
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    bool showToggle = false,
    VoidCallback? onToggle,
    bool isObscured = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure ? isObscured : false,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          suffixIcon: showToggle
              ? IconButton(
                  icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility),
                  onPressed: onToggle,
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF8E1),
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Abstract shapes
            Positioned(
              top: -60,
              left: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCreate) ...[
                          _buildInputField(controller: nameController, hint: 'Full Name'),
                          const SizedBox(height: 16),
                          _buildInputField(controller: emailController, hint: 'Email', keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: passwordController,
                            hint: 'Password',
                            obscure: true,
                            showToggle: true,
                            isObscured: isCreatePasswordObscured,
                            onToggle: () => setState(() => isCreatePasswordObscured = !isCreatePasswordObscured),
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(controller: mobileController, hint: 'Mobile', keyboardType: TextInputType.phone),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Checkbox(
                                value: acceptTerms,
                                onChanged: (v) => setState(() => acceptTerms = v ?? false),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              const Text('I accept Terms & Conditions', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: LoginButton(
                              key: _loginButtonKey,
                              loading: loading,
                              onPressed: _createAccount,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? ', style: TextStyle(fontSize: 15)),
                              GestureDetector(
                                onTap: () => setState(() { isCreate = false; isLogin = true; }),
                                child: const Text('Login', style: TextStyle(fontSize: 15, color: Colors.blue, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ] else if (isLogin) ...[
                          _buildInputField(controller: emailController, hint: 'Email', keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: passwordController,
                            hint: 'Password',
                            obscure: true,
                            showToggle: true,
                            isObscured: isLoginPasswordObscured,
                            onToggle: () => setState(() => isLoginPasswordObscured = !isLoginPasswordObscured),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: (v) => setState(() => rememberMe = v ?? false),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              const Text('Remember Me', style: TextStyle(fontSize: 14)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(() { isLogin = false; }),
                                child: const Text('Forgot Password?', style: TextStyle(fontSize: 14, color: Colors.blue)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: LoginButton(
                              key: _loginButtonKey,
                              loading: loading,
                              onPressed: _login,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Don’t have an account? ', style: TextStyle(fontSize: 15)),
                              GestureDetector(
                                onTap: () => setState(() { isLogin = false; isCreate = true; }),
                                child: const Text('Sign Up', style: TextStyle(fontSize: 15, color: Colors.blue, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Password recovery
                          _buildInputField(controller: recoveryEmailController, hint: 'Enter your email for recovery', keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: loading ? null : _recoverPassword,
                              child: loading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Send Recovery Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() { isLogin = true; isCreate = false; }),
                                child: const Text('Back to Login', style: TextStyle(fontSize: 15, color: Colors.blue, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                        if (error.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(error, style: const TextStyle(color: Colors.red)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}