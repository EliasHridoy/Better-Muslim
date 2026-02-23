import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            authProvider.clearError();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Join the Ummah',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Track your deeds & compete with friends',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ─── Error ──────────────────────────────
                if (authProvider.error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      authProvider.error!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ─── Name ───────────────────────────────
                Text('Full Name', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your name';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ─── Email ──────────────────────────────
                Text('Email', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ─── Password ───────────────────────────
                Text('Password', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ─── Register button ────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _register,
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Login link ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted),
                    ),
                    GestureDetector(
                      onTap: () {
                        authProvider.clearError();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Sign In',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthProvider>().clearError();
    final success = await context.read<AuthProvider>().signUp(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      // Pop back to login, then pop login to go to main app
      Navigator.pop(context); // Pop register
      Navigator.pop(context); // Pop login
    }
  }
}
