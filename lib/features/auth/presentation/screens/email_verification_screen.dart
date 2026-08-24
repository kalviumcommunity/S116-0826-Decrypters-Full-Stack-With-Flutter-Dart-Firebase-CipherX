import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/failures/auth_failure.dart';
import '../providers/auth_providers.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _resendSent = false;

  Future<void> _handleResendVerification() async {
    final controller = ref.read(authControllerProvider.notifier);
    final bool success = await controller.sendEmailVerification();
    if (success && mounted) {
      setState(() {
        _resendSent = true;
      });
    }
  }

  Future<void> _handleSignOut() async {
    final controller = ref.read(authControllerProvider.notifier);
    await controller.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> authState = ref.watch(authControllerProvider);
    final bool isLoading = authState.isLoading;
    final user = ref.watch(authStateProvider).value;

    final String? errorMessage = authState.hasError
        ? (authState.error is AuthFailure
              ? (authState.error as AuthFailure).message
              : authState.error.toString().replaceFirst(
                  RegExp(r'^.*Exception:\s*'),
                  '',
                ))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: <Widget>[
          IconButton(
            key: const Key('verification_logout_button'),
            icon: const Icon(Icons.logout),
            onPressed: isLoading ? null : _handleSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(
                Icons.mark_email_unread_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Your Email Address',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'A verification link has been sent to ${user?.email ?? "your email address"}. Please check your inbox and verify your account.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (_resendSent) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Verification email resent cleanly!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green.shade900),
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
              OutlinedButton.icon(
                key: const Key('resend_verification_button'),
                onPressed: isLoading ? null : _handleResendVerification,
                icon: const Icon(Icons.send_outlined),
                label: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Resend Verification Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
