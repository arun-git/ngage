import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_providers.dart';
import '../../../services/auth_validation_service.dart';

class PhoneLoginForm extends ConsumerStatefulWidget {
  final bool isEnabled;

  const PhoneLoginForm({
    super.key,
    required this.isEnabled,
  });

  @override
  ConsumerState<PhoneLoginForm> createState() => _PhoneLoginFormState();
}

class _PhoneLoginFormState extends ConsumerState<PhoneLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  
  bool _codeSent = false;
  bool _isVerifying = false;
 // String? _verificationId;
  int _resendTimer = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_codeSent) ...[
              // Phone number input
              TextFormField(
                controller: _phoneController,
                enabled: widget.isEnabled && !_isVerifying,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
                  LengthLimitingTextInputFormatter(20),
                  _PhoneNumberFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+1 (234) 567-8900',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Include country code (e.g., +1 for US)',
                  helperMaxLines: 2,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: _validatePhoneNumber,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleSendCode(),
              ),
              const SizedBox(height: 16),

              // Send code button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (widget.isEnabled && !_isVerifying) ? _handleSendCode : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Send Verification Code',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ] else ...[
              // Verification code input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Enter the verification code sent to ${AuthValidationService.formatPhoneNumber(_phoneController.text)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _codeController,
                enabled: widget.isEnabled,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  hintText: '123456',
                  prefixIcon: Icon(Icons.sms_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Enter the 6-digit code',
                ),
                validator: _validateVerificationCode,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleVerifyCode(),
              ),
              const SizedBox(height: 16),

              // Verify code button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.isEnabled ? _handleVerifyCode : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Verify Code',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Resend code button
              TextButton(
                onPressed: (_resendTimer == 0 && widget.isEnabled) ? _handleResendCode : null,
                child: Text(
                  _resendTimer > 0
                      ? 'Resend code in ${_resendTimer}s'
                      : 'Resend Code',
                ),
              ),

              // Change phone number button
              TextButton(
                onPressed: widget.isEnabled ? _handleChangePhoneNumber : null,
                child: const Text('Change Phone Number'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _validatePhoneNumber(String? value) {
    return AuthValidationService.validatePhoneNumber(value);
  }

  String? _validateVerificationCode(String? value) {
    return AuthValidationService.validateVerificationCode(value);
  }

  void _handleSendCode() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isVerifying = true);

    final phoneNumber = _phoneController.text.trim();
    
    ref.read(authStateProvider.notifier).verifyPhoneNumber(
      phoneNumber,
      codeSent: (verificationId) {
        setState(() {
   //       _verificationId = verificationId;
          _codeSent = true;
          _isVerifying = false;
        });
        _startResendTimer();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent to $phoneNumber'),
            backgroundColor: Colors.green,
          ),
        );
      },
      verificationFailed: (error) {
        setState(() => _isVerifying = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _handleVerifyCode() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phoneNumber = _phoneController.text.trim();
    final verificationCode = _codeController.text.trim();
    
    ref.read(authStateProvider.notifier).signInWithPhone(phoneNumber, verificationCode);
  }

  void _handleResendCode() {
    _handleSendCode();
  }

  void _handleChangePhoneNumber() {
    setState(() {
      _codeSent = false;
   //   _verificationId = null;
      _codeController.clear();
      _resendTimer = 0;
    });
  }

  void _startResendTimer() {
    setState(() => _resendTimer = 60);
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _resendTimer--);
        return _resendTimer > 0;
      }
      return false;
    });
  }
}

/// Custom formatter for phone numbers that preserves + sign and formats nicely
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // If the text is empty or just contains +, return as is
    if (text.isEmpty || text == '+') {
      return newValue;
    }
    
    // If user is trying to add + at the beginning, allow it
    if (text.startsWith('+')) {
      // Remove any extra + signs beyond the first one
      final cleanText = '+${text.substring(1).replaceAll('+', '')}';
      
      // Format the number based on length and pattern
      final formatted = _formatPhoneNumber(cleanText);
      
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    
    // If no + at the beginning, add it automatically
    final withPlus = '+$text';
    final formatted = _formatPhoneNumber(withPlus);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
  
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all formatting except +
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (digitsOnly.length <= 1) {
      return digitsOnly;
    }
    
    // US/Canada number formatting (+1XXXXXXXXXX)
    if (digitsOnly.startsWith('+1') && digitsOnly.length > 2) {
      final digits = digitsOnly.substring(2);
      if (digits.length <= 3) {
        return '+1 ($digits';
      } else if (digits.length <= 6) {
        return '+1 (${digits.substring(0, 3)}) ${digits.substring(3)}';
      } else if (digits.length <= 10) {
        return '+1 (${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
      } else {
        // Limit to 10 digits after +1
        return '+1 (${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)}';
      }
    }
    
    // Other country codes - basic formatting with spaces
    if (digitsOnly.startsWith('+') && digitsOnly.length > 1) {
      final countryAndNumber = digitsOnly.substring(1);
      if (countryAndNumber.length <= 3) {
        return '+$countryAndNumber';
      } else if (countryAndNumber.length <= 6) {
        return '+${countryAndNumber.substring(0, 2)} ${countryAndNumber.substring(2)}';
      } else {
        return '+${countryAndNumber.substring(0, 2)} ${countryAndNumber.substring(2, 5)} ${countryAndNumber.substring(5)}';
      }
    }
    
    return digitsOnly;
  }
}