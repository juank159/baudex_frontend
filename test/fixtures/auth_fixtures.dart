// test/fixtures/auth_fixtures.dart
import 'package:baudex_desktop/features/auth/domain/entities/user.dart';
import 'package:baudex_desktop/features/auth/domain/entities/auth_result.dart';
import 'package:baudex_desktop/features/auth/data/models/user_model.dart';
import 'package:baudex_desktop/features/auth/data/models/auth_response_model.dart';
import 'package:baudex_desktop/features/auth/data/models/login_request_model.dart';
import 'package:baudex_desktop/features/auth/data/models/register_request_model.dart';
import 'package:baudex_desktop/features/auth/data/models/change_password_request_model.dart';
import 'package:baudex_desktop/features/auth/data/models/update_profile_request_model.dart';
import 'package:baudex_desktop/features/auth/data/models/profile_response_model.dart';
import 'package:baudex_desktop/features/auth/data/models/refresh_token_response_model.dart';

/// Test fixtures for Auth module
class AuthFixtures {
  // ============================================================================
  // CONSTANTS
  // ============================================================================

  static const String testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLTAwMSIsImVtYWlsIjoidGVzdEB0ZXN0LmNvbSJ9.test';
  static const String testRefreshToken = 'refresh_token_test_xyz123abc';
  static const String testEmail = 'test@test.com';
  static const String testPassword = 'password123';
  static const String testFirstName = 'John';
  static const String testLastName = 'Doe';
  static const String testOrganizationId = 'org-001';
  static const String testOrganizationSlug = 'test-org';
  static const String testOrganizationName = 'Test Organization';

  // ============================================================================
  // ENTITY FIXTURES (Domain Layer)
  // ============================================================================

  /// Creates a single user entity with default test data
  static User createUserEntity({
    String id = 'user-001',
    String firstName = testFirstName,
    String lastName = testLastName,
    String email = testEmail,
    String? phone = '+57 300 123 4567',
    UserRole role = UserRole.user,
    UserStatus status = UserStatus.active,
    String? avatar,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String organizationId = testOrganizationId,
    String organizationSlug = testOrganizationSlug,
    String? organizationName = testOrganizationName,
  }) {
    return User(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      role: role,
      status: status,
      avatar: avatar,
      lastLoginAt: lastLoginAt,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 1),
      organizationId: organizationId,
      organizationSlug: organizationSlug,
      organizationName: organizationName,
    );
  }

  /// Creates an admin user
  static User createAdminUser({
    String id = 'user-admin',
  }) {
    return createUserEntity(
      id: id,
      firstName: 'Admin',
      lastName: 'User',
      email: 'admin@test.com',
      role: UserRole.admin,
    );
  }

  /// Creates a manager user
  static User createManagerUser({
    String id = 'user-manager',
  }) {
    return createUserEntity(
      id: id,
      firstName: 'Manager',
      lastName: 'User',
      email: 'manager@test.com',
      role: UserRole.manager,
    );
  }

  /// Creates an inactive user
  static User createInactiveUser({
    String id = 'user-inactive',
  }) {
    return createUserEntity(
      id: id,
      firstName: 'Inactive',
      lastName: 'User',
      email: 'inactive@test.com',
      status: UserStatus.inactive,
    );
  }

  /// Creates a suspended user
  static User createSuspendedUser({
    String id = 'user-suspended',
  }) {
    return createUserEntity(
      id: id,
      firstName: 'Suspended',
      lastName: 'User',
      email: 'suspended@test.com',
      status: UserStatus.suspended,
    );
  }

  /// Creates an auth result entity
  static AuthResult createAuthResult({
    User? user,
    String token = testToken,
    String? refreshToken = testRefreshToken,
  }) {
    return AuthResult(
      user: user ?? createUserEntity(),
      token: token,
      refreshToken: refreshToken,
    );
  }

  // ============================================================================
  // MODEL FIXTURES (Data Layer)
  // ============================================================================

  /// Creates a user model
  static UserModel createUserModel({
    String id = 'user-001',
    String firstName = testFirstName,
    String lastName = testLastName,
    String email = testEmail,
    String? phone = '+57 300 123 4567',
    UserRole role = UserRole.user,
    UserStatus status = UserStatus.active,
    String? avatar,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String organizationId = testOrganizationId,
    String organizationSlug = testOrganizationSlug,
    String? organizationName = testOrganizationName,
  }) {
    return UserModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      role: role,
      status: status,
      avatar: avatar,
      lastLoginAt: lastLoginAt,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 1),
      organizationId: organizationId,
      organizationSlug: organizationSlug,
      organizationName: organizationName,
    );
  }

  /// Creates an auth response model
  static AuthResponseModel createAuthResponseModel({
    UserModel? user,
    String token = testToken,
    String? refreshToken = testRefreshToken,
  }) {
    return AuthResponseModel(
      user: user ?? createUserModel(),
      token: token,
      refreshToken: refreshToken,
    );
  }

  /// Creates a profile response model
  static ProfileResponseModel createProfileResponseModel({
    UserModel? user,
  }) {
    return ProfileResponseModel(
      user: user ?? createUserModel(),
    );
  }

  /// Creates a refresh token response model
  static RefreshTokenResponseModel createRefreshTokenResponseModel({
    String token = testToken,
  }) {
    return RefreshTokenResponseModel(
      token: token,
    );
  }

  // ============================================================================
  // REQUEST MODEL FIXTURES
  // ============================================================================

  /// Creates a login request model
  static LoginRequestModel createLoginRequestModel({
    String email = testEmail,
    String password = testPassword,
  }) {
    return LoginRequestModel(
      email: email,
      password: password,
    );
  }

  /// Creates a register request model
  static RegisterRequestModel createRegisterRequestModel({
    String firstName = testFirstName,
    String lastName = testLastName,
    String email = testEmail,
    String password = testPassword,
    UserRole? role,
    String? organizationName,
  }) {
    return RegisterRequestModel.fromParams(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      role: role,
      organizationName: organizationName,
    );
  }

  /// Creates a change password request model
  static ChangePasswordRequestModel createChangePasswordRequestModel({
    String currentPassword = testPassword,
    String newPassword = 'newPassword123',
    String confirmPassword = 'newPassword123',
  }) {
    return ChangePasswordRequestModel(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  /// Creates an update profile request model
  static UpdateProfileRequestModel createUpdateProfileRequestModel({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatar,
  }) {
    return UpdateProfileRequestModel.fromParams(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      avatar: avatar,
    );
  }

  // ============================================================================
  // JSON FIXTURES
  // ============================================================================

  /// Creates JSON for a user
  static Map<String, dynamic> createUserJson({
    String id = 'user-001',
    String firstName = testFirstName,
    String lastName = testLastName,
    String email = testEmail,
    String? phone = '+57 300 123 4567',
    String role = 'user',
    String status = 'active',
    String? avatar,
    String? lastLoginAt,
    String? createdAt,
    String? updatedAt,
    String organizationId = testOrganizationId,
    String organizationSlug = testOrganizationSlug,
    String? organizationName = testOrganizationName,
  }) {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'avatar': avatar,
      'lastLoginAt': lastLoginAt,
      'createdAt': createdAt ?? DateTime(2024, 1, 1).toIso8601String(),
      'updatedAt': updatedAt ?? DateTime(2024, 1, 1).toIso8601String(),
      'organizationId': organizationId,
      'organizationSlug': organizationSlug,
      'organizationName': organizationName,
    };
  }

  /// Creates JSON for auth response
  static Map<String, dynamic> createAuthResponseJson({
    Map<String, dynamic>? user,
    String token = testToken,
    String? refreshToken = testRefreshToken,
  }) {
    return {
      'user': user ?? createUserJson(),
      'token': token,
      'refreshToken': refreshToken,
    };
  }

  /// Creates JSON for successful API response
  static Map<String, dynamic> createSuccessApiResponseJson({
    required Map<String, dynamic> data,
    String message = 'Operation successful',
  }) {
    return {
      'success': true,
      'data': data,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Creates JSON for error API response
  static Map<String, dynamic> createErrorApiResponseJson({
    String message = 'An error occurred',
    int? statusCode = 400,
    Map<String, dynamic>? errors,
  }) {
    return {
      'success': false,
      'message': message,
      'errors': errors,
      'statusCode': statusCode,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Creates JSON for login response
  static Map<String, dynamic> createLoginResponseJson({
    Map<String, dynamic>? user,
    String token = testToken,
    String? refreshToken = testRefreshToken,
  }) {
    return createSuccessApiResponseJson(
      data: createAuthResponseJson(
        user: user,
        token: token,
        refreshToken: refreshToken,
      ),
      message: 'Login successful',
    );
  }

  /// Creates JSON for register response
  static Map<String, dynamic> createRegisterResponseJson({
    Map<String, dynamic>? user,
    String token = testToken,
    String? refreshToken = testRefreshToken,
  }) {
    return createSuccessApiResponseJson(
      data: createAuthResponseJson(
        user: user,
        token: token,
        refreshToken: refreshToken,
      ),
      message: 'Registration successful',
    );
  }

  /// Creates JSON for profile response
  static Map<String, dynamic> createProfileResponseJson({
    Map<String, dynamic>? user,
  }) {
    return {
      'user': user ?? createUserJson(),
    };
  }

  /// Creates JSON for refresh token response
  static Map<String, dynamic> createRefreshTokenResponseJson({
    String token = testToken,
  }) {
    return {
      'token': token,
    };
  }

  // ============================================================================
  // VALIDATION ERROR FIXTURES
  // ============================================================================

  /// Creates validation errors for login
  static Map<String, dynamic> createLoginValidationErrors() {
    return {
      'email': ['The email field is required.', 'The email must be a valid email address.'],
      'password': ['The password field is required.', 'The password must be at least 6 characters.'],
    };
  }

  /// Creates validation errors for registration
  static Map<String, dynamic> createRegisterValidationErrors() {
    return {
      'firstName': ['The first name field is required.'],
      'lastName': ['The last name field is required.'],
      'email': ['The email field is required.', 'The email has already been taken.'],
      'password': ['The password field is required.', 'The password must be at least 8 characters.'],
    };
  }

  /// Creates validation errors for change password
  static Map<String, dynamic> createChangePasswordValidationErrors() {
    return {
      'currentPassword': ['The current password is incorrect.'],
      'newPassword': ['The new password must be at least 8 characters.'],
      'confirmPassword': ['The password confirmation does not match.'],
    };
  }
}
