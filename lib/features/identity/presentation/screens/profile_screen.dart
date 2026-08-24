import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/failures/identity_failure.dart';
import '../../domain/validators/user_profile_validator.dart';
import '../providers/identity_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _populateFields(UserProfile profile) {
    if (!_initialized) {
      _displayNameController.text = profile.displayName;
      _phoneController.text = profile.phone;
      _initialized = true;
    }
  }

  Future<void> _updateProfile(String uid) async {
    if (!_formKey.currentState!.validate()) return;

    final success =
        await ref.read(profileControllerProvider.notifier).updateProfile(
              uid: uid,
              displayName: _displayNameController.text.trim(),
              phone: _phoneController.text.trim(),
            );

    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('User Profile & Identity'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('profile_logout_button'),
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: authState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Auth Error: $err',
                style: const TextStyle(color: AppColors.error)),
          ),
          data: (authUser) {
            if (authUser == null) {
              return const Center(child: Text('Not authenticated.'));
            }

            final profileAsync = ref.watch(userProfileProvider(authUser.uid));
            final controllerState = ref.watch(profileControllerProvider);

            return profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  err is IdentityFailure
                      ? err.message
                      : 'Error loading profile.',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              data: (profile) {
                if (profile == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_circle_outlined,
                              size: 64, color: AppColors.primary),
                          const SizedBox(height: 16),
                          const Text(
                            'Profile Not Found',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                              'Please complete your identity setup to proceed.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            key: const Key('go_setup_profile_button'),
                            onPressed: () =>
                                ref.refresh(userProfileProvider(authUser.uid)),
                            child: const Text('Refresh Profile'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                _populateFields(profile);

                final activeProfile = controllerState.value ?? profile;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          color: AppColors.surfaceLight,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.2),
                                  child: Text(
                                    activeProfile.displayName.isNotEmpty
                                        ? activeProfile.displayName[0]
                                            .toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activeProfile.displayName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimaryLight,
                                        ),
                                      ),
                                      Text(
                                        activeProfile.email,
                                        style: const TextStyle(
                                          color: AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Chip(
                                        label: Text(
                                          'Status: ${activeProfile.status.name.toUpperCase()}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        backgroundColor: activeProfile.status ==
                                                UserStatus.active
                                            ? Colors.green
                                                .withValues(alpha: 0.2)
                                            : Colors.orange
                                                .withValues(alpha: 0.2),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'PERMITTED PROFILE EDITS',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('edit_displayName_field'),
                          controller: _displayNameController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: UserProfileValidator.validateDisplayName,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('edit_phone_field'),
                          controller: _phoneController,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          validator: UserProfileValidator.validatePhone,
                        ),
                        const SizedBox(height: 24),
                        if (_isEditing)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      setState(() => _isEditing = false),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  key: const Key('save_profile_button'),
                                  onPressed: controllerState.isLoading
                                      ? null
                                      : () => _updateProfile(authUser.uid),
                                  child: controllerState.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Text('Save Changes'),
                                ),
                              ),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            key: const Key('enable_edit_profile_button'),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Profile'),
                            onPressed: () => setState(() => _isEditing = true),
                          ),
                        const SizedBox(height: 32),
                        Text(
                          'IMMUTABLE SECURITY BOUNDARIES',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: const Icon(Icons.fingerprint),
                          title: const Text('User UID'),
                          subtitle: Text(activeProfile.uid),
                        ),
                        ListTile(
                          leading: const Icon(Icons.business),
                          title: const Text('Organization ID'),
                          subtitle: Text(activeProfile.organizationId),
                        ),
                        ListTile(
                          leading: const Icon(Icons.shield),
                          title: const Text('Assigned Identity Role'),
                          subtitle: Text(activeProfile.role.name.toUpperCase()),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
