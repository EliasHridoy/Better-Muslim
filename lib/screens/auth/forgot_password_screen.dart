import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _emailSent ? _buildSuccessState(theme) : _buildForm(authProvider, theme, isDark),
        ),
      ),
    );
  }

  Widget _buildForm(AuthProvider authProvider, ThemeData theme, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Icon(
              Icons.lock_reset_rounded,
              size: 64,
              color: AppColors.accent.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Forgot Password?',
              style: theme.textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter the email address associated with your account and we\'ll send you a link to reset your password.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
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
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authProvider.error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

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
          const SizedBox(height: 32),

          // ─── Reset Button ────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : _sendResetLink,
              child: authProvider.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : const Text('Send Reset Link'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: AppColors.success,
            size: 40,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Email Sent!',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ve sent a password reset link to\n${_emailController.text}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.muted,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.brightness == Brightness.dark
                ? AppColors.darkCard
                : AppColors.lightBackground,
              foregroundColor: theme.textTheme.bodyLarge?.color,
            ),
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }

  void _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthProvider>().clearError();
    final success = await context.read<AuthProvider>().resetPassword(
          _emailController.text.trim(),
        );

    if (success && mounted) {
      setState(() {
        _emailSent = true;
      });
    }
  }
}
