import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:ngage/models/member.dart';
import 'package:ngage/models/user.dart';
import 'package:ngage/repositories/member_repository.dart';
import 'package:ngage/repositories/user_repository.dart';
import 'package:ngage/services/member_claim_service.dart';
import 'package:ngage/services/member_service.dart';

import '../providers/auth_providers_test.mocks.dart';
import 'enhanced_auth_service_test.mocks.dart';

@GenerateMocks([MemberRepository, UserRepository, MemberClaimService])
void main() {
  group('MemberService', () {
    late MemberService memberService;
    late MockMemberRepository mockMemberRepository;
    late MockUserRepository mockUserRepository;
    late MockMemberClaimService mockMemberClaimService;

    setUp(() {
      mockMemberRepository = MockMemberRepository();
      mockUserRepository = MockUserRepository();
      mockMemberClaimService = MockMemberClaimService();
      
      memberService = MemberServiceImpl(
        memberRepository: mockMemberRepository,
        userRepository: mockUserRepository,
        memberClaimService: mockMemberClaimService,
      );
    });

    group('getUserMembers', () {
      test('should return user members successfully', () async {
        // Arrange
        const userId = 'user123';
        final expectedMembers = [
          Member(
            id: 'member1',
            userId: userId,
            email: 'test1@example.com',
            firstName: 'John',
            lastName: 'Doe',
            createdAt: DateTime(2023, 1, 1),
            updatedAt: DateTime(2023, 1, 1),
          ),
          Member(
            id: 'member2',
            userId: userId,
            email: 'test2@example.com',
            firstName: 'Jane',
            lastName: 'Smith',
            createdAt: DateTime(2023, 1, 1),
            updatedAt: DateTime(2023, 1, 1),
          ),
        ];

        when(mockMemberRepository.getUserMembers(userId))
            .thenAnswer((_) async => expectedMembers);

        // Act
        final result = await memberService.getUserMembers(userId);

        // Assert
        expect(result, equals(expectedMembers));
        verify(mockMemberRepository.getUserMembers(userId)).called(1);
      });

      test('should throw exception when repository fails', () async {
        // Arrange
        const userId = 'user123';
        when(mockMemberRepository.getUserMembers(userId))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => memberService.getUserMembers(userId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get user members'),
          )),
        );
      });
    });

    group('getCurrentMember', () {
      test('should return current member when user has default member', () async {
        // Arrange
        const userId = 'user123';
        const memberId = 'member123';
        final user = User(
          id: userId,
          email: 'test@example.com',
          defaultMember: memberId,
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
        );
        final member = Member(
          id: memberId,
          userId: userId,
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
        );

        when(mockUserRepository.getUser(userId))
            .thenAnswer((_) async => user);
        when(mockMemberRepository.getMember(memberId))
            .thenAnswer((_) async => member);

        // Act
        final result = await memberService.getCurrentMember(userId);

        // Assert
        expect(result, equals(member));
        verify(mockUserRepository.getUser(userId)).called(1);
        verify(mockMemberRepository.getMember(memberId)).called(1);
      });

      test('should return null when user has no default member', () async {
        // Arrange
        const userId = 'user123';
        final user = User(
          id: userId,
          email: 'test@example.com',
          defaultMember: null,
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
        );

        when(mockUserRepository.getUser(userId))
            .thenAnswer((_) async => user);

        // Act
        final result = await memberService.getCurrentMember(userId);

        // Assert
        expect(result, isNull);
        verify(mockUserRepository.getUser(userId)).called(1);
        verifyNever(mockMemberRepository.getMember(any));
      });

      test('should return null when user not found', () async {
        // Arrange
        const userId = 'user123';
        when(mockUserRepository.getUser(userId))
            .thenAnswer((_) async => null);

        // Act
        final result = await memberService.getCurrentMember(userId);

        // Assert
        expect(result, isNull);
        verify(mockUserRepository.getUser(userId)).called(1);
      });
    });

    group('switchDefaultMember', () {
      test('should switch default member successfully', () async {
        // Arrange
        const userId = 'user123';
        const memberId = 'member123';
        final member = Member(
          id: memberId,
          userId: userId,
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          isActive: true,
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
        );

        when(mockMemberRepository.getMember(memberId))
            .thenAnswer((_) async => member);
        when(mockMemberClaimService.setDefaultMember(userId, memberId))
            .thenAnswer((_) async {});

        // Act
        await memberService.switchDefaultMember(userId, memberId);

        // Assert
        verify(mockMemberRepository.getMember(memberId)).called(1);
        verify(mockMemberClaimService.setDefaultMember(userId, memberId)).called(1);
      });

      test('should throw exception when member not found', () async {
        // Arrange
        const userId = 'user123';
        const memberId = 'member123';

        when(mockMemberRepository.getMember(memberId))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => memberService.switchDefaultMember(userId, memberId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Member not found'),
          )),
        );
      });

      test('should throw exception when member belongs to different user', () async {
        // Arrange
        const userId = 'user123';
        const memberId = 'member123';
        final member = Member(
          id: memberId,
          userId: 'different_user',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
        );

        when(mockMemberRepository.getMember(memberId))
            .thenAnswer((_) async => member);

        // Act & Assert
        expect(
          () => memberService.switchDefaultMember(userId, memberId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Member does not belong to user'),
          )),
        );
      });

      test('should throw exception when member is inactive', () async {
        // Arrange
        const userId = 'user123';
        const memberId = 'member123';
        final member = Member(
          id: memberId,
          userId: userId,
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          isActive: false,
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
        );

        when(mockMemberRepository.getMember(memberId))
            .thenAnswer((_) async => member);

        // Act & Assert
        expect(
          () => memberService.switchDefaultMember(userId, memberId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot set inactive member as default'),
          )),
        );
      });
    });

    group('updateMemberProfile', () {
      test('should update member profile successfully', () async {
        // Arrange
        const memberId = 'member123';
        final originalMember = Member(
          id: memberId,
          userId: 'user123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
        );

        const updateData = MemberUpdateData(
          firstName: 'Jane',
          title: 'Software Engineer',
        );

        when(mockMemberRepository.getMember(memberId))
            .thenAnswer((_) async => originalMember);
        when(mockMemberRepository.updateMember(any))
            .thenAnswer((_) async {});

        // Act
        final result = await memberService.updateMemberProfile(memberId, updateData);

        // Assert
        expect(result.firstName, equals('Jane'));
        expect(result.title, equals('Software Engineer'));
        expect(result.lastName, equals('Doe')); // Unchanged
        expect(result.updatedAt.isAfter(originalMember.updatedAt), isTrue);
        
        verify(mockMemberRepository.getMember(memberId)).called(1);
        verify(mockMemberRepository.updateMember(any)).called(1);
      });

      test('should throw exception when no updates provided', () async {
        // Arrange
        const memberId = 'member123';
        const updateData = MemberUpdateData();

        // Act & Assert
        expect(
          () => memberService.updateMemberProfile(memberId, updateData),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No updates provided'),
          )),
        );
      });

      test('should throw exception when member not found', () async {
        // Arrange
        const memberId = 'member123';
        const updateData = MemberUpdateData(firstName: 'Jane');

        when(mockMemberRepository.getMember(memberId))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => memberService.updateMemberProfile(memberId, updateData),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Member not found'),
          )),
        );
      });
    });

    group('deactivateMember', () {
      test('should deactivate member successfully', () async {
        // Arrange
        const memberId = 'member123';
        final member = Member(
          id: memberId,
          userId: 'user123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          isActive: true,
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
        );

        when(mockMemberRepository.getMember(memberId))
            .thenAnswer((_) async => member);
        when(mockMemberRepository.updateMember(any))
            .thenAnswer((_) async {});

        // Act
        await memberService.deactivateMember(memberId);

        // Assert
        verify(mockMemberRepository.getMember(memberId)).called(1);
        verify(mockMemberRepository.updateMember(
          argThat(predicate<Member>((m) => !m.isActive)),
        )).called(1);
      });

      test('should throw exception when member not found', () async {
        // Arrange
        const memberId = 'member123';
        when(mockMemberRepository.getMember(memberId))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => memberService.deactivateMember(memberId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Member not found'),
          )),
        );
      });
    });

    group('reactivateMember', () {
      test('should reactivate member successfully', () async {
        // Arrange
        const memberId = 'member123';
        final member = Member(
          id: memberId,
          userId: 'user123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          isActive: false,
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
        );

        when(mockMemberRepository.getMember(memberId))
            .thenAnswer((_) async => member);
        when(mockMemberRepository.updateMember(any))
            .thenAnswer((_) async {});

        // Act
        await memberService.reactivateMember(memberId);

        // Assert
        verify(mockMemberRepository.getMember(memberId)).called(1);
        verify(mockMemberRepository.updateMember(
          argThat(predicate<Member>((m) => m.isActive)),
        )).called(1);
      });
    });

    group('streamMember', () {
      test('should return member stream', () {
        // Arrange
        const memberId = 'member123';
        final member = Member(
          id: memberId,
          userId: 'user123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
        );

        when(mockMemberRepository.streamMember(memberId))
            .thenAnswer((_) => Stream.value(member));

        // Act
        final stream = memberService.streamMember(memberId);

        // Assert
        expect(stream, emits(member));
        verify(mockMemberRepository.streamMember(memberId)).called(1);
      });
    });

    group('streamUserMembers', () {
      test('should return user members stream', () {
        // Arrange
        const userId = 'user123';
        final members = [
          Member(
            id: 'member1',
            userId: userId,
            email: 'test1@example.com',
            firstName: 'John',
            lastName: 'Doe',
            createdAt: DateTime(2023, 1, 1),
            updatedAt: DateTime(2023, 1, 1),
          ),
        ];

        when(mockMemberRepository.streamUserMembers(userId))
            .thenAnswer((_) => Stream.value(members));

        // Act
        final stream = memberService.streamUserMembers(userId);

        // Assert
        expect(stream, emits(members));
        verify(mockMemberRepository.streamUserMembers(userId)).called(1);
      });
    });
  });
}