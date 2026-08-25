import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/app_text_field.dart';
import '../../../../guards/domain/entities/guard.dart';
import '../../../../guards/presentation/providers/guard_providers.dart';
import '../../../../identity/presentation/providers/identity_providers.dart';

class GuardFormScreen extends ConsumerStatefulWidget {
  final Guard? existingGuard;

  const GuardFormScreen({super.key, this.existingGuard});

  @override
  ConsumerState<GuardFormScreen> createState() => _GuardFormScreenState();
}

class _GuardFormScreenState extends ConsumerState<GuardFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _employeeIdController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  bool get isEditing => widget.existingGuard != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingGuard?.name ?? '',
    );
    _employeeIdController = TextEditingController(
      text: widget.existingGuard?.employeeId ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.existingGuard?.phone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.existingGuard?.email ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final profileAsync = ref.read(currentUserProfileProvider);
    final profile = profileAsync.asData?.value;

    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session error: No organization context.'),
        ),
      );
      return;
    }

    final guard = Guard(
      guardId: isEditing ? widget.existingGuard!.guardId : '',
      organizationId: profile.organizationId,
      name: _nameController.text.trim(),
      employeeId: _employeeIdController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      status: isEditing ? widget.existingGuard!.status : GuardStatus.active,
      createdAt: isEditing ? widget.existingGuard!.createdAt : null,
      // photoUrl: TODO: Add photo upload integration
    );

    final controller = ref.read(guardControllerProvider.notifier);
    final success = isEditing
        ? await controller.updateGuard(guard)
        : await controller.createGuard(guard);

    if (success && mounted) {
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save guard. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(guardControllerProvider);
    final isLoading = controllerState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Guard' : 'Add New Guard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TODO: Add Photo Upload Widget here
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                child: Icon(
                  Icons.add_a_photo_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Photo Upload (Coming soon)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'e.g., John Doe',
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the guard\'s full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _employeeIdController,
                label: 'Employee ID',
                hint: 'e.g., GRD-1024',
                prefixIcon: const Icon(Icons.badge_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an employee ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'e.g., +1234567890',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number';
                  }
                  // Basic phone validation
                  if (value.length < 7) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailController,
                label: 'Email (Optional)',
                hint: 'e.g., john@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),
              FilledButton(
                onPressed: isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Create Guard',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
