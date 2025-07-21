import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'auth_service.dart';

/// Provider for the current authenticated user
/// Returns null if no user is authenticated
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for authentication state (boolean)
/// Returns true if user is authenticated, false otherwise
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for the current user ID
/// Returns null if no user is authenticated
final currentUserIdProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.id,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for authentication loading state
/// Returns true while authentication state is being determined
final authLoadingProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.isLoading;
});

/// Provider for authentication error
/// Returns error if authentication failed, null otherwise
final authErrorProvider = Provider<Object?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.hasError ? userAsync.error : null;
});