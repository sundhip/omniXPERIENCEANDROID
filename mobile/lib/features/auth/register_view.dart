import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/components/state_banners.dart';
import 'auth_bloc.dart';

class RegisterView extends StatefulWidget {
  final VoidCallback onNavigateToLogin;
  final VoidCallback onRegisterSuccess;

  const RegisterView({super.key, required this.onNavigateToLogin,
    required this.onRegisterSuccess,
  });

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _clientValidationError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitRegistration() {
    setState(() => _clientValidationError = null);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _clientValidationError = 'Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      setState(() => _clientValidationError = 'Password must be at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _clientValidationError = 'Passwords do not match.');
      return;
    }

    context.read<AuthBloc>().add(RegisterSubmitted(
      email: email,
      password: password,
      displayName: name.isNotEmpty ? name : email.split('@')[0],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: widget.onNavigateToLogin,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppGeometry.sectionPadding),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is Authenticated) {
                  widget.onRegisterSuccess();
                }
              },
              builder: (context, state) {
                final errorMessage = _clientValidationError ??
                    (state is AuthError ? state.message : null);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, color: colors.primary, size: 38),
                    const SizedBox(height: AppGeometry.gapSmall),
                    Text(
                      'CREATE ACCOUNT',
                      style: AppTypography.display.copyWith(
                        color: colors.textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppGeometry.gapSmall),
                    Text(
                      'Join OmniPresence to start curating your wardrobe.',
                      style: AppTypography.body.copyWith(color: colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppGeometry.gapLarge),
                    if (errorMessage != null) ...[
                      ErrorBanner(
                        message: errorMessage,
                        onDismiss: () => setState(() => _clientValidationError = null),
                      ),
                      const SizedBox(height: AppGeometry.gapNormal),
                    ],
                    AppTextField(
                      label: 'Full Name',
                      hint: 'e.g. Alex Chen',
                      controller: _nameController,
                    ),
                    const SizedBox(height: AppGeometry.gapNormal),
                    AppTextField(
                      label: 'Email Address',
                      hint: 'name@example.com',
                      controller: _emailController,
                    ),
                    const SizedBox(height: AppGeometry.gapNormal),
                    AppTextField(
                      label: 'Password',
                      hint: 'At least 6 characters',
                      controller: _passwordController,
                      obscureText: true,
                    ),
                    const SizedBox(height: AppGeometry.gapNormal),
                    AppTextField(
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      controller: _confirmPasswordController,
                      obscureText: true,
                    ),
                    const SizedBox(height: AppGeometry.gapLarge),
                    AppButton(
                      label: 'Sign Up',
                      isLoading: state is AuthLoading,
                      onPressed: _submitRegistration,
                    ),
                    const SizedBox(height: AppGeometry.gapNormal),
                    SecondaryButton(
                      label: 'Already have an account? Sign In',
                      onPressed: widget.onNavigateToLogin,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
