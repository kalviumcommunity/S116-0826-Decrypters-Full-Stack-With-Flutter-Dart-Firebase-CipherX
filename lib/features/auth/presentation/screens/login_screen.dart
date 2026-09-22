import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/failures/auth_failure.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (ref.read(authControllerProvider).isLoading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    await controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _handleDemoLogin(String email) async {
    if (ref.read(authControllerProvider).isLoading) return;
    FocusScope.of(context).unfocus();
    _emailController.text = email;
    _passwordController.text = 'Password123!';
    final controller = ref.read(authControllerProvider.notifier);
    await controller.signIn(
      email: email,
      password: 'Password123!',
    );
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
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Reference-driven Header with Official Cipher-X Logo & Brand Titles
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/images/cipher_x_logo.png',
                          width: 54,
                          height: 54,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CIPHER-X',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineLarge(
                      color: AppColors.textPrimaryLight,
                    ).copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Security Workforce Authentication',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.textSecondaryLight,
                    ).copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Demo Credentials Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 14.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.bolt,
                              color: AppColors.primaryLight,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Quick Demo Sign-In',
                              style: AppTextStyles.caption(
                                color: AppColors.primaryLight,
                              ).copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: [
                            ActionChip(
                              key: const Key('demo_login_admin_button'),
                              avatar: const Icon(
                                Icons.admin_panel_settings,
                                size: 15,
                                color: AppColors.primary,
                              ),
                              label: const Text('Admin'),
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                  color: AppColors.borderLight),
                              labelStyle: AppTextStyles.caption(
                                      color: AppColors.textPrimaryLight)
                                  .copyWith(fontWeight: FontWeight.w600),
                              onPressed: isLoading
                                  ? null
                                  : () => _handleDemoLogin('admin@cipherx.org'),
                            ),
                            ActionChip(
                              key: const Key('demo_login_guard_button'),
                              avatar: const Icon(
                                Icons.shield,
                                size: 15,
                                color: AppColors.primary,
                              ),
                              label: const Text('Guard'),
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                  color: AppColors.borderLight),
                              labelStyle: AppTextStyles.caption(
                                      color: AppColors.textPrimaryLight)
                                  .copyWith(fontWeight: FontWeight.w600),
                              onPressed: isLoading
                                  ? null
                                  : () => _handleDemoLogin('guard@cipherx.org'),
                            ),
                            ActionChip(
                              key: const Key('demo_login_supervisor_button'),
                              avatar: const Icon(
                                Icons.supervised_user_circle,
                                size: 15,
                                color: AppColors.primary,
                              ),
                              label: const Text('Supervisor'),
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                  color: AppColors.borderLight),
                              labelStyle: AppTextStyles.caption(
                                      color: AppColors.textPrimaryLight)
                                  .copyWith(fontWeight: FontWeight.w600),
                              onPressed: isLoading
                                  ? null
                                  : () => _handleDemoLogin(
                                        'supervisor@cipherx.org',
                                      ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (errorMessage != null) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorBadgeBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextFormField(
                    key: const Key('email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'e.g. admin@cipherx.org or your email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    validator: AuthValidators.validateEmail,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('password_field'),
                    controller: _passwordController,
                    obscureText: _isPasswordObscured,
                    autofillHints: const <String>[AutofillHints.password],
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter password (min 6 characters)',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      filled: true,
                      fillColor: Colors.white,
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    validator: AuthValidators.validatePassword,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('forgot_password_button'),
                      onPressed: isLoading
                          ? null
                          : () {
                              if (GoRouter.maybeOf(context) != null) {
                                context.push('/forgot-password');
                              }
                            },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Signature AppPillButton
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppColors.cardWineGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('login_submit_button'),
                        onTap: isLoading ? null : _handleLogin,
                        borderRadius: BorderRadius.circular(28),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 34),
                              Expanded(
                                child: Center(
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'SIGN IN',
                                          style: AppTextStyles.button(
                                                  color: Colors.white)
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                ),
                              ),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Don't have an account?",
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      TextButton(
                        key: const Key('register_navigation_link'),
                        onPressed: isLoading
                            ? null
                            : () {
                                if (GoRouter.maybeOf(context) != null) {
                                  context.push('/register');
                                }
                              },
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 3 Feature Capsules (matching reference design Screen 1)
                  Row(
                    children: [
                      _buildFeatureCapsule(
                        context,
                        icon: Icons.shield_outlined,
                        title: 'Verified\nCheck-In',
                      ),
                      const SizedBox(width: 8),
                      _buildFeatureCapsule(
                        context,
                        icon: Icons.location_on_outlined,
                        title: 'Geofenced\nProtection',
                      ),
                      const SizedBox(width: 8),
                      _buildFeatureCapsule(
                        context,
                        icon: Icons.bolt_outlined,
                        title: 'Instant\nIncident Ops',
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

  Widget _buildFeatureCapsule(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.accentRose,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(
                color: AppColors.textPrimaryLight,
              ).copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
