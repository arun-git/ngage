// Mocks generated by Mockito 5.4.4 from annotations
// in ngage/test/services/enhanced_auth_service_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;

import 'package:firebase_auth/firebase_auth.dart' as _i6;
import 'package:mockito/mockito.dart' as _i1;
import 'package:ngage/models/member.dart' as _i3;
import 'package:ngage/models/user.dart' as _i2;
import 'package:ngage/repositories/user_repository.dart' as _i8;
import 'package:ngage/services/auth_service.dart' as _i4;
import 'package:ngage/services/member_claim_service.dart' as _i7;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeUser_0 extends _i1.SmartFake implements _i2.User {
  _FakeUser_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeMember_1 extends _i1.SmartFake implements _i3.Member {
  _FakeMember_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [AuthService].
///
/// See the documentation for Mockito's code generation for more information.
class MockAuthService extends _i1.Mock implements _i4.AuthService {
  MockAuthService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i5.Stream<_i2.User?> get authStateChanges => (super.noSuchMethod(
        Invocation.getter(#authStateChanges),
        returnValue: _i5.Stream<_i2.User?>.empty(),
      ) as _i5.Stream<_i2.User?>);

  @override
  _i5.Future<_i2.User> signInWithEmail(
    String? email,
    String? password,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #signInWithEmail,
          [
            email,
            password,
          ],
        ),
        returnValue: _i5.Future<_i2.User>.value(_FakeUser_0(
          this,
          Invocation.method(
            #signInWithEmail,
            [
              email,
              password,
            ],
          ),
        )),
      ) as _i5.Future<_i2.User>);

  @override
  _i5.Future<_i2.User> signInWithPhone(
    String? phone,
    String? verificationCode,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #signInWithPhone,
          [
            phone,
            verificationCode,
          ],
        ),
        returnValue: _i5.Future<_i2.User>.value(_FakeUser_0(
          this,
          Invocation.method(
            #signInWithPhone,
            [
              phone,
              verificationCode,
            ],
          ),
        )),
      ) as _i5.Future<_i2.User>);

  @override
  _i5.Future<_i2.User> signInWithGoogle() => (super.noSuchMethod(
        Invocation.method(
          #signInWithGoogle,
          [],
        ),
        returnValue: _i5.Future<_i2.User>.value(_FakeUser_0(
          this,
          Invocation.method(
            #signInWithGoogle,
            [],
          ),
        )),
      ) as _i5.Future<_i2.User>);

  @override
  _i5.Future<_i2.User> signInWithSlack(String? code) => (super.noSuchMethod(
        Invocation.method(
          #signInWithSlack,
          [code],
        ),
        returnValue: _i5.Future<_i2.User>.value(_FakeUser_0(
          this,
          Invocation.method(
            #signInWithSlack,
            [code],
          ),
        )),
      ) as _i5.Future<_i2.User>);

  @override
  _i5.Future<void> signOut() => (super.noSuchMethod(
        Invocation.method(
          #signOut,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> sendPasswordResetEmail(String? email) => (super.noSuchMethod(
        Invocation.method(
          #sendPasswordResetEmail,
          [email],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<_i2.User> createUserWithEmailAndPassword(
    String? email,
    String? password,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #createUserWithEmailAndPassword,
          [
            email,
            password,
          ],
        ),
        returnValue: _i5.Future<_i2.User>.value(_FakeUser_0(
          this,
          Invocation.method(
            #createUserWithEmailAndPassword,
            [
              email,
              password,
            ],
          ),
        )),
      ) as _i5.Future<_i2.User>);

  @override
  _i5.Future<void> verifyPhoneNumber(
    String? phoneNumber, {
    required dynamic Function(String)? codeSent,
    required dynamic Function(_i6.FirebaseAuthException)? verificationFailed,
    dynamic Function(_i6.PhoneAuthCredential)? verificationCompleted,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #verifyPhoneNumber,
          [phoneNumber],
          {
            #codeSent: codeSent,
            #verificationFailed: verificationFailed,
            #verificationCompleted: verificationCompleted,
          },
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
}

/// A class which mocks [MemberClaimService].
///
/// See the documentation for Mockito's code generation for more information.
class MockMemberClaimService extends _i1.Mock
    implements _i7.MemberClaimService {
  MockMemberClaimService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i5.Future<List<_i3.Member>> claimMemberProfiles(_i2.User? user) =>
      (super.noSuchMethod(
        Invocation.method(
          #claimMemberProfiles,
          [user],
        ),
        returnValue: _i5.Future<List<_i3.Member>>.value(<_i3.Member>[]),
      ) as _i5.Future<List<_i3.Member>>);

  @override
  _i5.Future<_i3.Member> createBasicMemberProfile(_i2.User? user) =>
      (super.noSuchMethod(
        Invocation.method(
          #createBasicMemberProfile,
          [user],
        ),
        returnValue: _i5.Future<_i3.Member>.value(_FakeMember_1(
          this,
          Invocation.method(
            #createBasicMemberProfile,
            [user],
          ),
        )),
      ) as _i5.Future<_i3.Member>);

  @override
  _i5.Future<void> setDefaultMember(
    String? userId,
    String? memberId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #setDefaultMember,
          [
            userId,
            memberId,
          ],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
}

/// A class which mocks [UserRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockUserRepository extends _i1.Mock implements _i8.UserRepository {
  MockUserRepository() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i5.Future<void> createUser(_i2.User? user) => (super.noSuchMethod(
        Invocation.method(
          #createUser,
          [user],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<_i2.User?> getUser(String? userId) => (super.noSuchMethod(
        Invocation.method(
          #getUser,
          [userId],
        ),
        returnValue: _i5.Future<_i2.User?>.value(),
      ) as _i5.Future<_i2.User?>);

  @override
  _i5.Future<void> updateUser(_i2.User? user) => (super.noSuchMethod(
        Invocation.method(
          #updateUser,
          [user],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> updateDefaultMember(
    String? userId,
    String? memberId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateDefaultMember,
          [
            userId,
            memberId,
          ],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> deleteUser(String? userId) => (super.noSuchMethod(
        Invocation.method(
          #deleteUser,
          [userId],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<bool> userExists(String? userId) => (super.noSuchMethod(
        Invocation.method(
          #userExists,
          [userId],
        ),
        returnValue: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);

  @override
  _i5.Stream<_i2.User?> streamUser(String? userId) => (super.noSuchMethod(
        Invocation.method(
          #streamUser,
          [userId],
        ),
        returnValue: _i5.Stream<_i2.User?>.empty(),
      ) as _i5.Stream<_i2.User?>);
}
