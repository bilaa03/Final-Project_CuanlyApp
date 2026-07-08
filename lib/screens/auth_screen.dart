import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthScreen extends StatefulWidget {
  final List<UserAccount> users;
  final Function(String, String) onLogin;
  final Function(String, String, String) onRegister;
  final String currentAccent;

  const AuthScreen({
    super.key,
    required this.users,
    required this.onLogin,
    required this.onRegister,
    required this.currentAccent,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginMode = true;
  bool _showPassword = false;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Color _getPrimaryColor() {
    switch (widget.currentAccent) {
      case 'emerald':
        return const Color(0xFF10B981);
      case 'sapphire':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFCCA352);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cuanly Logo Icon
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF534AB7).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cuanly',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Smart Personal Finance Hub',
                style: TextStyle(color: Color(0xFF8B8A88), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 36),

              // Form card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C24),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        _isLoginMode ? 'Login ke Akun Anda' : 'Registrasi Akun Baru',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 20),

                      // Name Field if Register
                      if (!_isLoginMode) ...[
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap',
                            labelStyle: const TextStyle(color: Color(0xFF8B8A88), fontSize: 12),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Mohon isi nama lengkap.' : null,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Alamat Email',
                          labelStyle: const TextStyle(color: Color(0xFF8B8A88), fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) => value == null || !value.contains('@') ? 'Mohon isi email yang valid.' : null,
                      ),
                      const SizedBox(height: 14),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi',
                          labelStyle: const TextStyle(color: Color(0xFF8B8A88), fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF8B8A88), size: 18),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        validator: (value) => value == null || value.length < 6 ? 'Kata sandi minimal 6 karakter.' : null,
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF534AB7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final email = _emailController.text.trim();
                              final password = _passwordController.text;
                              if (_isLoginMode) {
                                widget.onLogin(email, password);
                              } else {
                                final name = _nameController.text.trim();
                                widget.onRegister(name, email, password);
                              }
                            }
                          },
                          child: Text(
                            _isLoginMode ? 'Masuk' : 'Daftar',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      
                      // Demo Account Shortcut
                      if (_isLoginMode) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.04),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              _emailController.text = 'bilaa@cuanly.ai';
                              _passwordController.text = 'password123';
                              widget.onLogin('bilaa@cuanly.ai', 'password123');
                            },
                            child: const Text('Login Cepat Demo (Bilaa)', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Switch mode button
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoginMode = !_isLoginMode;
                  });
                },
                child: Text(
                  _isLoginMode ? 'Belum memiliki akun? Daftar Sekarang' : 'Sudah memiliki akun? Masuk',
                  style: const TextStyle(color: Color(0xFF7F77DD), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
