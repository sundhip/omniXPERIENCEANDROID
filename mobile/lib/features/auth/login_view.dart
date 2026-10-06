import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_text_field.dart';
import 'auth_bloc.dart';

class LoginView extends StatefulWidget {
  final VoidCallback onNavigateToRegister;
  final VoidCallback onLoginSuccess;

  const LoginView({
    Key? key,
    required this.onNavigateToRegister,
    required this.onLoginSuccess,
  }) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController(text: "alex.chen@omnipresence.ai");
  final _passwordController = TextEditingController(text: "SecurePassword123!");

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppGeometry.sectionPadding),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is Authenticated) {
                  widget.onLoginSuccess();
                }
              },
              builder: (context, state) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, color: colors.primary, size: 38),
                    const SizedBox(height: AppGeometry.gapSmall),
                    Text(
                      'OMNIPRESENCE',
                      style: AppTypography.display.copyWith(
                        color: colors.textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppGeometry.gapSmall),
                    Text(
                      'Your intelligent personal presence layer.',
                      style: AppTypography.body.copyWith(color: colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppGeometry.gapLarge * 1.5),
                    AppTextField(
                      label: 'Email',
                      hint: 'Enter your email',
                      controller: _emailController,
                    ),
                    const SizedBox(height: AppGeometry.gapNormal),
                    AppTextField(
                      label: 'Password',
                      hint: '????????',
                      controller: _passwordController,
                      obscureText: true,
                    ),
                    const SizedBox(height: AppGeometry.gapLarge),
                    AppButton(
                      label: 'Sign In',
                      isLoading: state is AuthLoading,
                      onPressed: () {
                        context.read<AuthBloc>().add(
                          LoginSubmitted(_emailController.text, _passwordController.text),
                        );
                      },
                    ),
                    const SizedBox(height: AppGeometry.gapNormal),
                    SecondaryButton(
                      label: 'Create Account',
                      onPressed: widget.onNavigateToRegister,
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
