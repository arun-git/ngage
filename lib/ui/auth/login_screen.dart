import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_picker/country_picker.dart';
import '../../providers/auth_providers.dart';
import 'widgets/social_login_buttons.dart';
import 'password_screen.dart';
import 'phone_verification_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  bool _isSignUp = false;
  bool _isPhoneMode = false;
  Country _selectedCountry = CountryService().findByCode('IN')!;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome message
              Text(
                _isSignUp ? 'Welcome to Ngage' : 'Welcome back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Email or Phone input
              _isPhoneMode ? _buildPhoneInput(isLoading) : _buildEmailInput(isLoading),
              const SizedBox(height: 16),

              // Continue button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: isLoading ? null : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp ? 'Sign in' : 'Sign up',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              // Toggle between email and phone
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: isLoading ? null : () {
                    setState(() => _isPhoneMode = !_isPhoneMode);
                    // Auto-focus the appropriate field after mode change
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_isPhoneMode) {
                        _phoneFocusNode.requestFocus();
                      } else {
                        _emailFocusNode.requestFocus();
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 8),
                      Icon(_isPhoneMode ? Icons.email : Icons.phone, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _isPhoneMode ? 'Continue with email' : 'Continue with phone',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Social login buttons
              SocialLoginButtons(isEnabled: !isLoading, hidePhoneButton: true),

              const SizedBox(height: 32),

              // Terms and Privacy
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _showTermsDialog(),
                    child: Text(
                      'Terms of Use',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    '  |  ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  GestureDetector(
                    onTap: () => _showPrivacyDialog(),
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInput(bool isLoading) {
    // Auto-focus when email mode is active
    if (!_isPhoneMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_emailFocusNode.hasFocus) {
          _emailFocusNode.requestFocus();
        }
      });
    }
    
    return TextField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      enabled: !isLoading,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'Email address',
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildPhoneInput(bool isLoading) {
    // Auto-focus when phone mode is active
    if (_isPhoneMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_phoneFocusNode.hasFocus) {
          _phoneFocusNode.requestFocus();
        }
      });
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country selector
        GestureDetector(
          onTap: isLoading ? null : _showCountryPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  '${_selectedCountry.name} (+${_selectedCountry.phoneCode})',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Phone number input
        TextField(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          enabled: !isLoading,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Phone number',
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            prefixText: '+${_selectedCountry.phoneCode} ',
            prefixStyle: const TextStyle(color: Colors.black87),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      showWorldWide: false,
      showSearch: true,
      countryListTheme: CountryListThemeData(
        flagSize: 0, // Hide flag emojis to avoid rendering issues
        backgroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, color: Colors.black87),
        bottomSheetHeight: 500,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withOpacity(0.2),
            ),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

  void _handleContinue() {
    if (_isPhoneMode) {
      _handlePhoneContinue();
    } else {
      _handleEmailContinue();
    }
  }

  void _handleEmailContinue() {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    // Navigate to password screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PasswordScreen(
          email: email,
          isSignUp: _isSignUp,
        ),
      ),
    );
  }

  void _handlePhoneContinue() async {
    final phone = _phoneController.text.trim();
    
    if (phone.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }

    final fullPhoneNumber = '+${_selectedCountry.phoneCode}$phone';

    try {
      await ref.read(authStateProvider.notifier).verifyPhoneNumber(
        fullPhoneNumber,
        codeSent: (verificationId) {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PhoneVerificationScreen(
                  phoneNumber: fullPhoneNumber,
                  verificationId: verificationId,
                ),
              ),
            );
          }
        },
        verificationFailed: (error) {
          if (mounted) {
            _showError('Phone verification failed: ${error.toString()}');
          }
        },
      );
    } catch (e) {
      _showError('Failed to send verification code: $e');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Use'),
        content: const Text('Terms of Use content would go here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text('Privacy Policy content would go here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}