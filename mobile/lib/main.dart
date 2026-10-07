import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage.dart';
import 'core/sync/sync_engine.dart';
import 'features/auth/auth_bloc.dart';
import 'features/auth/login_view.dart';
import 'features/auth/register_view.dart';
import 'features/onboarding/onboarding_view.dart';
import 'features/wardrobe/wardrobe_bloc.dart';
import 'features/profile/profile_repository.dart';
import 'features/profile/profile_bloc.dart';
import 'features/profile/visual_profile_repository.dart';
import 'features/profile/visual_profile_bloc.dart';
import 'features/money/money_repository.dart';
import 'features/money/money_bloc.dart';
import 'features/wellness/wellness_repository.dart';
import 'features/wellness/wellness_bloc.dart';
import 'features/learning/learning_repository.dart';
import 'features/learning/learning_bloc.dart';
import 'features/personal_ai/personal_ai_repository.dart';
import 'features/personal_ai/personal_ai_bloc.dart';
import 'features/shell/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient();
  final syncEngine = SyncEngine(apiClient: apiClient);

  runApp(OmniPresenceApp(
    apiClient: apiClient,
    syncEngine: syncEngine,
  ));
}

class OmniPresenceApp extends StatefulWidget {
  final ApiClient apiClient;
  final SyncEngine syncEngine;

  const OmniPresenceApp({
    super.key,
    required this.apiClient,
    required this.syncEngine,
  }) : super();

  @override
  State<OmniPresenceApp> createState() => _OmniPresenceAppState();
}

class _OmniPresenceAppState extends State<OmniPresenceApp> {
  bool _hasCompletedOnboarding = false;
  bool _isCheckingOnboarding = true;
  bool _isInitialSessionCheck = true;
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    _checkInitialOnboardingState();
  }

  Future<void> _checkInitialOnboardingState() async {
    final completed = await SecureStorage.isOnboardingCompleted();
    if (mounted) {
      setState(() {
        _hasCompletedOnboarding = completed;
        _isCheckingOnboarding = false;
      });
    }
  }

  void _onOnboardingComplete() async {
    await SecureStorage.setOnboardingCompleted(true);
    if (mounted) {
      setState(() {
        _hasCompletedOnboarding = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: widget.apiClient),
        RepositoryProvider<ProfileRepository>(
          create: (_) => ProfileRepository(apiClient: widget.apiClient),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(apiClient: widget.apiClient)..add(SessionCheckRequested()),
          ),
          BlocProvider<WardrobeBloc>(
            create: (_) => WardrobeBloc(
              apiClient: widget.apiClient,
              syncEngine: widget.syncEngine,
            )..add(const LoadWardrobeRequested()),
          ),
          BlocProvider<ProfileBloc>(
            create: (_) => ProfileBloc(
              repository: ProfileRepository(apiClient: widget.apiClient),
            ),
          ),
          BlocProvider<VisualProfileBloc>(
            create: (_) => VisualProfileBloc(
              repository: VisualProfileRepository(apiClient: widget.apiClient),
            )..add(LoadVisualProfileEvent()),
          ),
          BlocProvider<MoneyBloc>(
            create: (_) => MoneyBloc(
              repository: MoneyRepository(apiClient: widget.apiClient),
            )..add(const LoadMoneyData()),
          ),
          BlocProvider<WellnessBloc>(
            create: (_) => WellnessBloc(
              repository: WellnessRepository(apiClient: widget.apiClient),
            )..add(const LoadWellnessData()),
          ),
          BlocProvider<LearningBloc>(
            create: (_) => LearningBloc(
              repository: LearningRepository(apiClient: widget.apiClient),
            )..add(const LoadLearningData()),
          ),
          BlocProvider<PersonalAiBloc>(
            create: (_) => PersonalAiBloc(
              repository: PersonalAiRepository(apiClient: widget.apiClient),
            )..add(const LoadPersonalAiOverviewEvent()),
          ),
        ],
        child: MaterialApp(
          title: 'OmniXPERIENCE',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: _isCheckingOnboarding
            ? const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              )
            : BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (_isInitialSessionCheck && state is! AuthInitial && state is! AuthLoading) {
                    setState(() => _isInitialSessionCheck = false);
                  }
                  if (state is Authenticated) {
                    _checkInitialOnboardingState();
                    context.read<ProfileBloc>().add(LoadProfileRequested());
                    context.read<VisualProfileBloc>().add(LoadVisualProfileEvent());
                    context.read<MoneyBloc>().add(const LoadMoneyData(forceRefresh: true));
                    context.read<WellnessBloc>().add(const LoadWellnessData(forceRefresh: true));
                    context.read<LearningBloc>().add(const LoadLearningData(forceRefresh: true));
                    context.read<PersonalAiBloc>().add(const LoadPersonalAiOverviewEvent());
                  }
                  if (state is Unauthenticated) {
                    setState(() {
                      _hasCompletedOnboarding = false;
                    });
                    context.read<ProfileBloc>().add(ResetProfileRequested());
                    context.read<VisualProfileBloc>().add(ResetVisualProfileEvent());
                  }
                },
                builder: (context, state) {
                  // Only show full splash during first-time cold startup session restore
                  if (_isInitialSessionCheck && state is AuthLoading) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (state is Authenticated) {
                    return BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, profileState) {
                        final bool isProfileOnboarded = profileState is ProfileLoaded
                            ? profileState.profile.onboardingCompleted
                            : false;
                        if (!_hasCompletedOnboarding && !isProfileOnboarded) {
                          return OnboardingView(
                            onComplete: _onOnboardingComplete,
                          );
                        }
                        return const AppShell();
                      },
                    );
                  }

                  if (_showRegister) {
                    return RegisterView(
                      onNavigateToLogin: () => setState(() => _showRegister = false),
                      onRegisterSuccess: () {
                        setState(() => _showRegister = false);
                        _checkInitialOnboardingState();
                      },
                    );
                  }

                  return LoginView(
                    onNavigateToRegister: () => setState(() => _showRegister = true),
                    onLoginSuccess: () {
                      _checkInitialOnboardingState();
                    },
                  );
                },
              ),
        ),
      ),
    );
  }
}
