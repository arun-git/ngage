import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngage/providers/auth_providers.dart';
import 'package:ngage/services/enhanced_auth_service.dart';
import 'package:ngage/repositories/user_repository.dart';
import 'package:ngage/repositories/member_repository.dart';
import 'package:ngage/repositories/repository_providers.dart';
import 'package:ngage/models/user.dart' as app_user;
import 'package:ngage/models/member.dart';

// Generate mocks
@GenerateMocks([
  EnhancedAuthService,
  UserRepository,
  MemberRepository,
])
import 'auth_providers_test.mocks.dart';

void main() {
  group('AuthStateNotifier', () {
    late MockEnhancedAuthService mockEnhancedAuthService;
    late MockUserRepository mockUserRepository;
    late MockMemberRepository mockMemberRepository;
    late ProviderContainer container;

    setUp(() {
      mockEnhancedAuthService = MockEnhancedAuthService();
      mockUserRepository = MockUserRepository();
      mockMemberRepository = MockMemberRepository();

      container = ProviderContainer(
        overrides: [
          enhancedAuthServiceProvider.overrideWithValue(mockEnhancedAuthService),
          userRepositoryProvider.overrideWithValue(mockUserRepository),
          memberRepositoryProvider.overrideWithValue(mockMemberRepository),
        ],
      );

      // Setup default auth state changes stream
      when(mockEnhancedAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(null));
    });

    tearDown(() {
      container.dispose();
    });

    group('initialization', () {
      test('should start with initial state', () {
        // Act
        final authState = container.read(authStateProvider);

        // Assert
        expect(authState.state, equals(AuthState.initial));
        expect(authState.user, isNull);
        expect(authState.memberProfiles, isNull);
        expect(authState.currentMember, isNull);
        expect(authState.errorMessage, isNull);
      });

      test('should handle user signed in from auth state changes', () async {
        // Arrange
        final user = _createTestUser();
        final memberProfiles = [_createTestMember()];
        
        when(mockEnhancedAuthService.authStateChanges)
            .thenAnswer((_) => Stream.value(user));
        when(mockMemberRepository.getUserMembers(user.id))
            .thenAnswer((_) async => memberProfiles);
        when(mockMemberRepository.getMember(any))
            .thenAnswer((_) async => memberProfiles.first);

        // Act
        final notifier = container.read(authStateProvider.notifier);
        
        // Wait for the stream to emit
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final authState = container.read(authStateProvider);
        expect(authState.state, equals(AuthState.authenticated));
        expect(authState.user, equals(user));
        expect(authState.memberProfiles, equals(memberProfiles));
      });

      test('should handle user signed out from auth state changes', () async {
        // Arrange
        when(mockEnhancedAuthService.authStateChanges)
            .thenAnswer((_) => Stream.value(null));

        // Act
        final notifier = container.read(authStateProvider.notifier);
        
        // Wait for the stream to emit
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final authState = container.read(authStateProvider);
        expect(authState.state, equals(AuthState.unauthenticated));
        expect(authState.user, isNull);
      });
    });

    group('signInWithEmail', () {
      test('should handle successful sign in', () async {
        // Arrange
        final user = _createTestUser();
        final claimedMembers = [_createTestMember()];
        final authResult = AuthResult(
          user: user,
          claimedMembers: claimedMembers,
          isNewUser: false,
        );

        when(mockEnhancedAuthService.signInWithEmail('test@example.com', 'password123'))
            .thenAnswer((_) async => authResult);

        // Act
        final notifier = container.read(authStateProvider.notifier);
        await notifier.signInWithEmail('test@example.com', 'password123');

        // Assert
        final authState = container.read(authStateProvider);
        expect(authState.memberProfiles, equals(claimedMembers));
        expect(authState.currentMember, equals(claimedMembers.first));
        verify(mockEnhancedAuthService.signInWithEmail('test@example.com', 'password123')).called(1);
      });

      test('should handle sign in error', () async {
        // Arrange
        when(mockEnhancedAuthService.signInWithEmail('test@example.com', 'wrongpassword'))
            .thenThrow(Exception('Invalid credentials'));

        // Act
        final notifier = container.read(authStateProvider.notifier);
        await notifier.signInWithEmail('test@example.com', 'wrongpassword');

        // Assert
        final authState = container.read(authStateProvider);
        expect(authState.state, equals(AuthState.error));
        expect(authState.errorMessage, contains('Invalid credentials'));
      });
    });

    group('createUserWithEmailAndPassword', () {
      test('should handle successful account creation', () async {
        // Arrange
        final user = _createTestUser();
        final claimedMembers = [_createTestMember()];
        final authResult = AuthResult(
          user: user,
          claimedMembers: claimedMembers,
          isNewUser: true,
        );

        when(mockEnhancedAuthService.createUserWithEmailAndPassword('test@example.com', 'password123'))
            .thenAnswer((_) async => authResult);

        // Act
        final notifier = container.read(authStateProvider.notifier);
        await notifier.createUserWithEmailAndPassword('test@example.com', 'password123');

        // Assert
        final authState = container.read(authStateProvider);
        expect(authState.memberProfiles, equals(claimedMembers));
        expect(authState.currentMember, equals(claimedMembers.first));
        verify(mockEnhancedAuthService.createUserWithEmailAndPassword('test@example.com', 'password123')).called(1);
      });
    });

    group('signOut', () {
      test('should call enhanced auth service signOut', () async {
        // Arrange
        when(mockEnhancedAuthService.signOut()).thenAnswer((_) async {});

        // Act
        final notifier = container.read(authStateProvider.notifier);
        await notifier.signOut();

        // Assert
        verify(mockEnhancedAuthService.signOut()).called(1);
      });

      test('should handle sign out error', () async {
        // Arrange
        when(mockEnhancedAuthService.signOut())
            .thenThrow(Exception('Sign out failed'));

        // Act
        final notifier = container.read(authStateProvider.notifier);
        await notifier.signOut();

        // Assert
        final authState = container.read(authStateProvider);
        expect(authState.state, equals(AuthState.error));
        expect(authState.errorMessage, contains('Sign out failed'));
      });
    });

    group('switchMemberProfile', () {
      test('should switch to different member profile', () async {
        // Arrange
        final user = _createTestUser();
        final newMember = _createTestMember(id: 'new-member-id');
        
        // Set initial state with authenticated user
        container.read(authStateProvider.notifier).state = AuthStateData(
          state: AuthState.authenticated,
          user: user,
          memberProfiles: [_createTestMember(), newMember],
          currentMember: _createTestMember(),
        );

        when(mockUserRepository.updateDefaultMember(user.id, 'new-member-id'))
            .thenAnswer((_) async {});
        when(mockMemberRepository.getMember('new-member-id'))
            .thenAnswer((_) async => newMember);

        // Act
        final notifier = container.read(authStateProvider.notifier);
        await notifier.switchMemberProfile('new-member-id');

        // Assert
        final authState = container.read(authStateProvider);
        expect(authState.currentMember, equals(newMember));
        expect(authState.user?.defaultMember, equals('new-member-id'));
        verify(mockUserRepository.updateDefaultMember(user.id, 'new-member-id')).called(1);
        verify(mockMemberRepository.getMember('new-member-id')).called(1);
      });

      test('should handle switch member profile error', () async {
        // Arrange
        final user = _createTestUser();
        
        container.read(authStateProvider.notifier).state = AuthStateData(
          state: AuthState.authenticated,
          user: user,
        );

        when(mockUserRepository.updateDefaultMember(user.id, 'new-member-id'))
            .thenThrow(Exception('Update failed'));

        // Act
        final notifier = container.read(authStateProvider.notifier);
        await notifier.switchMemberProfile('new-member-id');

        // Assert
        final authState = container.read(authStateProvider);
        expect(authState.state, equals(AuthState.error));
        expect(authState.errorMessage, contains('Failed to switch member profile'));
      });
    });

    group('clearError', () {
      test('should clear error state when authenticated', () {
        // Arrange
        final user = _createTestUser();
        container.read(authStateProvider.notifier).state = AuthStateData(
          state: AuthState.error,
          user: user,
          errorMessage: 'Some error',
        );

        // Act
        final notifier = container.read(authStateProvider.notifier);
        notifier.clearError();

        // Assert
        final authState = container.read(authStateProvider);
        expect(authState.state, equals(AuthState.authenticated));
        expect(authState.errorMessage, isNull);
      });

      test('should clear error state when unauthenticated', () {
        // Arrange
        container.read(authStateProvider.notifier).state = const AuthStateData(
          state: AuthState.error,
          errorMessage: 'Some error',
        );

        // Act
        final notifier = container.read(authStateProvider.notifier);
        notifier.clearError();

        // Assert
        final authState = container.read(authStateProvider);
        expect(authState.state, equals(AuthState.unauthenticated));
        expect(authState.errorMessage, isNull);
      });
    });
  });

  group('Provider tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('currentUserProvider should return user from auth state', () {
      // Arrange
      final user = _createTestUser();
      container.read(authStateProvider.notifier).state = AuthStateData(
        state: AuthState.authenticated,
        user: user,
      );

      // Act
      final currentUser = container.read(currentUserProvider);

      // Assert
      expect(currentUser, equals(user));
    });

    test('currentMemberProvider should return current member from auth state', () {
      // Arrange
      final member = _createTestMember();
      container.read(authStateProvider.notifier).state = AuthStateData(
        state: AuthState.authenticated,
        currentMember: member,
      );

      // Act
      final currentMember = container.read(currentMemberProvider);

      // Assert
      expect(currentMember, equals(member));
    });

    test('memberProfilesProvider should return member profiles from auth state', () {
      // Arrange
      final memberProfiles = [_createTestMember(), _createTestMember(id: 'member-2')];
      container.read(authStateProvider.notifier).state = AuthStateData(
        state: AuthState.authenticated,
        memberProfiles: memberProfiles,
      );

      // Act
      final profiles = container.read(memberProfilesProvider);

      // Assert
      expect(profiles, equals(memberProfiles));
    });

    test('isAuthenticatedProvider should return true when authenticated', () {
      // Arrange
      final user = _createTestUser();
      container.read(authStateProvider.notifier).state = AuthStateData(
        state: AuthState.authenticated,
        user: user,
      );

      // Act
      final isAuthenticated = container.read(isAuthenticatedProvider);

      // Assert
      expect(isAuthenticated, isTrue);
    });

    test('isAuthLoadingProvider should return true when loading', () {
      // Arrange
      container.read(authStateProvider.notifier).state = const AuthStateData(
        state: AuthState.loading,
      );

      // Act
      final isLoading = container.read(isAuthLoadingProvider);

      // Assert
      expect(isLoading, isTrue);
    });

    test('authErrorProvider should return error message when in error state', () {
      // Arrange
      const errorMessage = 'Authentication failed';
      container.read(authStateProvider.notifier).state = const AuthStateData(
        state: AuthState.error,
        errorMessage: errorMessage,
      );

      // Act
      final error = container.read(authErrorProvider);

      // Assert
      expect(error, equals(errorMessage));
    });
  });
}

// Helper functions
app_user.User _createTestUser() {
  final now = DateTime.now();
  return app_user.User(
    id: 'test-user-id',
    email: 'test@example.com',
    phone: null,
    defaultMember: null,
    createdAt: now,
    updatedAt: now,
  );
}

Member _createTestMember({String? id}) {
  final now = DateTime.now();
  return Member(
    id: id ?? 'test-member-id',
    userId: 'test-user-id',
    email: 'test@example.com',
    phone: null,
    externalId: null,
    firstName: 'Test',
    lastName: 'User',
    category: null,
    title: null,
    profilePhoto: null,
    bio: null,
    isActive: true,
    importedAt: null,
    claimedAt: now,
    createdAt: now,
    updatedAt: now,
  );
}