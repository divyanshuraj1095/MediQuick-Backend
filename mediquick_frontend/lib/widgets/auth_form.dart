import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class AuthForm extends StatefulWidget {
  final bool isSignIn;
  final Function(bool) onTabChanged;
  final VoidCallback? onAuthSuccess;

  const AuthForm({
    super.key,
    required this.isSignIn,
    required this.onTabChanged,
    this.onAuthSuccess,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Capture the messenger using the synchronous, currently mounted context
    final messenger = ScaffoldMessenger.of(context);

    // Unfocus the keyboard to ensure smooth transition and avoid UI glitches
    FocusScope.of(context).unfocus();

    messenger.showSnackBar(
      SnackBar(
        content: Text(widget.isSignIn ? 'Signing in...' : 'Signing up...'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );

    final result = widget.isSignIn
        ? await AuthService.login(
            _emailController.text.trim(),
            _passwordController.text,
          )
        : await AuthService.register(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          );

    print('DEBUG: _handleSubmit result: $result');

    if (!mounted) return;

    if (result['success'] == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Success!'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onAuthSuccess?.call();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tabs
            Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Sign In',
                    isActive: widget.isSignIn,
                    onTap: () => widget.onTabChanged(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TabButton(
                    label: 'Sign Up',
                    isActive: !widget.isSignIn,
                    onTap: () => widget.onTabChanged(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Welcome heading
            if (widget.isSignIn) ...[
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to your MediQuick account',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textGray,
                ),
              ),
            ] else ...[
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign up to get started with MediQuick',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textGray,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Name Field (only for Sign Up)
            if (!widget.isSignIn) ...[
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'John Doe',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppTheme.textGray,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            // Confirm Password (only for Sign Up)
            if (!widget.isSignIn) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 16),

            // Remember Me & Forgot Password (only for Sign In)
            if (widget.isSignIn)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryGreen,
                      ),
                      const Text(
                        'Remember me',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // Handle forgot password
                    },
                    child: Text(
                      'Forgot password?',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              )
            else
              const SizedBox(height: 8),

            const SizedBox(height: 24),

            // Sign In/Up Button
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleSubmit,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      widget.isSignIn ? 'Sign In' : 'Sign Up',
                      style: AppTheme.buttonText,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Divider
            const Row(
              children: [
                Expanded(child: Divider(color: AppTheme.borderGray)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Or continue with',
                    style: AppTheme.bodySmall,
                  ),
                ),
                Expanded(child: Divider(color: AppTheme.borderGray)),
              ],
            ),

            const SizedBox(height: 24),

            // Social Buttons
            _SocialButton(
              icon: Icons.g_mobiledata,
              label: 'Google',
              onPressed: () {
                // Handle Google sign in
              },
            ),
            const SizedBox(height: 12),
            _SocialButton(
              icon: Icons.apple,
              label: 'Apple',
              onPressed: () {
                // Handle Apple sign in
              },
            ),

            const SizedBox(height: 24),

            // Security assurance text
            Text(
              'Protected by industry-standard encryption and security measures.',
              textAlign: TextAlign.center,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 12,
                color: AppTheme.textLightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive ? AppTheme.primaryGradient : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppTheme.textGray,
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppTheme.borderGray),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.textDark),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
