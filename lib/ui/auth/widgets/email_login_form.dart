import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_providers.dart';
import '../../../services/auth_validation_service.dart';

class EmailLoginForm extends ConsumerStatefulWidget {
  final bool isSignUp;
  final bool isEnabled;

  const EmailLoginForm({
    super.key,
    required this.isSignUp,
    required this.isEnabled,
  });

  @override
  ConsumerState<EmailLoginForm> createState() => _EmailLoginFormState();
}

class _EmailLoginFormState extends ConsumerState<EmailLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  PasswordStrength _passwordStrength = PasswordStrength.none;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              // Email field
              TextFormField(
                controller: _emailController,
                enabled: widget.isEnabled,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                enabled: widget.isEnabled,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => AuthValidationService.validatePassword(
                    value,
                    isSignUp: widget.isSignUp),
                textInputAction: widget.isSignUp
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted:
                    widget.isSignUp ? null : (_) => _handleSubmit(),
                onChanged: widget.isSignUp ? _onPasswordChanged : null,
              ),

              // Password strength indicator (only for sign up)
              if (widget.isSignUp && _passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildPasswordStrengthIndicator(),
                const SizedBox(height: 8),
              ] else if (widget.isSignUp) ...[
                const SizedBox(height: 16),
              ] else ...[
                const SizedBox(height: 16),
              ],

              // Confirm password field (only for sign up)
              if (widget.isSignUp) ...[
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: widget.isEnabled,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validateConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSubmit(),
                ),
                const SizedBox(height: 16),
              ],

              // Submit button
              ElevatedButton(
                onPressed: widget.isEnabled ? _handleSubmit : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.isSignUp ? 'Create Account' : 'Sign In',
                  style: const TextStyle(fontSize: 16),
                ),
              ),

              // Forgot password link (only for sign in)
              if (!widget.isSignUp) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: widget.isEnabled ? _handleForgotPassword : null,
                  child: const Text('Forgot Password?'),
                ),
              ],
            ],
          ),
        ),
    );
  }

  String? _validateEmail(String? value) {
    return AuthValidationService.validateEmail(value);
  }

  String? _validateConfirmPassword(String? value) {
    return AuthValidationService.validatePasswordConfirmation(
        value, _passwordController.text);
  }

  void _onPasswordChanged(String value) {
    setState(() {
      _passwordStrength = AuthValidationService.getPasswordStrength(value);
    });
  }

  Widget _buildPasswordStrengthIndicator() {
    final strength = _passwordStrength;
    final description =
        AuthValidationService.getPasswordStrengthDescription(strength);
    final suggestions =
        AuthValidationService.getPasswordSuggestions(_passwordController.text);

    Color strengthColor;
    double strengthValue;

    switch (strength) {
      case PasswordStrength.none:
        strengthColor = Colors.grey;
        strengthValue = 0.0;
        break;
      case PasswordStrength.weak:
        strengthColor = Colors.red;
        strengthValue = 0.25;
        break;
      case PasswordStrength.medium:
        strengthColor = Colors.orange;
        strengthValue = 0.5;
        break;
      case PasswordStrength.strong:
        strengthColor = Colors.blue;
        strengthValue = 0.75;
        break;
      case PasswordStrength.veryStrong:
        strengthColor = Colors.green;
        strengthValue = 1.0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strengthValue,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              description,
              style: TextStyle(
                color: strengthColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...suggestions.take(2).map((suggestion) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $suggestion',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              )),
        ],
      ],
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (widget.isSignUp) {
      ref
          .read(authStateProvider.notifier)
          .createUserWithEmailAndPassword(email, password);
    } else {
      ref.read(authStateProvider.notifier).signInWithEmail(email, password);
    }
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (AuthValidationService.validateEmail(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref.read(authStateProvider.notifier).sendPasswordResetEmail(email);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password reset email sent to $email'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
