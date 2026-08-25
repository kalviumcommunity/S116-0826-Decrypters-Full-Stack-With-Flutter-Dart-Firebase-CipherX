import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/failures/auth_failure.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_validators.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    final bool success = await controller.signUp(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      if (GoRouter.maybeOf(context) != null) {
        context.go('/verify-email');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> authState = ref.watch(authControllerProvider);
    final bool isLoading = authState.isLoading;

    final String? errorMessage = authState.hasError
        ? (authState.error is AuthFailure
            ? (authState.error as AuthFailure).message
            : authState.error.toString().replaceFirst(
                  RegExp(r'^.*Exception:\s*'),
                  '',
                ))
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Join Cipher-X',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Register for secure platform access',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  if (errorMessage != null) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    key: const Key('register_email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.newUsername],
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: AuthValidators.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('register_password_field'),
                    controller: _passwordController,
                    obscureText: _isPasswordObscured,
                    autofillHints: const <String>[AutofillHints.newPassword],
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: AuthValidators.validatePassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('register_confirm_password_field'),
                    controller: _confirmPasswordController,
                    obscureText: _isConfirmPasswordObscured,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_clock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordObscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordObscured =
                                !_isConfirmPasswordObscured;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (String? value) =>
                        AuthValidators.validateConfirmPassword(
                      value,
                      _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    key: const Key('register_submit_button'),
                    onPressed: isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('REGISTER'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text('Already have an account?'),
                      TextButton(
                        key: const Key('login_navigation_link'),
                        onPressed: isLoading
                            ? null
                            : () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
