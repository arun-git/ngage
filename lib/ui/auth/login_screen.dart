import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import 'widgets/email_login_form.dart';
import 'widgets/phone_login_form.dart';
import 'widgets/social_login_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo and title
              const Icon(
                Icons.groups,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'Ngage Platform',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Team-based competitions and engagement',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Sign In/Sign Up toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => setState(() => _isSignUp = false),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        fontWeight: _isSignUp ? FontWeight.normal : FontWeight.bold,
                        color: _isSignUp ? Colors.grey : Colors.blue,
                      ),
                    ),
                  ),
                  const Text(' | '),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => setState(() => _isSignUp = true),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontWeight: _isSignUp ? FontWeight.bold : FontWeight.normal,
                        color: _isSignUp ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Error message
              if (authState.hasError) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.errorMessage ?? 'An error occurred',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => ref.read(authStateProvider.notifier).clearError(),
                        color: Colors.red[700],
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Loading indicator
              if (isLoading) ...[
                const Center(
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 16),
              ],

              // Social login buttons
              SocialLoginButtons(isEnabled: !isLoading),
              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              // Tab bar for email/phone
              TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: const [
                  Tab(text: 'Email'),
                  Tab(text: 'Phone'),
                ],
              ),
              const SizedBox(height: 16),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    EmailLoginForm(isSignUp: _isSignUp, isEnabled: !isLoading),
                    PhoneLoginForm(isEnabled: !isLoading),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}