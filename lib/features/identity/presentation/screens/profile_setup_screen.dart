import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/failures/identity_failure.dart';
import '../../domain/validators/user_profile_validator.dart';
import '../providers/identity_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _orgCodeController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _orgCodeController.dispose();
    super.dispose();
  }

  Future<void> _submitProfileSetup() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authStateProvider);
    final user = authState.value;
    if (user == null) return;

    final success =
        await ref.read(profileControllerProvider.notifier).createProfile(
              uid: user.uid,
              email: user.email ?? '',
              displayName: _displayNameController.text.trim(),
              phone: _phoneController.text.trim(),
              organizationCode: _orgCodeController.text.trim(),
            );

    if (success && mounted) {
      if (GoRouter.maybeOf(context) != null) {
        context.go('/profile');
      } else {
        Navigator.maybePop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final authUser = ref.watch(authStateProvider).value;

    String? errorMessage;
    if (profileState.hasError && profileState.error is IdentityFailure) {
      errorMessage = (profileState.error as IdentityFailure).message;
    } else if (profileState.hasError) {
      errorMessage = 'Failed to set up profile. Please try again.';
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Complete Identity Profile'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CIPHER-X IDENTITY',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'User Profile Setup',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your identity details and attach your organization membership code to access Cipher-X services.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
                const SizedBox(height: 24),
                if (authUser != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Authenticated: ${authUser.email ?? ''}',
                            style: const TextStyle(
                              color: AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                TextFormField(
                  key: const Key('displayName_field'),
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. John Doe',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: UserProfileValidator.validateDisplayName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('phone_field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. +1 555-0199',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: UserProfileValidator.validatePhone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('organization_code_field'),
                  controller: _orgCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Organization Code',
                    hintText: 'e.g. ORG001',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: UserProfileValidator.validateOrganizationCode,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('setup_profile_submit_button'),
                  onPressed:
                      profileState.isLoading ? null : _submitProfileSetup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                  ),
                  child: profileState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Profile & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
