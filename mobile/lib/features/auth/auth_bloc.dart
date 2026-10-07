import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class SessionCheckRequested extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginSubmitted(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  const RegisterSubmitted({
    required this.email,
    required this.password,
    required this.displayName,
  });
  @override
  List<Object?> get props => [email, password, displayName];
}

class LogoutRequested extends AuthEvent {}

class DeleteAccountRequested extends AuthEvent {}

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final String userId;
  final String email;
  final String displayName;

  const Authenticated({
    required this.userId,
    required this.email,
    required this.displayName,
  });

  @override
  List<Object?> get props => [userId, email, displayName];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient apiClient;

  AuthBloc({required this.apiClient}) : super(AuthInitial()) {
    on<SessionCheckRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final token = await SecureStorage.getToken();
        final userId = await SecureStorage.getUserId();
        final email = await SecureStorage.getUserEmail() ?? 'user@omnipresence.ai';
        final displayName = await SecureStorage.getDisplayName() ?? email.split('@')[0];

        if (token != null && token.isNotEmpty && userId != null) {
          // Attempt token validation against backend if reachable
          try {
            final res = await apiClient.dio.get('/auth/me');
            final verifiedEmail = res.data['email'] ?? email;
            final verifiedId = res.data['id'] ?? userId;
            emit(Authenticated(
              userId: verifiedId,
              email: verifiedEmail,
              displayName: displayName,
            ));
          } on DioException catch (dioErr) {
            if (dioErr.response?.statusCode == 401) {
              // Token expired or revoked
              await SecureStorage.clearSession();
              emit(Unauthenticated());
              return;
            }
            // If server connection failed/offline, preserve existing valid cached session
            emit(Authenticated(
              userId: userId,
              email: email,
              displayName: displayName,
            ));
          }
        } else {
          emit(Unauthenticated());
        }
      } catch (e) {
        emit(Unauthenticated());
      }
    });

    on<LoginSubmitted>((event, emit) async {
      if (event.email.trim().isEmpty || event.password.trim().isEmpty) {
        emit(const AuthError('Please enter both email and password.'));
        return;
      }
      emit(AuthLoading());
      try {
        final res = await apiClient.dio.post('/auth/login', data: {
          'email': event.email.trim(),
          'password': event.password,
        });

        final token = res.data['access_token'] as String;
        final userId = res.data['user_id'] as String;
        final email = res.data['email'] as String? ?? event.email.trim();
        final displayName = email.split('@')[0];

        await SecureStorage.saveSession(
          token: token,
          userId: userId,
          email: email,
          displayName: displayName,
        );

        emit(Authenticated(
          userId: userId,
          email: email,
          displayName: displayName,
        ));
      } catch (e) {
        emit(AuthError(ApiClient.getErrorMessage(e)));
      }
    });

    on<RegisterSubmitted>((event, emit) async {
      if (event.email.trim().isEmpty || event.password.trim().isEmpty) {
        emit(const AuthError('Please provide all required fields.'));
        return;
      }
      emit(AuthLoading());
      try {
        final res = await apiClient.dio.post('/auth/register', data: {
          'email': event.email.trim(),
          'password': event.password,
          'display_name': event.displayName.trim().isEmpty
              ? event.email.trim().split('@')[0]
              : event.displayName.trim(),
        });

        final token = res.data['access_token'] as String;
        final userId = res.data['user_id'] as String;
        final email = res.data['email'] as String? ?? event.email.trim();
        final displayName = event.displayName.trim().isNotEmpty
            ? event.displayName.trim()
            : email.split('@')[0];

        await SecureStorage.saveSession(
          token: token,
          userId: userId,
          email: email,
          displayName: displayName,
        );

        emit(Authenticated(
          userId: userId,
          email: email,
          displayName: displayName,
        ));
      } catch (e) {
        emit(AuthError(ApiClient.getErrorMessage(e)));
      }
    });

    on<LogoutRequested>((event, emit) async {
      await SecureStorage.clearSession();
      emit(Unauthenticated());
    });

    on<DeleteAccountRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await apiClient.dio.delete('/auth/me');
      } catch (_) {
        // Purge session regardless of network status
      } finally {
        await SecureStorage.clearSession();
        emit(Unauthenticated());
      }
    });
  }
}
